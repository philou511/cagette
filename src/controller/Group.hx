package controller;
import sugoi.form.elements.StringInput;
import sugoi.form.validators.EmailValidator;
import db.Amap.GroupType;

/**
 * Public pages controller
 */
class Group extends controller.Controller
{

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
			
			view.isMember = Lambda.has(app.user.getAmaps(), group);
		}
	}
	
	/**
	 * register to a waiting list.
	 * 
	 * the user can be logged or not !
	 */
	@tpl('form.mtt')
	function doList(group:db.Amap){
		
		if (group.regOption != db.Amap.RegOption.WaitingList) throw Redirect("/group/" + group.id);
		if (app.user != null){
			if ( db.WaitingList.manager.select($amapId == group.id && $user == app.user) != null) throw Error("/group/" + group.id, "Vous êtes déjà sur la liste d'attente de ce groupe");
			if ( db.UserAmap.manager.select($amapId == group.id && $user == app.user) != null) throw Error("/group/" + group.id, "Vous faites déjà partie de ce groupe.");			
		}
		
		var form = new sugoi.form.Form("reg");				
		if (app.user == null){
			form.addElement(new StringInput("userFirstName", "Votre prénom","",true));
			form.addElement(new StringInput("userLastName", "Votre nom de famille","",true));
			form.addElement(new StringInput("userEmail", "Votre email", "", true));		
		}
		form.addElement(new sugoi.form.elements.TextArea("msg", "Laissez un message"));
		
		if (form.isValid()){
			
			if (app.user == null){
				var f = form;
				var user = new db.User();
				user.email = f.getValueOf("userEmail");
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				
				if ( db.User.getSameEmail(user.email).length > 0 ) {
					throw Ok("/user/login","Vous êtes déjà enregistré dans Cagette.net, Connectez-vous à partir de cette page");
				}
				
				user.insert();
				app.session.setUser(user);
				
			}			
			
			var w = new db.WaitingList();
			w.user = app.user;
			w.group = group;
			w.message = form.getValueOf("msg");
			w.insert();
			
			throw Ok("/group/" + group.id,"Votre inscription en liste d'attente a été prise en compte. Vous serez prévenu par email lorsque votre demande sera traitée.");
		}
		
		view.title = "Inscription en liste d'attente à \"" + group.name+"\"";
		view.form = form;
		
	}
	
	
	/**
	 * register direclty in an open group
	 * 
	 * the user can be logged or not !
	 */
	@tpl('form.mtt')
	function doRegister(group:db.Amap){
		
		if (group.regOption != db.Amap.RegOption.Open) throw Redirect("/group/" + group.id);
		if (app.user != null){			
			if ( db.UserAmap.manager.select($amapId == group.id && $user == app.user) != null) throw Error("/group/" + group.id, "Vous faites déjà partie de ce groupe.");			
		}
		
		var form = new sugoi.form.Form("reg");	
		form.submitButtonLabel = "Rejoindre le groupe";
		form.addElement(new sugoi.form.elements.Html("Confirmez votre inscription à \""+group.name+"\""));
		if (app.user == null){
			form.addElement(new StringInput("userFirstName", "Votre prénom","",true));
			form.addElement(new StringInput("userLastName", "Votre nom de famille", "", true));
			var em = new StringInput("userEmail", "Votre email", "", true);
			em.addValidator(new EmailValidator());
			form.addElement(em);		
			form.addElement(new StringInput("address", "Adresse", "", true));					
			form.addElement(new StringInput("zipCode", "Code postal", "", true));		
			form.addElement(new StringInput("city", "Ville", "", true));		
			form.addElement(new StringInput("phone", "Téléphone", "", true));		
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
					throw Ok("/user/login","Vous êtes déjà enregistré dans Cagette.net, Connectez-vous à partir de cette page");
				}
				
				user.insert();				
				app.session.setUser(user);
				
			}			
			
			var w = new db.UserAmap();
			w.user = app.user;
			w.amap = group;
			w.insert();
			
			throw Ok("/user/choose","Votre inscription a été prise en compte.");
		}
		
		view.title = "Inscription à \"" + group.name+"\"";
		view.form = form;
		
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
				g.flags.set(db.Amap.AmapFlags.HasMembership);
				g.regOption = db.Amap.RegOption.WaitingList;
				
			case GroupType.GroupedOrders :
				g.flags.set(db.Amap.AmapFlags.ShopMode);
				g.flags.set(db.Amap.AmapFlags.HasMembership);
				g.regOption = db.Amap.RegOption.WaitingList;
				
			case GroupType.ProducerDrive : 
				g.flags.set(db.Amap.AmapFlags.ShopMode);
				g.regOption = db.Amap.RegOption.Open;
				
			case GroupType.FarmShop : 
				g.flags.set(db.Amap.AmapFlags.ShopMode);
				g.regOption = db.Amap.RegOption.Open;
			}
			
			g.groupType = type;
			g.insert();
			
			var ua = new db.UserAmap();
			ua.user = user;
			ua.amap = g;
			ua.rights = [db.UserAmap.Right.AmapAdmin,db.UserAmap.Right.Membership,db.UserAmap.Right.Messages,db.UserAmap.Right.ContractAdmin(null)];
			ua.insert();
			
			//example datas
			var place = new db.Place();
			place.name = "Place du marché";
			place.zipCode  = "000";
			place.city = "St Martin de la Cagette";
			place.amap = g;
			place.insert();
			
			//contrat AMAP
			var vendor = new db.Vendor();
			vendor.amap = g;
			vendor.name = "Jean Martin EURL";
			vendor.zipCode = "000";
			vendor.city = "Langon";
			vendor.email = "jean@cagette.net";
			vendor.insert();			
			
			if (type == Amap){
				var contract = new db.Contract();
				contract.name = "Contrat AMAP Maraîcher Exemple";
				contract.description = "Ce contrat est un exemple de contrat maraîcher avec engagement à l'année comme on le trouve dans les AMAP.";
				contract.amap  = g;
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
				p.organic = true;
				p.contract = contract;
				p.insert();
				
				var p = new db.Product();
				p.name = "Petit panier de légumes";
				p.price = 10;
				p.organic = true;
				p.contract = contract;
				p.insert();
			
				db.UserContract.make(user, 1, p, null, true);
				
				var d = new db.Distribution();
				d.contract = contract;
				d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
				d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
				d.place = place;
				d.insert();
				
			}
			
			
			
			//contrat variable
			var vendor = new db.Vendor();
			vendor.amap = g;
			vendor.name = "Ferme de la Galinette";
			vendor.zipCode = "000";
			vendor.city = "Bazas";
			vendor.email = "galinette@cagette.net";
			vendor.insert();			
			
			var contract = new db.Contract();
			contract.name = "Contrat Poulet Exemple";
			contract.description = "Exemple de contrat à commande variable. Il permet de commander quelque chose de différent à chaque distribution.";
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
			egg.name = "Douzaine d'oeufs bio";
			egg.price = 5;
			egg.type = 6;
			egg.organic = true;
			egg.contract = contract;
			egg.insert();
			
			var p = new db.Product();
			p.name = "Poulet bio";
			p.type = 2;
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
			
			db.UserContract.make(user, 2, egg, d.id);
			db.UserContract.make(user, 1, p, d.id);
			
			App.current.session.data.amapId  = g.id;
			app.session.data.newGroup = true;
			throw Redirect("/");
		}
		
		view.form= f;
		
	}
	
	@tpl('group/place.mtt')
	public function doPlace(place:db.Place){
		view.place = place;
		
		//build adress for google maps
		var addr = "";
		if (place.address1 != null)
			addr += place.address1;
			
		if (place.address2 != null) {
			addr += ", " + place.address2;
		}
		
		if (place.zipCode != null) {
			addr += " " + place.zipCode;
		}
		
		if (place.city != null) {
			addr += " " + place.city;
		}
		
		view.addr = view.escapeJS(addr);
	}
	
	
}