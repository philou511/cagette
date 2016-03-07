package controller;


/**
 * Public pages controller
 */
class Group extends controller.Controller
{

	@tpl('group/view.mtt')
	function doDefault(group:db.Amap){
		view.group = group;
		view.contracts = group.getActiveContracts();
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
			form.addElement(new sugoi.form.elements.Input("userFirstName", "Votre prénom","",true));
			form.addElement(new sugoi.form.elements.Input("userLastName", "Votre nom de famille","",true));
			form.addElement(new sugoi.form.elements.Input("userEmail", "Votre email", "", true));		
		}
		form.addElement(new sugoi.form.elements.TextArea("msg", "Laissez un message"));
		
		if (form.isValid()){
			
			if (app.user == null){
				var f = form;
				var user = new db.User();
				user.email = f.getValueOf("userEmail");
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				
				if ( db.User.getSimilar(user.firstName, user.lastName, user.email).length > 0 ) {
					throw Ok("/user/login","Vous êtes déjà enregistré dans Cagette.net, Connectez-vous à votre groupe à partir de cette page");
				}
				
				user.insert();
				app.session.setUser(user);
				
			}			
			
			var w = new db.WaitingList();
			w.user = app.user;
			w.amap = group;
			w.message = form.getValueOf("msg");
			w.insert();
			
			throw Ok("/group/" + group.id,"Votre inscription en liste d'attente a été prise en compte. Vous serez prévenu par email lorsque votre demande sera traitée.");
		}
		
		view.title = "Inscription en liste d'attente à \"" + group.name+"\"";
		view.form = form;
		
	}
	
	
	/**
	 * register direclty
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
			form.addElement(new sugoi.form.elements.Input("userFirstName", "Votre prénom","",true));
			form.addElement(new sugoi.form.elements.Input("userLastName", "Votre nom de famille","",true));
			form.addElement(new sugoi.form.elements.Input("userEmail", "Votre email", "", true));		
		}
		
		if (form.isValid()){
			
			if (app.user == null){
				var f = form;
				var user = new db.User();
				user.email = f.getValueOf("userEmail");
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				
				if ( db.User.getSimilar(user.firstName, user.lastName, user.email).length > 0 ) {
					throw Ok("/user/login","Vous êtes déjà enregistré dans Cagette.net, Connectez-vous à votre groupe à partir de cette page");
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
	
	
}