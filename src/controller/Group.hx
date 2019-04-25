package controller;
import sugoi.form.elements.StringInput;
import service.OrderService;
import service.WaitingListService;
import db.Amap;
import Common;

/**
 * Groups
 */
class Group extends controller.Controller
{

	/**
	 * Public page of a group
	 */
	@tpl('group/view.mtt')
	function doDefault(group:db.Amap){
		
		if (group.regOption == db.Amap.RegOption.Open) {
			app.session.data.amapId = group.id;
			throw Redirect("/");
		}
		
		view.group = group;
		view.contracts = group.getActiveContracts();
		view.pageTitle = group.name;
		group.getMainPlace(); //just to update cache
		if (app.user != null){			
			view.isMember = Lambda.has(app.user.getGroups(), group);
		}else{
			service.UserService.prepareLoginBoxOptions(view,group);
		}
	}
	
	/**
	 * Register to a waiting list.
	 * the user can be logged or not !
	 */
	@tpl('form.mtt')
	function doList(group:db.Amap){
		
		//checks
		if (group.regOption != db.Amap.RegOption.WaitingList) throw Redirect("/group/" + group.id);
		if (app.user != null) {
			try{
				WaitingListService.canRegister(app.user,group);
			}catch(e:tink.core.Error){				
				throw Error("/group/" + group.id,e.message);
			}
		}
		
		//build form
		var form = new sugoi.form.Form("reg");				
		if (app.user == null){
			form.addElement(new StringInput("userFirstName", t._("Your firstname"),"",true));
			form.addElement(new StringInput("userLastName", t._("Your lastname") ,"",true));
			form.addElement(new StringInput("userEmail", t._("Your e-mail"), "", true));		
		}
		form.addElement(new sugoi.form.elements.TextArea("msg", t._("Leave a message")));
		
		if (form.isValid()){
			try{
				if (app.user == null){
					var f = form;
					var user = service.UserService.softRegistration(f.getValueOf("userFirstName"),f.getValueOf("userLastName"), f.getValueOf("userEmail") );
					db.User.login(user, user.email);				
				}			
				
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
	function doListCancel(group:db.Amap){
		try{
			WaitingListService.removeFromWl(app.user,group);
		}catch(e:tink.core.Error){				
			throw Error("/group/" + group.id,e.message);
		}
		throw Ok("/group/" + group.id,t._("You've been removed from the waiting list"));
	}
	
	
	/**
	 * 	Register direclty in an open group
	 * 
	 * 	the user can be logged or not !
	
	@tpl('form.mtt')
	function doRegister(group:db.Amap){
		
		if (group.regOption != db.Amap.RegOption.Open) throw Redirect("/group/" + group.id);
		if (app.user != null){			
			if ( db.UserAmap.manager.select($amapId == group.id && $user == app.user) != null) throw Error("/group/" + group.id, t._("You are already member of this group."));			
		}
		
		var form = new sugoi.form.Form("reg");	
		form.submitButtonLabel = t._("Join the group");
		form.addElement(new sugoi.form.elements.Html("html",t._("Confirm your subscription to \"::groupName::\"", {groupName:group.name})));
		if (app.user == null){
			form.addElement(new StringInput("userFirstName", t._("Your firstname"),"",true));
			form.addElement(new StringInput("userLastName", t._("Your lastname"), "", true));
			var em = new StringInput("userEmail", t._("Your e-mail"), "", true);
			em.addValidator(new EmailValidator());
			form.addElement(em);		
			form.addElement(new StringInput("address", t._("Address"), "", true));					
			form.addElement(new StringInput("zipCode", t._("Zip code"), "", true));		
			form.addElement(new StringInput("city", t._("City"), "", true));		
			form.addElement(new StringInput("phone", t._("Phone"), "", true));		
		}
		
		if (form.isValid()){
			
			if (app.user == null){
				var f = form;
				var user = new db.User();
				user.email = f.getValueOf("userEmail");
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				user.address1 = f.getValueOf("address");
				user.zipCode = f.getValueOf("zipCode");
				user.city = f.getValueOf("city");
				user.phone = f.getValueOf("phone");
				
				if ( db.User.getSameEmail(user.email).length > 0 ) {
					throw Ok("/user/login",t._("You already subscribed to Cagette.net, please log in on this page"));
				}
				
				user.insert();				
				app.session.setUser(user);
				
			}			
			
			var w = new db.UserAmap();
			w.user = app.user;
			w.amap = group;
			w.insert();
			
			throw Ok("/user/choose", t._("Your subscription has been taken into account"));
		}
		
		view.title = t._("Subscription to \"::groupName::\"", {groupName:group.name});
		view.form = form;
		
	}*/
	
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
			{label:t._("CSA"),value:"0"},
			{label:t._("Grouped orders"),value:"1"},
			{label:t._("Farmers collective"),value:"2"},
			{label:t._("Farm shop"),value:"3"},
		];	
		var gt = new sugoi.form.elements.RadioGroup("type", t._("Group type"), data ,"1","1",true,true,true);
		f.addElement(gt);
		
		if (f.checkToken()) {
			
			var user = app.user;
			
			var g = new db.Amap();
			g.name = f.getValueOf("name");
			g.contact = user;
			
			var type:GroupType = Type.createEnumIndex(GroupType, Std.parseInt(f.getValueOf("type")) );
			
			switch(type){
			case null : 
				throw "unknown group type";
			case Amap : 
				g.flags.set(HasMembership);
				g.regOption = WaitingList;
				
			case GroupedOrders :
				g.flags.set(ShopMode);
				g.flags.set(HasMembership);
				g.flags.set(ShopV2);
				g.flags.set(ShopCategoriesFromTaxonomy);
				g.regOption = WaitingList;
				
			case ProducerDrive,FarmShop : 
				g.flags.set(ShopMode);								
				g.flags.set(PhoneRequired);
				//g.flags.set(ShopV2);
				//g.flags.set(ShopCategoriesFromTaxonomy);
				g.regOption = Open;
			}
			
			g.groupType = type;
			g.insert();
			
			var ua = new db.UserAmap();
			ua.user = user;
			ua.amap = g;
			ua.rights = [Right.GroupAdmin,Right.Membership,Right.Messages,Right.ContractAdmin(null)];
			ua.insert();
			
			//example datas
			var place = new db.Place();
			place.name = t._("Market square");
			place.zipCode  = "000";
			place.city = "St Martin de la Cagette";
			place.amap = g;
			place.insert();
			
			//contrat AMAP
			var vendor = db.Vendor.manager.select($email=="jean@cagette.net",false);
			if(vendor==null){
				vendor = new db.Vendor();
				vendor.name = "Jean Martin EARL";
				vendor.zipCode = "000";
				vendor.city = "Langon";
				vendor.email = "jean@cagette.net";
				vendor.insert();
			}
			
			if (type == Amap){
				var contract = new db.Contract();
				contract.name = t._("CSA contract Vegetables - Example");
				contract.description = t._("This contract is an example where the customer has to commit to buy the whole year as with AMAPs");
				contract.amap  = g;
				contract.type = 0;
				contract.vendor = vendor;
				contract.startDate = Date.now();
				contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
				contract.contact = user;
				contract.distributorNum = 2;
				contract.insert();
				
				var p = new db.Product();
				p.name = t._("Big basket of vegetables");
				p.price = 15;
				p.organic = true;
				p.contract = contract;
				p.insert();
				
				var p = new db.Product();
				p.name = t._("Small basket of vegetables");
				p.price = 10;
				p.organic = true;
				p.contract = contract;
				p.insert();
			
				OrderService.make(user, 1, p, null, true);
				
				var d = new db.Distribution();
				d.contract = contract;
				d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
				d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
				d.place = place;
				d.insert();
				
			}
			
			//contrat variable
			var vendor = db.Vendor.manager.select($email=="galinette@cagette.net",false);
			if(vendor==null){
				vendor = new db.Vendor();
				vendor.name = t._("Farm Galinette");
				vendor.zipCode = "000";
				vendor.city = t._("Bazas");
				vendor.email = "galinette@cagette.net";
				vendor.insert();			
			}			
			
			var contract = new db.Contract();
			contract.name = t._("Chicken Contract - Example");
			contract.description = t._("Example of contract with variable orders. It is allowed to order something else at every delivery.");
			contract.amap  = g;
			contract.type = 1;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.flags.set(db.Contract.ContractFlags.UsersCanOrder);
			contract.insert();
			
			var egg = new db.Product();
			egg.name = t._("12 eggs");
			egg.price = 5;
			//egg.type = 6;
			egg.organic = true;
			egg.contract = contract;
			egg.insert();
			
			var p = new db.Product();
			p.name = t._("Chicken");
			//p.type = 2;
			p.price = 9.50;
			p.organic = true;
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
			
			OrderService.make(user, 2, egg, d.id);
			OrderService.make(user, 1, p, d.id);
			
			App.current.session.data.amapId  = g.id;
			app.session.data.newGroup = true;
			throw Redirect("/");
		}
		
		view.form= f;
		
	}
	
	/**
		Displays a google map in a popup
	**/
	@tpl('group/place.mtt')
	public function doPlace(place:db.Place){
		view.place = place;
		
		//build adress for google maps
		var addr = "";
		if (place.address1 != null) addr += place.address1;
		if (place.address2 != null) addr += ", " + place.address2;
		if (place.zipCode != null) addr += " " + place.zipCode;
		if (place.city != null) addr += " " + place.city;
		
		view.addr = view.escapeJS(addr);
	}
	
	/**
	 * Groups map
	 */
	@tpl("group/map.mtt")
	public function doMap(?args:{?lat:Float,?lng:Float,?address:String}){

		view.container = "container-fluid";
		
		//if no param is sent, focus on Paris
		if (args == null || (args.address == null && args.lat == null && args.lng == null)){
			args = {lat:48.855675, lng:2.3472365};
		}
		
		view.lat = args.lat;
		view.lng = args.lng;
		view.address = args.address;		
	}
	
	
}