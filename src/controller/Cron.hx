package controller;
import Common;
import db.Catalog;
import db.MultiDistrib;
import haxe.CallStack;
import haxe.display.Display.CompletionModeKind;
import hosted.db.GroupStats;
import service.GraphService;
import sugoi.Web;
import sugoi.db.Cache;
import sugoi.mail.Mail;
import sugoi.tools.TransactionWrappedTask;
import sys.db.Mysql;

using Lambda;
using tools.DateTool;

class Cron extends Controller
{
	var now : Date;

	public function new(){
		super();

		//For testing purposes you can add an arg to build a "fake now"
		this.now = App.current.params.exists("now") ? Date.fromString(App.current.params.get("now")) : Date.now();
		Sys.println("now is "+this.now.toString());
	}

	public function doDefault(){}
	
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
	
	/**
		Cron executed every minute
	**/
	public function doMinute() {
		if (!canRun()) return;
		
		app.event(MinutelyCron(this.now));
	}
	
	/**
	 *  Hourly Cron
	 *  this can be locally tested with `neko index.n cron/hour > cron.log`				
	 */
	public function doHour() {

		//instructions for dutyperiod volunteers
		var task = new TransactionWrappedTask("Volunteers instruction mail");
		task.setTask(function() {
			//Let's get all the multidistribs that start in the right time range
			var fromNow = now.setHourMinute( now.getHours(), 0 );
			var toNow = now.setHourMinute( now.getHours() + 1, 0);
			var multidistribs: Array<db.MultiDistrib> = db.MultiDistrib.manager.unsafeObjects(
				'SELECT distrib.* 
				FROM MultiDistrib distrib INNER JOIN `Group` g
				ON distrib.groupId = g.id
				WHERE distrib.distribStartDate >= DATE_ADD(\'${fromNow}\', INTERVAL g.volunteersMailDaysBeforeDutyPeriod DAY)
				AND distrib.distribStartDate < DATE_ADD(\'${toNow}\', INTERVAL g.volunteersMailDaysBeforeDutyPeriod DAY);', false).array();
			
			for (multidistrib  in multidistribs) {

				var volunteers: Array<db.Volunteer> = multidistrib.getVolunteers();
				if ( volunteers.length != 0 ) {
					task.log(multidistrib.getGroup().name+" : "+multidistrib.getDate());
					var mail = new Mail();
					mail.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
					var volunteersList = "<ul>";
					for ( volunteer in  volunteers ) {
						
						mail.addRecipient( volunteer.user.email, volunteer.user.getName() );
						if ( volunteer.user.email2 != null ) {
							mail.addRecipient( volunteer.user.email2 );
						}
						volunteersList += "<li>"+volunteer.volunteerRole.name + " : " + volunteer.user.getCoupleName() + "</li>";
					}
					volunteersList += "</ul>";
					
					mail.setSubject( t._("Instructions for the volunteers of the ::date:: distribution",{date : view.hDate(multidistrib.distribStartDate)}) );
					
					//Let's replace all the tokens
					var ddate = t._("::date:: from ::startHour:: to ::endHour::",{date:view.dDate(multidistrib.distribStartDate),startHour:view.hHour(multidistrib.distribStartDate),endHour:view.hHour(multidistrib.distribEndDate)});
					var emailBody = StringTools.replace( multidistrib.group.volunteersMailContent, "[DATE_DISTRIBUTION]", ddate );
					emailBody = StringTools.replace( emailBody, "[LIEU_DISTRIBUTION]", multidistrib.place.name ); 
					emailBody = StringTools.replace( emailBody, "[LISTE_BENEVOLES]", volunteersList ); 
					mail.setHtmlBody( app.processTemplate("mail/message.mtt", { text: emailBody, group: multidistrib.group  } ) );
					App.sendMail(mail, multidistrib.group);
				}
			}			
		});
		task.execute(!App.config.DEBUG);


		var task = new TransactionWrappedTask("Volunteers alerts");
		task.setTask(function() {

			//Let's get all the multidistribs that start in the right time range
			var fromNow = now.setHourMinute( now.getHours(), 0 );
			var toNow = now.setHourMinute( now.getHours() + 1, 0);
			var multidistribs: Array<db.MultiDistrib> = Lambda.array( db.MultiDistrib.manager.unsafeObjects(
				'SELECT distrib.* 
				FROM MultiDistrib distrib INNER JOIN `Group` g
				ON distrib.groupId = g.id
				WHERE distrib.distribStartDate >= DATE_ADD(\'${fromNow}\', INTERVAL g.vacantVolunteerRolesMailDaysBeforeDutyPeriod DAY)
				AND distrib.distribStartDate < DATE_ADD(\'${toNow}\', INTERVAL g.vacantVolunteerRolesMailDaysBeforeDutyPeriod DAY);', false));

			var vacantVolunteerRolesMultidistribs = Lambda.filter( multidistribs, function(multidistrib) return multidistrib.hasVacantVolunteerRoles() );
			
			for (multidistrib  in vacantVolunteerRolesMultidistribs) {
				task.log(multidistrib.getGroup().name+" : "+multidistrib.getDate());
				var mail = new Mail();
				mail.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
				for ( member in multidistrib.group.getMembers() ) {
					mail.addRecipient( member.email, member.getName() );
					if ( member.email2 != null ) {
						mail.addRecipient( member.email2 );
					}
				}

				//vacant roles
				var vacantVolunteerRolesList = "<ul>"+Lambda.map( multidistrib.getVacantVolunteerRoles(),function (r) return "<li>"+r.name+"</li>").join("\n")+"</ul>";
				mail.setSubject("Besoin de volontaires pour la distribution du " + view.hDate(multidistrib.distribStartDate));
				
				//Let's replace all the tokens
				var ddate = view.dDate(multidistrib.distribStartDate) + " de " + view.hHour(multidistrib.distribStartDate) + " à " + view.hHour(multidistrib.distribEndDate);
				var emailBody = StringTools.replace( multidistrib.group.alertMailContent, "[DATE_DISTRIBUTION]", ddate );
				emailBody = StringTools.replace( emailBody, "[LIEU_DISTRIBUTION]", multidistrib.place.name ); 
				emailBody = StringTools.replace( emailBody, "[ROLES_MANQUANTS]", vacantVolunteerRolesList ); 										
				mail.setHtmlBody( app.processTemplate("mail/message.mtt", { text: emailBody, group: multidistrib.getGroup()  } ) );

				App.sendMail(mail, multidistrib.getGroup());
			}
		});
		task.execute(!App.config.DEBUG);

		//Distribution time notifications
		var task = new TransactionWrappedTask("Distrib notifications");
		task.setTask(function(){
			distribNotif(task,this.now,4,db.User.UserFlags.HasEmailNotif4h); //4h before
			distribNotif(task,this.now,24,db.User.UserFlags.HasEmailNotif24h); //24h before
		});
		task.execute(!App.config.DEBUG);

		//opening orders notification
		var task = new TransactionWrappedTask("Opening orders notifications");
		task.setTask(function(){
			openingOrdersNotif(task);
		});
		task.execute(!App.config.DEBUG);

		//Distrib Validation notifications				
		var task = new TransactionWrappedTask("Distrib Validation notifications");
		task.setTask(distribValidationNotif.bind(task));
		task.execute(!App.config.DEBUG);

		var task = new TransactionWrappedTask( 'Default automated orders for CSA variable contracts' );
		task.setTask( function() {

			var range = tools.DateTool.getLastHourRange( now );

			var distributionsToCheckForMissingOrders = db.Distribution.manager.unsafeObjects(
			'SELECT Distribution.* 
			FROM Distribution INNER JOIN Catalog
			ON Distribution.catalogId = Catalog.id
			WHERE Catalog.distribMinOrdersTotal > 0
			AND Distribution.orderEndDate >= \'${range.from}\'
			AND Distribution.orderEndDate < \'${range.to}\';', false );
				
			for ( distrib in distributionsToCheckForMissingOrders ) {
				var distribSubscriptions = db.Subscription.manager.search( $catalog == distrib.catalog && $startDate <= distrib.date && $endDate >= distrib.date, false );

				for ( subscription in distribSubscriptions ) {

					if ( subscription.getAbsentDistribIds().find( id -> id == distrib.id ) == null ) {
					
						var distribSubscriptionOrders = db.UserOrder.manager.search( $subscription == subscription && $distribution == distrib );
						if ( distribSubscriptionOrders.length == 0 ) {

							// if ( service.SubscriptionService.areAutomatedOrdersValid( subscription, distrib ) ) {

								var defaultOrders = subscription.getDefaultOrders();

								var automatedOrders = [];
								for ( order in defaultOrders ) {

									var product = db.Product.manager.get( order.productId, false );
									if ( product != null && order.quantity != null && order.quantity != 0 ) {
										automatedOrders.push( service.OrderService.make( subscription.user, order.quantity, product, distrib.id, null, subscription ) );	
									}
								}

								if( automatedOrders.length != 0 ) {

									var message = 'Bonjour ${subscription.user.firstName},<br /><br />
									A défaut de commande de votre part, votre commande par défaut a été appliquée automatiquement 
									à la distribution du ${view.hDate( distrib.date )} du contrat "${subscription.catalog.name}".
									<br /><br />
									Votre commande par défaut : <br /><br />${subscription.getDefaultOrdersToString()}
									<br /><br />
									La commande à chaque distribution est obligatoire dans le contrat "${subscription.catalog.name}". 
									Vous pouvez modifier votre commande par défaut en accédant à votre souscription à ce contrat depuis la page "commandes" sur Cagette.net';

									//fail silently
									try{} catch(e:Dynamic){
										App.quickMail( subscription.user.email, distrib.catalog.name + ' : Commande par défaut', message, distrib.catalog.group );
									}
								}
							
								//Create order operation only
								service.SubscriptionService.createOrUpdateTotalOperation( subscription );
						}

					}
				}
			}
		});
		task.execute(!App.config.DEBUG);

		//clean files that are not linked to anything
		var task = new TransactionWrappedTask( "Clean unused db.File entities");
		task.setTask(function() {
			var maxId = sys.db.Manager.cnx.request("select max(id) from File").getIntResult(0);
			var rd = Std.random(Math.round(maxId/1000));

			var files =  sugoi.db.File.manager.search($id > (rd*1000) && $id < ((rd+1)*1000) ,true);
			task.log('get ${files.length} files with id from ${rd*1000} to ${(rd+1)*1000}');

			for( f in files){
				//product file
				if(db.Product.manager.select($image==f)!=null) continue;

				//entity file 
				if(sugoi.db.EntityFile.manager.select($file==f)!=null) continue;	
				
				//TODO : remove entityFiles related to unexisting entities
				
				//vendor logo
				if(db.Group.manager.select($image==f)!=null) continue;

				//group logo
				if(db.Vendor.manager.select($image==f)!=null) continue;

				#if plugins
				if(pro.db.PProduct.manager.select($image==f)!=null) continue;
				if(pro.db.POffer.manager.select($image==f)!=null) continue;
				#end
				
				task.log("delete "+f.toString());
				f.delete();
			}
		});
		task.execute(false);

		/**
			orders notif in cpro, should be sent AFTER default automated orders
		**/
		app.event(HourlyCron(this.now));
		

	}
	
	/**
		Daily cron job
	**/
	public function doDaily() {
		if (!canRun()) return;

		app.event(DailyCron(this.now));		
		
		var task = new TransactionWrappedTask( "Send errors to admin by email");
		task.setTask(function() {
			var n = Date.now();
			var yest24h = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
			var yest0h = DateTools.delta(yest24h, -1000 * 60 * 60 * 24);
			
			var errors = sugoi.db.Error.manager.search( $date < yest24h && $date > yest0h  );		
			if (errors.length > 0) {
				var report = new StringBuf();
				report.add("<h1>" + App.current.getTheme().name + " : ERRORS</h1>");
				for (e in errors) {
					report.add("<div><pre>"+e.error + " at URL " + e.url + " ( user : " + (e.user!=null?e.user.toString():"none") + ", IP : " + e.ip + ")</pre></div><hr/>");
				}
				
				var m = new Mail();
				m.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
				m.addRecipient(App.config.get("webmaster_email"));
				m.setSubject(App.current.getTheme().name+" Errors");
				m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:report.toString() } ) );
				App.sendMail(m);
			}
		});
		task.execute(!App.config.DEBUG);
		
		var task = new TransactionWrappedTask( "Old datas cleaning");
		task.setTask(function() {
			task.log("Delete old sessions");
			sugoi.db.Session.clean();
			task.log("Delete old demo catalogs");
			var sevenDaysAgo = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 7);
			var heightDaysAgo = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 8);
			for( g in db.Group.manager.search($cdate<sevenDaysAgo && $cdate>heightDaysAgo) ){
				g.deleteDemoContracts();
			}	
		});
		task.execute(!App.config.DEBUG);
		
		
		//Delete old documents of catalogs that have ended 18 months ago
		var task = new TransactionWrappedTask( "Delete old documents");
		task.setTask(function() {
			var eighteenMonthsAgo = DateTools.delta( Date.now(), -1000.0 * 60 * 60 * 24 * 30 * 18 );
			var oneDayBefore = DateTools.delta( eighteenMonthsAgo, -1000 * 60 * 60 * 24 );
			task.log('Catalogs that have ended between $oneDayBefore and $eighteenMonthsAgo');
			//Catalogs that have ended during that time range
			var endedCatalogs = db.Catalog.manager.search( $endDate >= oneDayBefore && $endDate < eighteenMonthsAgo, false );
			var documents : Array<sugoi.db.EntityFile>  = null;
			for ( catalog in endedCatalogs ) {

				documents = sugoi.db.EntityFile.getByEntity( 'catalog', catalog.id, 'document' );
				for ( document in documents ) {

					document.file.delete();
					document.delete();
				}
			}
		});
		task.execute(!App.config.DEBUG);

		//stats
		var task = new TransactionWrappedTask( "Stats");
		task.setTask(function() {
			var yesterday = new Date(now.getFullYear(), now.getMonth(), now.getDate()-1, 0, 0, 0);
			for( k in GraphService.getAllGraphKeys()){
				GraphService.getDay(k,yesterday);
			}
		});
		task.execute();


		var task = new TransactionWrappedTask( "Refresh group Stats");
		task.setTask(function() {			
			//split groups in 7 segments so the update is made every week
			var maxId = sys.db.Manager.cnx.request("select max(id) from `Group`").getIntResult(0);
			var dayOfWeek = Date.now().getDay();
			var segmentLength = Math.ceil(maxId/7);
			task.log('maxId : $maxId, dayOfWeek : $dayOfWeek, segmentLength : $segmentLength');

			var groups = db.Group.manager.search($id >=(dayOfWeek*segmentLength) && $id<((dayOfWeek+1)*segmentLength) );

			for(g in groups){
				var gs = GroupStats.getOrCreate(g.id);
				gs.updateStats();
				task.log("update "+g.id+" - "+g.name);
			}
		});
		task.execute(!App.config.DEBUG);

		
	
	}
	
	/**
	 * Send email notifications to users before a distribution
	 * @param	hour
	 * @param	flag
	 */
	function distribNotif(task:TransactionWrappedTask,now:Date,hour:Int, flag:db.User.UserFlags) {
		
		//trouve les distrib qui commencent dans le nombre d'heures demandé
 		//on recherche celles qui commencent jusqu'à une heure avant pour ne pas en rater 
 		var from = DateTools.delta(now, 1000.0 * 60 * 60 * (hour-1));
 		var to = DateTools.delta(now, 1000.0 * 60 * 60 * hour);
		
		// dans le cas HasEmailNotifOuverture la date à prendre est le orderStartDate
		// et non pas date qui est la date de la distribution
		var distribs;
		task.title('$flag : Look for distribs happening between $from to $to');
		distribs = db.Distribution.manager.search( $date >= from && $date < to , false);
		
		
		//on s'arrete immédiatement si aucune distibution trouvée
 		if (distribs.length == 0) return;
		
		//on vérifie dans le cache du jour que ces distrib n'ont pas deja été traitées lors d'un cron précédent
		var dist :Array<Int> = [];
		var cacheId = Date.now().toString().substr(0, 10)+Std.string(flag);
		if(!App.config.DEBUG) {
			dist = sugoi.db.Cache.get(cacheId);
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
		}
		
		
		//toutes les distribs trouvées ont deja été traitées
		if (distribs.length == 0) return;
		
		//stocke cache
		for (d in distribs) {
			dist.push(d.id);
			task.log("Distrib : "+d.date+" de "+d.catalog.name+", groupe : "+d.catalog.group.name);
		}
		if(!App.config.DEBUG) Cache.set(cacheId, dist, 24 * 60 * 60);

 		var orders = [];
 		for (d in distribs) {
			if (d == null || d.catalog==null) continue;
 			//get orders for both type of catalogs
			for ( x in d.catalog.getOrders(d)) orders.push(x);
		}
		
		/*
		 * Group orders by users-group to receive separate emails by groups for the same user.
		 * Map key is $userId-$groupId
		*/
		var users = new Map <String,{
			user:db.User,
			distrib:db.MultiDistrib,
			orders:Array<db.UserOrder>,
			vendors:Array<db.Vendor>		
		}>();
		
		for (o in orders) {
			
			var x = users.get(o.user.id+"-"+o.product.catalog.group.id);
			if (x == null) x = {user:o.user,distrib:null,orders:[],vendors:[]};
			x.distrib = o.distribution.multiDistrib;
			x.orders.push(o);			
			users.set(o.user.id+"-"+o.product.catalog.group.id, x);
			 
			// Prévenir également le deuxième user en cas des commandes alternées
 			if (o.user2 != null) {
 				var x = users.get(o.user2.id+"-"+o.product.catalog.group.id);
 				if (x == null) x = {user:o.user2,distrib:null,orders:[],vendors:[]};
 				x.distrib = o.distribution.multiDistrib;
 				x.orders.push(o);
				users.set(o.user2.id+"-"+o.product.catalog.group.id, x);
 			}
		}

		//remove zero qt orders
		for( k in users.keys()){
			var x = users.get(k);
			var total = 0.0;
			for( o in x.orders) total += o.quantity;
			if(total==0.0) users.remove(k);
		}

		for ( u in users) {			
			if (u.user.flags.has(flag) ) {				
				if (u.user.email != null) {
					var group = u.distrib.group;
					task.log("=== "+u.user.getName()+" de "+group.name);
					this.t = sugoi.i18n.Locale.init(u.user.lang); //switch to the user language

					var text;
					
					//Distribution notif to the users
					var d = u.distrib;
					text = t._("Do not forget the delivery on <b>::day::</b> from ::from:: to ::to::<br/>", {day:view.dDate(d.distribStartDate),from:view.hHour(d.distribStartDate),to:view.hHour(d.distribEndDate)});
					text += t._("Your products to collect :") + "<br/><ul>";
					for ( p in u.orders) {
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
				
					try{
						var m = new Mail();
						m.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
						if(group.contact!=null) m.setReplyTo(group.contact.email, group.name);
						m.addRecipient(u.user.email, u.user.getName());
						if (u.user.email2 != null) m.addRecipient(u.user.email2);
						m.setSubject( t._("Distribution on ::date::",{date:app.view.hDate(u.distrib.distribStartDate)})  );
						
						//time slots
						var status = null;
						var timeSlotService = function(d:db.MultiDistrib){
							return new service.TimeSlotsService(d);
						};

						m.setHtmlBody( app.processTemplate("mail/orderNotif.mtt", { text:text,group:group,multiDistrib:u.distrib,user:u.user,hHour:Formatting.hHour,timeSlotService:timeSlotService } ) );
						App.sendMail(m, group);	

						if(App.config.DEBUG){
							//task.log("distrib is "+u.distrib);
							task.title(u.user.getName());
							task.log(m.getHtmlBody());
						}

					}catch (e:Dynamic){						
						app.logError(e); //email could be invalid
						task.warning(e);
						task.warning(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					}
					
				}
			}
		}
	}


	function openingOrdersNotif(task:TransactionWrappedTask) {
		
		var from = now.setHourMinute( now.getHours(), 0 );
		var to = now.setHourMinute( now.getHours()+1 , 0);		
		var distribs = db.Distribution.manager.search( $orderStartDate >= from && $orderStartDate < to , false);		
		task.title('Look for distribs with orderStartDate between $from to $to (${distribs.length})');
 		if (distribs.length == 0) return;		
		
		//exclude CSA catalogs
		distribs = distribs.filter( (d) -> return d.catalog.type!=db.Catalog.TYPE_CONSTORDERS );
		distribs.map(  (d) -> task.log("Distrib : "+d.date+" de "+d.catalog.name+", groupe : "+d.catalog.group.name) );
				
		/*
		 * Group distribs by group.
		 * Map key is $groupId
		*/
		var data = new Map <Int,{distributions:Array<db.Distribution>,vendors:Array<db.Vendor>}>();
		
		for (d in distribs) {			
			var x = data.get(d.catalog.group.id);
			if (x == null) x = {distributions:[],vendors:[]};
			x.distributions.push(d);
			x.vendors.push(d.catalog.vendor);			
			data.set(d.catalog.group.id, x);						
		}
		for( d in data){
			//deduplicate vendors
			d.vendors = tools.ObjectListTool.deduplicate(d.vendors);
		}

		for(g in data){
			if(g.distributions.length==0) continue;
			var group = g.distributions[0].catalog.group;
			var md = g.distributions[0].multiDistrib;
			for ( user in group.getMembers()) {			
				if (user.flags.has(db.User.UserFlags.HasEmailNotifOuverture) ) {				

					if (user.email != null) {
						task.log("=== "+user.getName()+" de "+group.name);
						this.t = sugoi.i18n.Locale.init(user.lang); //switch to the user language
						
						//order opening notif
						var text = t._("Opening of orders for the delivery of <b>::date::</b>", {date:view.hDate(md.distribStartDate)});
						text += "<br/>";
						text += t._("The following suppliers are involved :");
						text += "<br/><ul>";
						for ( v in g.vendors) {
							text += "<li>" + v.name + "</li>";
						}
						text += "</ul>";						
											
						try{
							var m = new Mail();
							m.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
							if(group.contact!=null) m.setReplyTo(group.contact.email, group.name);
							m.addRecipient(user.email, user.getName());
							if (user.email2 != null) m.addRecipient(user.email2);
							m.setSubject( t._("Distribution on ::date::",{date:app.view.hDate(md.distribStartDate)})  );
							
							m.setHtmlBody( app.processTemplate("mail/orderNotif.mtt", { 
								text:text,
								group:group,
								multiDistrib:md,
								user:user,
								hHour:Formatting.hHour 
							} ) );
							App.sendMail(m , group);	
	
							if(App.config.DEBUG){
								task.title(user.getName());
								task.log(m.getHtmlBody());
							}
	
						}catch (e:Dynamic){						
							app.logError(e); //email could be invalid
							task.warning(e);
							task.warning(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
						}
						
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
	function distribValidationNotif(task){
		
		var now = Date.now();

		var from = now.setHourMinute( now.getHours(), 0 );
		var to = now.setHourMinute( now.getHours()+1 , 0);
		
		var explain = t._("<p>This step is important in order to:</p>");
		explain += t._("<ul><li>Update orders if delivered quantities are different from ordered quantities</li>");
		explain += t._("<li>Confirm the reception of payments (checks, cash, transfers) in order to mark orders as 'paid'</li></ul>");
		
		/*
		 * warn administrator if a distribution just ended
		 */ 
		var distribs = db.MultiDistrib.manager.search( !$validated && ($distribStartDate >= from) && ($distribStartDate < to) , false);
		
		for ( d in Lambda.array(distribs)){
			if ( !d.getGroup().hasPayments() ){
				distribs.remove(d);
			}
		}
		var view = App.current.view;
		for ( d in distribs ){
			var subj = "Validation de la distribution du " + view.hDate(d.distribStartDate);
			var url = "http://" + App.config.HOST + "/distribution/validate/"+d.id;
			var html = t._("<p>Your distribution just finished, don't forget to <b>validate</b> it</p>");
			html += explain;
			html += "<p><a href='" + url + "'>Cliquez ici pour valider la distribution</a> (vous devez être connecté·e à votre groupe " + App.current.getTheme().name + ")</p>";
			App.quickMail(d.getGroup().contact.email, subj, html, d.getGroup());
		}
		
		/*
		 * warn administrator if a distribution ended 3 days ago
		 */		
		
		var from = now.setHourMinute( now.getHours() , 0 ).deltaDays(-3);
		var to = now.setHourMinute( now.getHours()+1 , 0).deltaDays(-3);
		
		//warn administrator if a distribution just ended
		var distribs = db.MultiDistrib.manager.search( !$validated && ($distribStartDate >= from) && ($distribStartDate < to) , false);
		
		for ( d in Lambda.array(distribs)){
			if ( !d.getGroup().hasPayments() ){
				distribs.remove(d);
			}
		}
		
		for ( d in distribs ){
		
			var subj = "Validation de la distribution du " + view.hDate(d.distribStartDate);
			var url = "http://" + App.config.HOST + "/distribution/validate/"+d.id;		
			var html = t._("<p>Reminder: you have a delivery to validate.</p>");
			html += explain;
			html += "<p><a href='" + url + "'>Cliquez ici pour valider la distribution</a> (vous devez être connecté·e à votre groupe " + App.current.getTheme().name + ")</p>";
			
			if(d.getGroup().contact!=null){
				App.quickMail(d.getGroup().contact.email, subj, html, d.getGroup());
			}
			
		}
		
		
		/*
		 * Autovalidate unvalidated distributions after 10 days
		 */ 
		/*var from = now.setHourMinute( now.getHours() , 0 ).deltaDays( 0 - db.Distribution.DISTRIBUTION_VALIDATION_LIMIT );
		var to = now.setHourMinute( now.getHours() + 1 , 0).deltaDays( 0 - db.Distribution.DISTRIBUTION_VALIDATION_LIMIT );
		task.log('<h3>Autovalidation of unvalidated distribs</h3>');
		task.log('Find distributions from $from to $to');
		var distribs = db.MultiDistrib.manager.search( !$validated && ($distribStartDate >= from) && ($distribStartDate < to) , false);
		for ( d in Lambda.array(distribs)){
			if ( !d.getGroup().hasPayments() ){
				distribs.remove(d);
			}
		}

		for (d in distribs){
			task.log(d.toString());
			try	{
				service.PaymentService.validateDistribution(d);
			}catch(e:tink.core.Error){
				task.log(e.message);
				continue;
			}
		}
		//email
		for ( d in distribs ){
			if(d.getGroup().contact==null) continue;
			var subj = t._("[::group::] Validation of the ::date:: distribution",{group : d.getGroup().name , date : view.hDate(d.distribStartDate)});
			var html = t._("<p>As you did not validate it manually after 10 days, <br/>the delivery of the ::deliveryDate:: has been validated automatically</p>", {deliveryDate:App.current.view.hDate(d.distribStartDate)});
			App.quickMail(d.getGroup().contact.email, subj, html);
		}*/
		
	}
	
	/**
	 *  Email product report when orders close				
	 **/  
	/*function sendOrdersByProductWhenOrdersClose(){
	
		var range = tools.DateTool.getLastHourRange();
		// Sys.println("Time is "+Date.now()+"<br/>");
		// Sys.println('Find all distributions that have closed in the last hour from ${range.from} to ${range.to} \n<br/>');
				
		for ( d in db.Distribution.manager.search($orderEndDate >= range.from && $orderEndDate < range.to, false)){
			service.OrderService.sendOrdersByProductReport(d);
		}
	}*/
	
	public static function print(text:Dynamic){
		var text = Std.string(text);
		Sys.println( "<pre>"+ text + "</pre>" );
	}

	public static function printTitle(title){
		Sys.println("<h2>"+title+"</h2>");
	}
}
