package hosted.controller;
import crm.CrmService;
import pro.db.VendorStats;
import tools.Timeframe;
import hosted.HostedPlugIn;
import sugoi.form.elements.StringInput;
import db.Operation;
import Common;

/**
 * Main controller of HOSTED plugin
 */
class Main extends controller.Controller
{

	public function new() 
	{
		super();
		view.category = "admin";

		//trigger a "Nav" event
		var nav = new Array<Link>();
		var e = Nav(nav,"admin");
		app.event(e);
		view.nav = e.getParameters()[0];
	}
	
	@admin @tpl("plugin/pro/hosted/group.mtt")
	public function doGroup(group:db.Group) {
		
		view.group = group;
		var mgpConf = mangopay.MangopayPlugin.getGroupConfig(group);
		if(mgpConf!=null){
			view.debugLegalUserModule = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(haxe.Json.stringify({moduleName:"mangopay-legal-user-module",props:{"mangopayUserId":mgpConf.legalUser.mangopayUserId}})));
		}
		view.mangopay = mgpConf;

		if( app.params.get("roleIds")=="1" ){
			for( md in db.MultiDistrib.manager.search($distribStartDate > Date.now() && $group==group,true) ){
				var rids = [];
				for( d in md.getDistributions() ){
					for( role in service.VolunteerService.getRolesFromContract(d.catalog) ){
						rids.push(role.id);
					}
				}
				md.lock();
				md.volunteerRolesIds = rids.join(",");
				md.update();
			}
		}

		view.vendors = group.getActiveVendors();
		view.getVendorStats = function(v:db.Vendor){
			return VendorStats.getOrCreate(v);
		}
		
		checkToken();
	}

	/*@admin
	public function doDebugOps(group:db.Group) {

		//essaye de trouver les ops de commande en double (faille dans findVOrderOperation )
		var basketIds = [];
		for( m in group.getMembers()){
			for (op in db.Operation.getOperations(m, group) ){

				if(op.type == VOrder){
					trace(op);
					var i : VOrderInfos = op.getOrderInfos();
					trace(i.basketId);

					if(Lambda.has(basketIds,i.basketId)) trace("DOUBLE BASKET ID "+i.basketId);

					basketIds.push(i.basketId);
				}

			}
		} 

	}*/	

	@admin
	function doResetBalances(g:db.Group){
		for ( m in g.getMembers()){

			var ua = db.UserGroup.get(m, g);
			var balance = ua.balance;
			if(balance<0 || balance>0){
				Sys.print('update ${m.getName()} : balance : $balance, fix : ${0-balance}<br/>');
				var op = service.PaymentService.makePaymentOperation(m,g,payment.Cash.TYPE,0-balance,"Correction de solde");
				//fix op
				op.pending = false;
				op.amount = 0-balance;
				op.update();
				Sys.print(op+"<br>");
				service.PaymentService.updateUserBalance(m,g);
			}
		}
		// throw Ok("/p/hosted/group/"+g.id,"Soldes corrigés");
	}

	public function doSyncToHubspot(group:db.Group) {

		for( vendor in group.getActiveVendors()){
			CrmService.syncToHubspot(vendor);
		}
		
		throw Ok("/p/hosted/group/"+group.id,"Synchronisation hubspot faite");
	}

	function doDeleteDemoContracts(a:db.Group){
		var contracts = a.deleteDemoContracts();
		throw Ok("/p/hosted/group/"+a.id,"Contrats suivants effacés : "+contracts.map(function(c) return c.name).join(", "));
	}
	
	function doDisableNotifs(g:db.Group){
		for ( m in g.getMembers()){
			m.lock();
			m.flags.unset(db.User.UserFlags.HasEmailNotif24h);
			m.flags.unset(db.User.UserFlags.HasEmailNotif4h);
			m.update();
		}
		throw Ok("/p/hosted/group/"+g.id, "Notifications désactivées pour tous les membres de ce groupe");
	}
	
	public function doCacheDebug(){
		Sys.println("<h2>pending carts</h2>");
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'lwec-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		Sys.println("<h2>finalize card</h2>");
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'debug-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'finalizeCard-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		
		
	}
	
	/**
	 * view a transaction detail in a pop-in window 
	 * @param	t
	 */
	@tpl("transaction/view.mtt")
	public function doOperation(op:db.Operation){
		view.op = op ;
		
		
		/* SERVICE BROKEN
		var lw = pro.payment.LWCPayment.getConnector(op.group);
		
		if (op.data.remoteOpId != null) {
			//update status if needed
			var td = lw.getMoneyInTransDetails(op.data.remoteOpId);
			//if (td.HPAY[0].STATUS == "3" && op.pending){
			//	op.lock();
			//	op.pending = false;
			//	op.update();
			//}
			
			view.infos = td;	
		}
		*/
		
	}
	
	@admin public function doAddMe(g:db.Group){
		
		var ua = app.user.makeMemberOf(g);
		throw Ok("/user/choose?group="+g.id, "Vous faites maintenant partie de " + ua.group.name);
		
	}
	
	@admin public function doDeleteGroup(a:db.Group) {
	
		if (checkToken()) {
			a.lock();
			a.delete();
			throw Ok("/p/hosted/","Groupe effacé");
		}
	}
	
	
	/**
	 * CRM page
	 */
	@admin @tpl("plugin/pro/hosted/default.mtt")
	public function doDefault() {
		
		var groups = db.Group.manager.unsafeObjects("select g.name, g.groupType, gs.* from `Group` g,GroupStats gs where g.id=gs.groupId ", false);		
		view.groups = groups;
		var hosted = hosted.db.GroupStats.manager.search($active == true);
		var acp = 0;

		//compteurs
		view.active = hosted.length;
		var members = 0;
		for ( h in hosted) {
			if( h.active ) {
				members += h.membersNum;
				if(h.cproContractNum>0) acp++;
			}
		}
		view.members = members;
		view.activeCpro = acp;
		
	}
	
	
	
	@admin
	function doGeocode(group:db.Group){
		
		/*var coords = hosted.HostedPlugIn.geocodeGroup(group);		
		throw Ok("/p/hosted/group/"+group.id,"Geocoding OK "+coords);*/
	}
	
	@admin
	function doRefresh(group:db.Group){
		
		var h = hosted.db.GroupStats.getOrCreate(group.id, true);
		var o = h.updateVisible();
		
		var str = "ACTIF : " + o.active+", VISIBLE : " + o.visible+" ( CagetteNetwork : " + o.cagetteNetwork + ", distributions : " + o.distributions + ", geoloc : " + o.geoloc + ", MembersNum : " + o.members+" )";
		
		throw Ok("/p/hosted/group/"+group.id,"Visible sur la carte : "+str);
	}
	
	function doUser(d:haxe.web.Dispatch) {
		d.dispatch(new hosted.controller.User());
	}

	/**
	 * infos sur le membre d'un groupe
	 */
	@admin @tpl("plugin/pro/hosted/usergroup.mtt")
	public function doUserGroup(u:db.User, g:db.Group){
		var ua = db.UserGroup.get(u, g, false);
		
		view.member = ua.user;
		view.ua = ua;
		view.operations = db.Operation.getLastOperations(u, g);

		var timeframe = new Timeframe( DateTools.delta(Date.now() ,-1000.0*60*60*24*30.5*3) , DateTools.delta(Date.now() , 1000.0*60*60*24*30.5*3) );
		var mds = db.MultiDistrib.getFromTimeRange(g,timeframe.from,timeframe.to);
		view.mds = mds;
		view.timeframe = timeframe;
		

	}

	
	@tpl("form.mtt")
	function doRegister() {
		
		if (App.current.user != null) throw Redirect('/');
		
		view.title = "Inscription";
		view.text = "Merci de bien vouloir remplir le formulaire ci-dessous afin de créer votre compte Cagette.net";
		
		
		var f = new sugoi.form.Form("c");
		f.addElement(new StringInput("userFirstName", "Prénom","",true));
		f.addElement(new StringInput("userLastName", "Nom de famille","",true));
		f.addElement(new StringInput("userEmail", "Email", "", true));
		var p = new StringInput("userPass", "Mot de passe", "", true);
		p.password = true;
		f.addElement(p);
		f.addElement(new StringInput("userPhone", "Téléphone (optionnel)", "", false));
		f.submitButtonLabel = "Inscription";
		
		if (f.checkToken()) {
			
			var user = new db.User();
			user.email = f.getValueOf("userEmail");
			user.firstName = f.getValueOf("userFirstName");
			user.lastName = f.getValueOf("userLastName");
			user.setPass( f.getValueOf("userPass") );
			user.phone = f.getValueOf("userPhone");
			
			if ( db.User.getSameEmail(user.email).length > 0 ) {
				throw Ok("/user/login","Vous êtes déjà enregistré dans Cagette.net, Connectez-vous à partir de cette page");
			}
			
			user.insert();
			
			/*var amap = new db.Group();
			amap.name = f.getValueOf("amapName");
			amap.txtHome = "Bienvenue sur la cagette de "+amap.name+" !\n Vous pouvez consulter votre planning de livraison ou faire une nouvelle commande.";
			amap.contact = user;

			amap.flags.set(db.Group.AmapFlags.HasMembership);
			amap.flags.set(db.Group.AmapFlags.IsAmap);
			amap.insert();
			
			var ua = new db.UserGroup();
			ua.user = user;
			ua.amap = amap;
			ua.rights = [db.UserGroup.Right.AmapAdmin,db.UserGroup.Right.Membership,db.UserGroup.Right.Messages,db.UserGroup.Right.ContractAdmin(null)];
			ua.insert();
			
			//example datas
			var place = new db.Place();
			place.name = "Place du marché";
			place.amap = amap;
			place.insert();
			
			//contrat AMAP
			var vendor = new db.Vendor();
			vendor.amap = amap;
			vendor.name = "Jean Martin EURL";
			vendor.zipCode = "33210";
			vendor.city = "Langon";
			vendor.insert();			
			
			var contract = new db.Catalog();
			contract.name = "Contrat AMAP Maraîcher Exemple";
			contract.description = "Ce contrat est un exemple de contrat maraîcher avec engagement à l'année comme on le trouve dans les AMAP.";
			contract.amap  = amap;
			contract.type = 0;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.insert();
			
			var p = new db.Product();
			p.name = "Gros panier de légumes";
			p.price = 15;
			p.contract = contract;
			p.insert();
			
			var p = new db.Product();
			p.name = "Petit panier de légumes";
			p.price = 10;
			p.contract = contract;
			p.insert();
		
			var uc = new db.UserOrder();
			uc.user = user;
			uc.product = p;
			uc.paid = true;
			uc.quantity = 1;
			uc.insert();
			
			var d = new db.Distribution();
			d.contract = contract;
			d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
			d.place = place;
			d.insert();
			
			
			//contrat variable
			var vendor = new db.Vendor();
			vendor.amap = amap;
			vendor.name = "Ferme de la Galinette";
			vendor.zipCode = "33430";
			vendor.city = "Bazas";
			vendor.insert();			
			
			var contract = new db.Catalog();
			contract.name = "Contrat Poulet Exemple";
			contract.description = "Exemple de contrat à commande variable. Il permet de commander quelque chose de différent à chaque livraison.";
			contract.amap  = amap;
			contract.type = 1;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.flags.set(db.Catalog.ContractFlags.UsersCanOrder);
			contract.insert();
			
			var egg = new db.Product();
			egg.name = "Douzaine d'oeufs bio";
			egg.price = 5;
			egg.type = 6;
			egg.contract = contract;
			egg.insert();
			
			var p = new db.Product();
			p.name = "Poulet bio";
			p.type = 2;
			p.price = 9.50;
			p.contract = contract;
			p.insert();
			
			var d = new db.Distribution();
			d.contract = contract;
			d.orderStartDate = Date.now();
			d.orderEndDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 19);
			d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 21);
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
			d.place = place;
			d.insert();
			
			var uc = new db.UserOrder();
			uc.user = user;
			uc.product = egg;
			uc.paid = true;
			uc.quantity = 2;
			uc.distribution = d;
			uc.insert();
			
			var uc = new db.UserOrder();
			uc.user = user;
			uc.product = p;
			uc.paid = true;
			uc.quantity = 1;
			uc.distribution = d;
			uc.insert();
			*/
			App.current.user = null;
			App.current.session.setUser(user);
			/*App.current.session.data.amapId  = amap.id;*/
			
			//welcome mail
			/*try {
				var m = new ufront.mail.Email();
				m.to(new ufront.mail.EmailAddress( user.email , user.firstName+" " + user.lastName));
				m.from(new ufront.mail.EmailAddress(App.config.get("webmaster_email"),"Cagette.net"));
				m.setSubject("Bienvenue sur Cagette.net !");
				
				var html = app.processTemplate("plugin/hosted/mail/welcome.mtt", { email:user.email, pass: f.getValueOf("userPass")  } );
				m.setHtml(html);
				App.getMailer().send(m);
				
			}catch(e:Dynamic){
				app.logError(e);
			}
			
			app.session.data.newGroup = true;*/
			throw Redirect("/");
		}
		
		view.form= f;
		
	}
	
	/**
	 * Stats sur les producteurs 
	 */
	@admin
	public function doVendors(){
		Sys.print("<pre>");
		Sys.println("id\tname\tcount\tstatus\tactive");


		for( v in sys.db.Manager.cnx.request("SELECT MAX(v.id) as id, count(v.id) as cnt,v.name
			FROM Vendor v
			group by name
			order by cnt desc"))	{

				var from = DateTools.delta(Date.now(), 1000.0*60*60*24*-30.5);
				var to = DateTools.delta(Date.now(), 1000.0*60*60*24*30.5*6);

				//cpro, invité ou gratuit ?
				var status = null;			
				var vendor = db.Vendor.manager.get(v.id);
				var cids = Lambda.map(vendor.getActiveContracts(),function(x) return x.id);
				var active = db.Distribution.manager.count(($catalogId in cids) && $date >= from && $date <= to) > 0;
				var contracts = db.Catalog.manager.search($vendor==vendor,false);
				for( c in contracts){
					var rc = connector.db.RemoteCatalog.getFromContract(c);
					if(rc!=null){
						status = "cpro";
						active = false;
						var company = rc.getCatalog().company;
						for( cata in company.getCatalogs()){
							if(active) break;
							for( rc in connector.db.RemoteCatalog.getFromCatalog(cata)){
								var c = rc.getContract();
								active = db.Distribution.manager.count($catalogId==c.id && $date >= from && $date <= to) > 0;
								//Sys.println("------ catalogue "+cata.name+": "+c.name+" de "+c.amap.name+" = "+active);
								if(active) break;
							}
						}
						break;
					} else if(vendor.email==c.contact.email){
						status = "gratuit";
						break;
					} else if(c.group.groupType==db.Group.GroupType.FarmShop || c.group.groupType==db.Group.GroupType.ProducerDrive){
						status = "gratuit";
						break;
					}
				}

				if(status==null) status = "invité";

				Sys.println(""+v.id+"\t"+v.name+"\t"+v.cnt+"\t"+status+"\t"+(active?"1":"0"));
		}
		Sys.print("</pre>");

	}

	@admin
	public function doAmap(){

		for( g in db.Group.manager.all(false)){

			if( !g.flags.has(ShopMode) && g.flags.has(HasPayments) ){

				var h = hosted.db.GroupStats.getOrCreate(g.id,true);
				h.updateVisible();
				if(h.active){
					Sys.print(g.id+" "+g.name+" <br>");
				}
			}
		}
	}

	@admin
	public function doMigrate(){
		
		//fix corto spremuta
		/*var d = db.Distribution.manager.get(108192);
		for ( order in db.UserOrder.manager.search($distribution == d, true) ){
			var p = order.product;
			var p2 = db.Product.manager.select($catalogId == 5839 && $ref == p.ref);
			Sys.print(p.name+" ==> " + p2.name+"<br/>");
			order.product = p2;
			order.update();
		}
		*/
		
		/*Sys.println("C'est parti....");
		for ( conf in who.db.WConfig.manager.all()){
			if (conf.contract2 == null) continue;
			
			if ( conf.contract1.amap.id != conf.contract2.amap.id){
				Sys.println("pwoblem ! "+conf.contract1.amap.name+"<br/>");
			}
		}
		
		
		//CLEAN TERRA LIBRA PRODUCTS
		/*var comp = pro.db.Company.manager.get(6,false);
		
		for ( prod in comp.getProducts()){
			
			
			//delete inactive products
			if (!prod.active) {
				Sys.println("Delete "+prod.name+"<br/>");
				prod.lock();
				prod.delete();				
			}			
		}
		
		for ( cata in comp.getCatalogs()){
			for ( rc in connector.db.RemoteCatalog.getFromCatalog(cata)) {
				var c = rc.getRelatedContract();
				Sys.println("<b>CONTRACT "+c.name+"</b><br/>");
				for ( p in c.getProducts(false)){
					if (!p.active){
						Sys.println("Delete "+p.name+"<br/>");
						p.lock();
						p.delete();
						
					}
				}
			}
		}*/
		
		
		/*for ( a in db.Group.manager.all(true)){
			
			var h = hosted.db.GroupStats.getOrCreate(a.id, true);
			h.updateVisible();
			h.update();
			
			//hasPayments == ancien isAmap
			if ( a.flags.has(db.Group.AmapFlags.HasPayments)){
				//mets en amap
				a.groupType = db.Group.GroupType.Amap;
				//unset le flag qui a changé de rôle
				a.flags.unset(db.Group.AmapFlags.HasPayments);
			}
			
			if ( a.name.indexOf("AMAP") > -1 ){
				a.groupType = db.Group.GroupType.Amap;
			}
			
			if ( a.name.indexOf("Drive") > -1 ){
				a.groupType = db.Group.GroupType.ProducerDrive;
			}
			
			//si ancien flag paiement, on met le nouveau
			if (a.flags.has(db.Group.AmapFlags.HasPaymentsOld)){
				
				a.flags.unset(db.Group.AmapFlags.HasPaymentsOld);
				a.flags.set(db.Group.AmapFlags.HasPayments);
			}
			
			a.update();
			Sys.println('${a.name} : ${a.groupType}<br>');
			
		}*/
	}

	
	

	@admin
	function doCourse(d:haxe.web.Dispatch){
		d.dispatch(new hosted.controller.Course());
	}

	@admin
	function doSeo(d:haxe.web.Dispatch){
		d.dispatch(new hosted.controller.Seo());
	}


	
}