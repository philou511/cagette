package controller;
import Common;
import db.Group;
import payment.Cash;
import payment.Cash;
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

		if(group.disabled!=null){
			throw Redirect("/group/disabled/"+group.id);
		}
		
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
		var cagettePros = service.VendorService.getCagetteProFromUser(App.current.user);
		if (!(App.current.getSettings().onlyVendorsCanCreateGroup==null
			 || App.current.getSettings().onlyVendorsCanCreateGroup==false 
			 || (App.current.getSettings().onlyVendorsCanCreateGroup==true && cagettePros!=null && cagettePros.length>0))
			 ) {
			throw Redirect("/");
		}

		view.title = "Créer un nouveau groupe " + App.current.getTheme().name;

		var p = new db.Place();
		var f = form.CagetteForm.fromSpod(p);
		f.addElement(new sugoi.form.elements.StringSelect('country',t._("Country"),db.Place.getCountries(),p.country,true));			
		f.addElement(new StringInput("groupName", t._("Name of your group"), "", true),1);
		
		//group type
		if (App.current.getSettings().noCsa != true) {
			var data = [
				{
					label:"Mode marché",
					value:"2",
					desc : "Drive de producteurs sans engagement.<br/>Configuration par défaut : Groupe ouvert, n'importe qui peut s'inscrire et commander <a data-toggle='tooltip' title='En savoir plus' href='https://wiki.cagette.net/admin:admin_boutique#mode_marche' target='_blank'><i class='icon icon-info'></i></a>"
				},
				{ 
					label:"Mode AMAP",
					value:"0",
					desc : "Gérer des contrats AMAP classiques ou variables.<br/>Configuration par défaut : Groupe fermé avec liste d'attente et gestion des adhésions. <a data-toggle='tooltip' title='En savoir plus' href='https://wiki.cagette.net/admin:admin_boutique#mode_amap' target='_blank'><i class='icon icon-info'></i></a>"
				}
			];	
			var gt = new sugoi.form.elements.RadioGroup("type", t._("Group type"), data ,"2", Std.string( db.Catalog.TYPE_VARORDER ), true, true, true);
			f.addElement(gt,2);
		}

		f.getElement("name").label = "Nom du lieu";
		f.removeElementByName("lat");
		f.removeElementByName("lng");

		f.addElement(new sugoi.form.elements.Html("infos","<h4>Lieu de distribution</h4>Renseignez le nom et adresse du lieu qui acceuillera les distributions de produits.<br/>Vous pourrez changer cette adresse plus tard si nécéssaire."),3);
		
		if (f.checkToken()) {
			
			var user = app.user;
			
			var g = new db.Group();
			g.name = f.getValueOf("groupName");
			g.contact = user;
			
			var type:GroupType;
			if (App.current.getSettings().noCsa == true) {
				type = GroupType.ProducerDrive;
			}else {
				type = Type.createEnumIndex(GroupType, Std.parseInt(f.getValueOf("type")) );
			}
			
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
			g.flags.set(HasPayments);
			g.setAllowedPaymentTypes([payment.Cash.TYPE,payment.Check.TYPE]);
			g.insert();
			
			var ua = new db.UserGroup();
			ua.user = user;
			ua.group = g;
			ua.insert();
			ua.giveRight(Right.GroupAdmin);
			ua.giveRight(Right.Membership);
			ua.giveRight(Right.Messages);
			ua.giveRight(Right.ContractAdmin(null));
			
			//insert place
			f.toSpod(p); 	
			p.group = g;		
			p.insert();

			service.PlaceService.geocode(p);

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
		
		view.lat = args.lat;
		view.lng = args.lng;
		view.address = args.address;
	}

	@tpl("group/disabled.mtt")
	public function doDisabled(?group: db.Group){
		var group = group != null ? group : App.current.getCurrentGroup();
		if (group == null) throw Redirect("/");
		view.group = group;
	}
}