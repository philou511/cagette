package controller;
import Common;
import db.Group;
import service.BridgeService;
import service.DistributionService;
import service.OrderService;
import service.SubscriptionService;
import service.WaitingListService;
import sugoi.form.elements.StringInput;

/**
 * Groups
 */
class Group extends controller.Controller
{

	/**
	 * Public page of a group
	 */
	@tpl('group/view.mtt')
	function doDefault( group : db.Group ) {
		
		if ( group.regOption == db.Group.RegOption.Open ) {

			if (app.session.data == null) app.session.data = {};
			app.session.data.amapId = group.id;
			throw Redirect("/");
		}
		
		view.group = group;
		var activeCatalogs = group.getActiveContracts();
		view.contracts = activeCatalogs;
		view.pageTitle = group.name;
		group.getMainPlace(); //just to update cache

		var isMemberOfGroup = app.user == null ? false : app.user.isMemberOf(group); 
		view.isInWaitingList = app.user == null ? false : db.WaitingList.manager.select($amapId == group.id && $user == app.user);

		if ( app.user == null ) {
			service.UserService.prepareLoginBoxOptions(view,group);
		}	
		view.user = app.user;
		view.isMember = isMemberOfGroup;

		// Documents
		view.visibleGroupDocuments = group.getVisibleDocuments( isMemberOfGroup );
		var visibleCatalogsDocuments = new Map< Int, List<sugoi.db.EntityFile> >();
		for ( catalog in activeCatalogs ) {
			
			visibleCatalogsDocuments.set( catalog.id, catalog.getVisibleDocuments( app.user ) );
		}
		view.visibleCatalogsDocuments = visibleCatalogsDocuments;
	}
	
	/**
	 * Register to a waiting list.
	 * the user can be logged or not !
	 */
	@tpl('form.mtt')
	function doList(group:db.Group){
		if ( app.user==null ) {
			throw Redirect("/group/"+group.id);
		}
		
		//checks
		if (group.regOption != db.Group.RegOption.WaitingList) throw Redirect("/group/" + group.id);
		if (app.user != null) {
			try{
				WaitingListService.canRegister(app.user,group);
			}catch(e:tink.core.Error){				
				throw Error("/group/" + group.id,e.message);
			}
		}
		
		//build form
		var form = new sugoi.form.Form("reg");				
		
		form.addElement(new sugoi.form.elements.TextArea("msg", t._("Leave a message")));
		
		if (form.isValid()){
			try{
				WaitingListService.registerToWl(app.user,group,form.getValueOf("msg"));
				throw Ok("/group/" + group.id,t._("Your subscription to the waiting list has been recorded. You will receive an e-mail as soon as your request is processed.") );
			}catch(e:tink.core.Error){
				throw Error("/group/list/" + group.id,e.message);
			}
			
		}
		
		view.title = t._("Subscription to \"::groupeName::\" waiting list", {groupeName:group.name});
		view.form = form;		
	}

	/**
		Cancel suscription request
	**/
	function doListCancel(group:db.Group){
		try{
			WaitingListService.removeFromWl(app.user,group);
		}catch(e:tink.core.Error){				
			throw Error("/group/" + group.id,e.message);
		}
		throw Ok("/group/" + group.id,t._("You've been removed from the waiting list"));
	}
	
	/**
	 * create a new group
	 */
	@tpl("form.mtt")
	function doCreate() {
		
		view.title = t._("Create a new Cagette Group");

		var f = new sugoi.form.Form("c");
		f.addElement(new StringInput("name", t._("Name of your group"), "", true));
		
		//group type
		var data = [
			{
				label:"Mode marché",
				value:"2",
				desc : "Drive de producteurs sans engagement.<br/>Configuration par défaut : Groupe ouvert (n'importe qui peut s'inscrire et commander) <a data-toggle='tooltip' title='En savoir plus' href='https://wiki.cagette.net/admin:admin_boutique#mode_marche' target='_blank'><i class='icon icon-info'></i></a>"
			},
			{ 
				label:"Mode AMAP",
				value:"0",
				desc : "Gérer des contrats AMAP classiques ou variables.<br/>Configuration par défaut : Groupe fermé avec liste d'attente et gestion des adhésions. <a data-toggle='tooltip' title='En savoir plus' href='https://wiki.cagette.net/admin:admin_boutique#mode_amap' target='_blank'><i class='icon icon-info'></i></a>"
			},
		/*	{
				label:t._("Grouped orders"),
				value:"1",
				desc : "Commandes en <a href='https://wiki.cagette.net/admin:admin_boutique#mode_boutique' target='_blank'>Mode Boutique</a>, groupe fermé avec liste d'attente et gestion des adhésions."
			},*/
			
			/*{
				label:"En direct d'un producteur",
				value:"3",
				desc : "Commandes en <a href='https://wiki.cagette.net/admin:admin_boutique#mode_boutique' target='_blank'>Mode Boutique</a>, groupe ouvert : n'importe qui peut commander."
			},*/
		];	
		var gt = new sugoi.form.elements.RadioGroup("type", t._("Group type"), data ,"2", Std.string( db.Catalog.TYPE_VARORDER ), true, true, true);
		f.addElement(gt);
		
		if (f.checkToken()) {
			
			var user = app.user;
			
			var g = new db.Group();
			g.name = f.getValueOf("name");
			g.contact = user;
			
			var type:GroupType = Type.createEnumIndex(GroupType, Std.parseInt(f.getValueOf("type")) );
			
			switch(type){
			case null : 
				throw "unknown group type";

			case Amap : 
				g.flags.unset(ShopMode);
				g.flags.set(HasPayments);
				g.hasMembership=true;
				g.regOption = WaitingList;

				if(!user.isAdmin()) throw Redirect('/group/csa?name='+g.name);
				
			case GroupedOrders :
				g.flags.set(ShopMode);
				g.hasMembership=true;
				g.regOption = WaitingList;
				
			case ProducerDrive,FarmShop : 
				g.flags.set(ShopMode);								
				g.flags.set(PhoneRequired);
				g.regOption = Open;
			}
			
			g.groupType = type;
			g.insert();
			
			var ua = new db.UserGroup();
			ua.user = user;
			ua.group = g;
			ua.insert();
			ua.giveRight(Right.GroupAdmin);
			ua.giveRight(Right.Membership);
			ua.giveRight(Right.Messages);
			ua.giveRight(Right.ContractAdmin(null));
			
			//example datas
			var place = new db.Place();
			place.name = t._("Market square");
			place.zipCode  = "000";
			place.city = "St Martin de la Cagette";
			place.group = g;
			place.insert();
			
			//contrat AMAP
			var vendor = db.Vendor.manager.select($email=="jean@cagette.net",false);
			if(vendor==null){
				vendor = new db.Vendor();
				vendor.name = "Jean Martin EARL";
				vendor.zipCode = "000";
				vendor.city = "St Martin de la Cagette";
				vendor.email = "jean@cagette.net";
				vendor.insert();
			}
			
			if ( type == Amap ) {

				var contract = new db.Catalog();
				contract.name = t._("Vegetables CSA contract - Example");
				contract.description = t._("CSA contract example");
				contract.group  = g;
				contract.type = db.Catalog.TYPE_CONSTORDERS;
				contract.vendor = vendor;
				contract.startDate = Date.now();
				contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
				contract.contact = user;
				contract.distributorNum = 2;
				contract.orderStartDaysBeforeDistrib = 365;
				contract.orderEndHoursBeforeDistrib = 24;
				contract.insert();
				
				var product = new db.Product();
				product.name = t._("Big basket of vegetables");
				product.price = 15;
				product.organic = true;
				product.catalog = contract;
				product.insert();
				
				var product = new db.Product();
				product.name = t._("Small basket of vegetables");
				product.price = 10;
				product.organic = true;
				product.catalog = contract;
				product.insert();
				
				var date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
				DistributionService.create(
					contract,
					date,
					DateTools.delta(date, 1000.0 * 60 * 90),
					place.id,
					Date.now(),
					DateTools.delta( Date.now(), 1000.0 * 60 * 60 * 24 * 13)
				);	
				var ordersData = new Array< { productId : Int, quantity : Float, invertSharedOrder : Bool, userId2 : Int } >();
				ordersData.push( { productId : product.id, quantity : 1, invertSharedOrder : false, userId2 : null } );
				var ss = new SubscriptionService();
				ss.createSubscription( user, contract, ordersData, null );
			}
			
			//contrat variable
			var vendor = db.Vendor.manager.select($email=="galinette@cagette.net",false);
			if(vendor==null){
				vendor = new db.Vendor();
				vendor.name = t._("Farm Galinette");
				vendor.zipCode = "000";
				vendor.city = "St Martin de la Cagette";
				vendor.email = "galinette@cagette.net";
				vendor.insert();			
			}			
			
			var contract = new db.Catalog();
			contract.name = t._("Chicken catalog - Example");
			contract.description = t._("Chicken catalog example.");
			contract.group  = g;
			contract.type = db.Catalog.TYPE_VARORDER;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.flags.set(db.Catalog.CatalogFlags.UsersCanOrder);
			contract.insert();
			
			var egg = new db.Product();
			egg.name = t._("12 eggs");
			egg.price = 5;
			//egg.type = 6;
			egg.organic = true;
			egg.catalog = contract;
			egg.insert();
			
			var p = new db.Product();
			p.name = t._("Chicken");
			//p.type = 2;
			p.price = 9.50;
			p.organic = true;
			p.catalog = contract;
			p.insert();
			
			var date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
			var d = DistributionService.create(
				contract,
				date,
				DateTools.delta(date, 1000.0 * 60 * 90),
				place.id,
				Date.now(),
				DateTools.delta( Date.now(), 1000.0 * 60 * 60 * 24 * 13)
			);

			var ordersData = new Array< { productId : Int, quantity : Float, ?userId2 : Int, ?invertSharedOrder : Bool } >();
			ordersData.push( { productId : egg.id, quantity : 2 } );
			ordersData.push( { productId : p.id, quantity : 1 } );
			var ss = new SubscriptionService();
			var subscription = ss.createSubscription( user, contract, ordersData, null );
			
			OrderService.make(user, 2, egg, d.id, false, subscription );
			OrderService.make(user, 1, p, d.id, false, subscription );
			
			App.current.session.data.amapId  = g.id;
			app.session.data.newGroup = true;

			#if plugins
			try{
				//sync if this user is not cpro && market mode group
				if( service.VendorService.getCagetteProFromUser(app.user).length==0 && g.hasShopMode() ){
					
					BridgeService.syncUserToHubspot(app.user);
					service.BridgeService.triggerWorkflow(29805116, app.user.email);
				}
			}catch(e:Dynamic){
				//fail silently
				app.logError(Std.string(e));
			}
			#end

			throw Redirect("/");
		}
		
		view.form= f;
		
	}

	@admin
	function doTest(){
		#if plugins
		
		var user = db.User.manager.get(1,false);
		Sys.print("sync user "+user.getName());
		BridgeService.syncUserToHubspot(user);
		service.BridgeService.triggerWorkflow(29805116, user.email);
		#end
	}
	
	/**
		Displays a google map in a popup
	**/
	// @tpl('group/place.mtt')
	// public function doPlace(place:db.Place){
	// 	view.place = place;
		
	// 	//build adress for google maps
	// 	var addr = "";
	// 	if (place.address1 != null) addr += place.address1;
	// 	if (place.address2 != null) addr += ", " + place.address2;
	// 	if (place.zipCode != null) addr += " " + place.zipCode;
	// 	if (place.city != null) addr += " " + place.city;
		
	// 	view.addr = view.escapeJS(addr);
	// }

	@tpl("group/csa.mtt")
	public function doCsa(args:{name:String}){

		view.groupName = args.name;

	}


	@tpl("group/map.mtt")
	public function doMap(?args:{?lat:Float,?lng:Float,?address:String}){

		view.container = "container-fluid";
		
		//if no param is sent, focus on Paris
		if (args == null || ((args.address == null || args.address == "") && args.lat == null && args.lng == null)){
			args = {lat:48.855675, lng:2.3472365};
		}
		
		view.lat = args.lat;
		view.lng = args.lng;
		view.address = args.address;		
	}
}