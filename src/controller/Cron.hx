package controller;
import sugoi.db.Cache;
import sugoi.Web;
import sugoi.mail.Mail;
import Common;
using Lambda;

class Cron extends Controller
{

	public function doDefault() 
	{
		
	}
	
	/**
	 * CLI only en prod
	 */
	function canRun() {
		if (App.current.user != null && App.current.user.isAdmin()){
			return true;
		}else if (App.config.DEBUG) {
			return true;
		}else {
			
			if (Web.isModNeko) {
				Sys.print("only CLI.");
				return false;
			}else {
				return true;
			}
		}
	}
	
	public function doMinute() {
		if (!canRun()) return;
		
		app.event(MinutelyCron);
	}
	
	public function doHour() {
		// this function could be locally tested by
		// cd /data/cagette/www/ && (rm page.html; neko index.n cron/hour > page.html)
		app.event(HourlyCron);
		
		distribNotif(4,db.User.UserFlags.HasEmailNotif4h); //4h before
		distribNotif(24,db.User.UserFlags.HasEmailNotif24h); //24h before
		distribNotif(0,db.User.UserFlags.HasEmailNotifOuverture); //on command open
	}
	
	
	public function doDaily() {
		if (!canRun()) return;
		
		app.event(DailyCron);
		
		//ERRORS MONITORING
		var n = Date.now();
		var yest24h = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
		var yest0h = DateTools.delta(yest24h, -1000 * 60 * 60 * 24);
		
		var errors = sugoi.db.Error.manager.search( $date < yest24h && $date > yest0h  );		
		if (errors.length > 0) {
			var report = new StringBuf();
			report.add("<h1>" + App.config.NAME + " : ERRORS</h1>");
			for (e in errors) {
				report.add("<div><pre>"+e.error + " at URL " + e.url + " ( user : " + (e.user!=null?e.user.toString():"none") + ", IP : " + e.ip + ")</pre></div><hr/>");
			}
			
			var m = new Mail();
			m.setSender(App.config.get("default_email"),"Cagette.net");
			m.addRecipient(App.config.get("webmaster_email"));
			m.setSubject(App.config.NAME+" Errors");
			m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:report.toString() } ) );
			App.sendMail(m);
		}
		
		
		//DEMO CONTRATS deletion after 10 days ( see controller.Group.doCreate() )
		db.Contract.manager.delete($name == "Contrat AMAP Maraîcher Exemple" && $startDate < DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 10));
		db.Contract.manager.delete($name == "Contrat Poulet Exemple" && $startDate < DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 10));

		
		//Old Messages cleaning
		db.Message.manager.delete($date < DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 365));
		
		//DB cleaning : I dont know how, but some people have empty string emails...
		for ( u in db.User.manager.search($email == "", true)){
			u.email = Std.random(9999) + "@cagette.net";
			u.update();
		}
		for ( u in db.User.manager.search($email2 == "", true)){
			u.email2 = null;
			u.update();
		}
		
		
	}
	
	/**
	 * Send email notifications to users before a distribution
	 * @param	hour
	 * @param	flag
	 */
	function distribNotif(hour:Int, flag:db.User.UserFlags) {
		
		//trouve les distrib qui commencent dans le nombre d'heures demandé
 		//on recherche celles qui commencent jusqu'à une heure avant pour ne pas en rater 
 		var d = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * (hour-1));
 		var h = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * hour);
		var distribs ;
		// dans le cas HasEmailNotifOuverture la date à prendre est le orderStartDate
		// et non pas date qui est la date de la distribution
		if ( db.User.UserFlags.HasEmailNotifOuverture == flag )
			distribs = db.Distribution.manager.search( $orderStartDate >= d && $orderStartDate <= h , false);
		else
			distribs = db.Distribution.manager.search( $date >= d && $date <= h , false);
		
		//trace("distribNotif "+hour+" from "+d+" to "+h);Sys.print("<br/>\n");
		
		//on s'arrete immédiatement si aucune distibution trouvée
 		if (distribs.length == 0) return;
		
		//cherche plus tard si on a pas une "grappe" de distrib
		while (true) {
			var extraDistribs ;
			if ( db.User.UserFlags.HasEmailNotifOuverture != flag )
				extraDistribs = db.Distribution.manager.search( $date >= h && $date <DateTools.delta(h,1000.0*60*60) , false);	
			else	
				extraDistribs = db.Distribution.manager.search( $orderStartDate >= h && $orderStartDate <DateTools.delta(h,1000.0*60*60) , false);
			for ( e in extraDistribs) distribs.add(e);
			if (extraDistribs.length > 0) {
				//on fait un tour de plus avec une heure plus tard
				h = DateTools.delta(h, 1000.0 * 60 * 60);
			}else {
				//plus de distribs
				break;
			}
		}
		
		//on vérifie dans le cache du jour que ces distrib n'ont pas deja été traitées lors d'un cron précédent
		var cacheId = Date.now().toString().substr(0, 10)+Std.string(flag);
		var dist :Array<Int> = sugoi.db.Cache.get(cacheId);
		if (dist != null) {
			for (d in Lambda.array(distribs)) {
				if (Lambda.exists(dist, function(x) return x == d.id)) {
					// Comment this line in case of local test
					distribs.remove(d);
				}
			}
		}else {
			dist = [];
		}
		
		//toutes les distribs trouvées ont deja été traitées
		if (distribs.length == 0) return;
		
		//stocke cache
		for (d in distribs) dist.push(d.id);
		Cache.set(cacheId, dist, 24 * 60 * 60);
		
		//We have now the distribs we want to notify about.
		trace(distribs);Sys.print("<br/>\n");
		var distribsByContractId = new Map<Int,db.Distribution>();
		for (d in distribs) distribsByContractId.set(d.contract.id, d);

		//Boucle sur les distributions pour gerer le cas de plusieurs distributions le même jour sur le même contrat
 		var orders = [];
 		for (d in distribs) {
 			//get orders for both type of contracts
			for ( x in d.contract.getOrders(d)) orders.push(x);
		}
		
		/*
		 * Group orders by users-amap to receive separate emails by groups for the same user.
		 * Map key is $userId-$groupId
		*/
		var users = new Map <String,{
			user:db.User,
			distrib:db.Distribution,
			products:Array<db.UserContract>			
		}>();
		
		for (o in orders) {
			
			var x = users.get(o.userId+"-"+o.product.contract.amap.id);
			if (x == null) x = {user:o.user,distrib:null,products:[]};
			x.distrib = distribsByContractId.get(o.product.contract.id);
			//x.distrib = o.distribution;
			x.products.push(o);			
			users.set(o.userId+"-"+o.product.contract.amap.id, x);
			trace (o.userId+"-"+o.product.contract.amap.id, x);Sys.print("<br/>\n");
			 
			// Prévenir également le deuxième user en cas des commandes alternées
 			if (o.user2 != null) {
 				var x = users.get(o.user2.id+"-"+o.product.contract.amap.id);
 				if (x == null) x = {user:o.user2,distrib:null,products:[]};
 				x.distrib = distribsByContractId.get(o.product.contract.id);
 				x.products.push(o);
 				users.set(o.user2.id+"-"+o.product.contract.amap.id, x);
 				trace (o.user2.id+"-"+o.product.contract.amap.id, x);Sys.print("<br/>\n");
 			}
		}
		
		// Dans le cas de l'ouverture de commande, ce sont tous les users qu'il faut intégrer
		if ( db.User.UserFlags.HasEmailNotifOuverture == flag )
		{
 			for (d in distribs) {
				var MemberList = d.contract.amap.getMembers();
				for (u in MemberList) {
					var x = users.get(u.id+"-"+d.contract.amap.id);
					if (x == null) x = {user:u,distrib:null,products:[]};
					x.distrib = distribsByContractId.get(d.contract.id);	
					users.set(u.id+"-"+d.contract.amap.id, x);
					trace (u.id+"-"+d.contract.amap.id, x);Sys.print("<br/>\n");
				}
			}
		}

		for ( u in users) {
			
			if (u.user.flags.has(flag) ) {
				
				if (u.user.email != null) {
					var group = u.distrib.contract.amap;

					var text;
					if ( db.User.UserFlags.HasEmailNotifOuverture == flag ) //ouverture de commande
					{
						text  = "Ouverture des commandes pour la distribution du : <b>" + view.hDate(u.distrib.date) + "</b><br>";
						var url = "http://" + App.config.HOST + "/group/"+ u.distrib.contract.amap.id;
						text += "L'adresse de votre cagette est : <a href=\"" + url + "\">" + url + "</a><br>";
					}
					else //rappel de la distribution
					{
						text = "N'oubliez pas la distribution : <b>" + view.hDate(u.distrib.date) + "</b><br>";
						text += "Vos produits à récupérer :<br><ul>";
						for ( p in u.products) {
							text += "<li>"+p.quantity+" x "+p.product.getName();
							// Gerer le cas des contrats en alternance
							if (p.user2 != null) {
								text += " en alternance avec ";
								if (u.user == p.user)
									text += p.user2.getCoupleName();
								else
									text += p.user.getCoupleName();
							}
							text += "</li>";
						}
						text += "</ul>";
					}
				
					if (u.distrib.isDistributor(u.user)) {
						text += "<b>ATTENTION : Vous ou votre conjoint(e) êtes distributeur ! N'oubliez pas d'imprimer la liste d'émargement.</b>";
					}

					var m = new Mail();
					m.setSender(App.config.get("default_email"), "Cagette.net");
					if(group.contact!=null){
						m.setReplyTo(group.contact.email, group.name);
					}
					m.addRecipient(u.user.email, u.user.getName());
					if(u.user.email2!=null) m.addRecipient(u.user.email2);
					m.setSubject( group.name+" : Distribution " + app.view.hDate(u.distrib.date) );
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:text,group:group } ) );
					
					//debug
					Sys.println("<hr/>---------------\n now is "+Date.now().toString()+" : " + m.getRecipients() + "<br/>" + m.getSubject() + "<br/>" + m.getHtmlBody()+ "");					
					Sys.sleep(0.25);
					
					try {
						// Comment this line in case of local test
						App.sendMail(m , u.distrib.contract.amap);	
					}catch (e:Dynamic){
						app.logError(e);
					}
					
				}
			}
		}
	}
	
}
