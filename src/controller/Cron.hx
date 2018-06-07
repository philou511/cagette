package controller;
import sugoi.db.Cache;
import sugoi.Web;
import sugoi.mail.Mail;
import Common;
using Lambda;
using tools.DateTool;

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

		sendEmailsfromBuffer();

	}
	
	public function doHour() {
		
		// this function can be locally tested by
		// cd /data/cagette/www/ && neko index.n cron/hour > cron.log
		
		app.event(HourlyCron);
		
		distribNotif(4,db.User.UserFlags.HasEmailNotif4h); //4h before
		distribNotif(24,db.User.UserFlags.HasEmailNotif24h); //24h before
		distribNotif(0, db.User.UserFlags.HasEmailNotifOuverture); //on command open
		
		distribValidationNotif();
		
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
 		var from = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * (hour-1));
 		var to = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * hour);
		
		//if (App.config.DEBUG) from = DateTools.delta(from, 1000.0 * 60 * 60 * 24 * -30);
		
		// dans le cas HasEmailNotifOuverture la date à prendre est le orderStartDate
		// et non pas date qui est la date de la distribution
		var distribs;
		if ( db.User.UserFlags.HasEmailNotifOuverture == flag )
			distribs = db.Distribution.manager.search( $orderStartDate >= from && $orderStartDate <= to , false);
		else
			distribs = db.Distribution.manager.search( $date >= from && $date <= to , false);
		
		//Sys.print("distribNotif "+hour+" from "+from+" to "+to+"<br/>\n");
		
		//on s'arrete immédiatement si aucune distibution trouvée
 		if (distribs.length == 0) return;
		
		//cherche plus tard si on a pas une "grappe" de distrib
		/*while (true) {
			var extraDistribs ;
			if ( db.User.UserFlags.HasEmailNotifOuverture != flag )
				extraDistribs = db.Distribution.manager.search( $date >= to && $date <DateTools.delta(to,1000.0*60*60) , false);	
			else	
				extraDistribs = db.Distribution.manager.search( $orderStartDate >= to && $orderStartDate <DateTools.delta(to,1000.0*60*60) , false);
			for ( e in extraDistribs) distribs.add(e);
			if (extraDistribs.length > 0) {
				//on fait un tour de plus avec une heure plus tard
				to = DateTools.delta(h, 1000.0 * 60 * 60);
			}else {
				//plus de distribs
				break;
			}
		}*/
		
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
		var distribsByContractId = new Map<Int,db.Distribution>();
		for (d in distribs) {			
			if (d == null || d.contract==null) continue;
			distribsByContractId.set(d.contract.id, d);
		}

		//Boucle sur les distributions pour gerer le cas de plusieurs distributions le même jour sur le même contrat
 		var orders = [];
 		for (d in distribs) {
			if (d == null || d.contract==null) continue;
 			//get orders for both type of contracts
			for ( x in d.contract.getOrders(d)) orders.push(x);
		}
		
		/*
		 * Group orders by users-group to receive separate emails by groups for the same user.
		 * Map key is $userId-$groupId
		*/
		var users = new Map <String,{
			user:db.User,
			distrib:db.Distribution,
			products:Array<db.UserContract>,
			vendors:Array<db.Vendor>		
		}>();
		
		for (o in orders) {
			
			var x = users.get(o.user.id+"-"+o.product.contract.amap.id);
			if (x == null) x = {user:o.user,distrib:null,products:[],vendors:[]};
			x.distrib = distribsByContractId.get(o.product.contract.id);
			x.products.push(o);			
			users.set(o.user.id+"-"+o.product.contract.amap.id, x);
			//trace (o.userId+"-"+o.product.contract.amap.id, x);Sys.print("<br/>\n");
			 
			// Prévenir également le deuxième user en cas des commandes alternées
 			if (o.user2 != null) {
 				var x = users.get(o.user2.id+"-"+o.product.contract.amap.id);
 				if (x == null) x = {user:o.user2,distrib:null,products:[],vendors:[]};
 				x.distrib = distribsByContractId.get(o.product.contract.id);
 				x.products.push(o);
 				users.set(o.user2.id+"-"+o.product.contract.amap.id, x);
 				//trace (o.user2.id+"-"+o.product.contract.amap.id, x);Sys.print("<br/>\n");
 			}
		}

		//remove zero qt orders
		for( k in users.keys()){
			var x = users.get(k);
			var total = 0.0;
			for( o in x.products) total += o.quantity;
			if(total==0.0) users.remove(k);
		}
		
		// Dans le cas de l'ouverture de commande, ce sont tous les users qu'il faut intégrer
		if ( db.User.UserFlags.HasEmailNotifOuverture == flag )
		{
 			for (d in distribs) {
				var memberList = d.contract.amap.getMembers();
				for (u in memberList) {
					var x = users.get(u.id+"-"+d.contract.amap.id);
					if (x == null) x = {user:u,distrib:null,products:[],vendors:[]};
					x.distrib = distribsByContractId.get(d.contract.id);
					x.vendors.push(d.contract.vendor);
					users.set(u.id+"-"+d.contract.amap.id, x);
					//print(u.id+"-"+d.contract.amap.id, x);
				}
			}
		}

		for ( u in users) {
			
			if (u.user.flags.has(flag) ) {
				
				if (u.user.email != null) {
					var group = u.distrib.contract.amap;
					this.t = sugoi.i18n.Locale.init(u.user.lang); //switch to the user language

					var text;
					if ( db.User.UserFlags.HasEmailNotifOuverture == flag ) //ouverture de commande
					{
						text = t._("Opening of orders for the delivery of <b>::date::</b>", {date:view.hDate(u.distrib.date)});
						text += "<br/>";
						text += t._("The following suppliers are involved :");
						text += "<br/><ul>";
						for ( v in u.vendors) {
							text += "<li>" + v + "</li>";
						}
						text += "</ul>";
						//var url = "http://" + App.config.HOST + "/group/"+ u.distrib.contract.amap.id;
						//text += t._("The web address of your group is: <a href=\" + ::groupurl:: + \"> ::groupurl:: </a><br>", {groupurl:url});
					}
					else //rappel de la distribution
					{
						text = t._("Do not forget the delivery: <b>::delivery::</b><br/>", {delivery:view.hDate(u.distrib.date)});
						text += t._("Your products to collect:<br/><ul>");
						for ( p in u.products) {
							text += "<li>"+p.quantity+" x "+p.product.getName();
							// Gerer le cas des contrats en alternance
							if (p.user2 != null) {
								text += " " + t._("alternated with") + " ";
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
						text += t._("<b>Warning: you are in charge of the delivery ! Do not forget to print the attendance sheet.</b>");
					}

					var m = new Mail();
					m.setSender(App.config.get("default_email"), "Cagette.net");
					if(group.contact!=null) m.setReplyTo(group.contact.email, group.name);
					try{
						m.addRecipient(u.user.email, u.user.getName());
						if (u.user.email2 != null) m.addRecipient(u.user.email2);
					}catch (e:Dynamic){						
						app.logError(e); //email could be invalid
					}
					m.setSubject( group.name+" : "+t._("Distribution on ::date::",{date:app.view.hDate(u.distrib.date)})  );
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:text,group:group } ) );
					
					try {
						App.sendMail(m , u.distrib.contract.amap);	
					}catch (e:Dynamic){
						app.logError(e);
					}
					
				}
			}
		}
	}
	
	
	/**
	 * Check if there is a multi-distrib to validate.
	 * 
	 * Autovalidate it after 10 days
	 */
	function distribValidationNotif(){
		
		var now = Date.now();

		var from = now.setHourMinute( now.getHours(), 0 );
		var to = now.setHourMinute( now.getHours()+1 , 0);
		
		var explain = t._("<p>This step is important in order to:</p>");
		explain += t._("<ul><li>Update orders if delivered quantities are different from ordered quantities</li>");
		explain += t._("<li>Confirm the reception of payments (checks, cash, transfers) in order to mark orders as 'paid'</li></ul>");
		
		/*
		 * warn administrator if a distribution just ended
		 */ 
		var ds = db.Distribution.manager.search( !$validated && ($end >= from) && ($end < to) , false);
		
		for ( d in Lambda.array(ds)){
			if ( d.contract.type != db.Contract.TYPE_VARORDER ){
				ds.remove(d);
			}else if ( !d.contract.amap.hasPayments() ){
				ds.remove(d);
			}
		}
		
		var ds = tools.ObjectListTool.deduplicateDistribsByKey(ds);
		
		for ( d in ds ){
			var subj = "["+d.contract.amap.name+"] " + t._("Validation of the ::date:: distribution",{date:App.current.view.hDate(d.date)});
			
			var url = "http://" + App.config.HOST + "/distribution/validate/"+d.date.toString().substr(0,10)+"/"+d.place.id;
			
			var html = t._("<p>Your distribution just finished, don't forget to <b>validate</b> it</p>");
			html += explain;
			html += t._("<p><a href='::distriburl::'>Click here to validate the distribution</a> (You must be connected to your group Cagette)", {distriburl:url});
			
			App.quickMail(d.contract.amap.contact.email, subj, html);
		}
		
		/*
		 * warn administrator if a distribution ended 3 days ago
		 */		
		
		var from = now.setHourMinute( now.getHours() , 0 ).deltaDays(-3);
		var to = now.setHourMinute( now.getHours()+1 , 0).deltaDays(-3);
		
		//warn administrator if a distribution just ended
		var ds = db.Distribution.manager.search( !$validated && ($end >= from) && ($end < to) , false);
		
		for ( d in Lambda.array(ds)){
			if ( d.contract.type != db.Contract.TYPE_VARORDER ){
				ds.remove(d);
			}else if ( !d.contract.amap.hasPayments() ){
				ds.remove(d);
			}
		}
		
		var ds = tools.ObjectListTool.deduplicateDistribsByKey(ds);
		
		for ( d in ds ){
			var subj = d.contract.amap.name + t._(": Validation of the delivery of the ") + App.current.view.hDate(d.date);
			
			var url = "http://" + App.config.HOST + "/distribution/validate/"+d.date.toString().substr(0,10)+"/"+d.place.id;
			
			var html = t._("<p>Reminder: you have a delivery to validate.</p>");
			html += explain;
			html += t._("<p><a href='::distriburl::'>Click here to validate the delivery</a> (You must be connected to your group Cagette)", {distriburl:url});
			
			App.quickMail(d.contract.amap.contact.email, subj, html);
		}
		
		
		/*
		 * Autovalidate unvalidated distributions after 10 days
		 */ 
		var from = now.setHourMinute( now.getHours() , 0 ).deltaDays( 0 - db.Distribution.DISTRIBUTION_VALIDATION_LIMIT );
		var to = now.setHourMinute( now.getHours() + 1 , 0).deltaDays( 0 - db.Distribution.DISTRIBUTION_VALIDATION_LIMIT );
		print('AUTOVALIDATION');
		print('Find distributions from $from to $to');
		var ds = db.Distribution.manager.search( !$validated && ($end >= from) && ($end < to) , true);
		for ( d in Lambda.array(ds)){
			if ( d.contract.type != db.Contract.TYPE_VARORDER ){
				ds.remove(d);
			}else if ( !d.contract.amap.hasPayments() ){
				ds.remove(d);
			}
		}
		for ( d in ds){
			print(d.toString());
			for ( u in d.getUsers()){
				
				var b = db.Basket.get(u, d.place, d.date);
				if (b == null) continue;
				
				//mark orders as paid
				for ( o in b.getOrders() ){				
					o.lock();
					o.paid = true;
					o.update();				
				}
				//validate order operation and payment
				var op = b.getOrderOperation(true);
				if (op != null){
					op.lock();
					op.pending = false;
					op.update();
					
					for ( op in b.getPayments()){
						if ( op.pending){
							op.lock();
							op.pending = false;
							op.update();
						}
					}	
				}
			}
			
			//finally validate distrib
			d.validated = true;
			d.update();
			
		}
		//email
		var ds = tools.ObjectListTool.deduplicateDistribsByKey(ds);
		for ( d in ds ){
			var subj = d.contract.amap.name + t._(": Validation of the distribution of the ") + App.current.view.hDate(d.date);
			var html = t._("<p>As you did not validate it manually after 10 days, <br/>the delivery of the ::deliveryDate:: has been validated automatically</p>", {deliveryDate:App.current.view.hDate(d.date)});
			App.quickMail(d.contract.amap.contact.email, subj, html);
		}
		
	}
	
	
	function sendEmailsfromBuffer(){
		print("<h3>Send Emails from Buffer</h3>");

		for( e in sugoi.db.BufferedMail.manager.search($sdate==null,{limit:100,orderBy:-cdate},true)  ){
			print('#${e.id} - ${e.title}');
			e.finallySend();
			Sys.sleep(0.25);
		}

	}
	
	
	function print(text){
		Sys.println( text + "<br/>" );
	}
}
