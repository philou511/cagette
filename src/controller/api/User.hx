package controller.api;
import haxe.Json;
import tink.core.Error;

class User extends Controller
{
	
	/**
	 * Login service
	 */
	public function doLogin(){
		
		//cleaning
		var email = StringTools.trim(App.current.params.get("email")).toLowerCase();
		var pass = StringTools.trim(App.current.params.get("password"));
		
		//user exists ?
		var user = db.User.manager.select( $email == email || $email2 == email , true);
		if (user == null) throw new Error(404,"Cet utilisateur n'existe pas");
		
		//new account
		if (!user.isFullyRegistred()) {
			user.sendInvitation();
			throw "Votre compte n'a pas encore été validé. Nous vous avons envoyé un email à <b>" + user.email + "</b> pour finaliser votre inscription !";			
		}
		
		var pass = haxe.crypto.Md5.encode( App.config.get('key') + pass );
		
		if (user.pass != pass) {
			throw new Error(400,"Mot de passe invalide.");
		}
		
		db.User.login(user, email);
		
		//register the user to the current group if needed
		var group = App.current.getCurrentGroup();	
		if (group != null && group.regOption == db.Amap.RegOption.Open && db.UserAmap.get(user, group) == null){			
			var w = new db.UserAmap();
			w.user = user;
			w.amap = group;
			w.insert();	
		}
		
		Sys.print(Json.stringify({success:true}));
	}
	
	/**
	 * Register service
	 */
	public function doRegister(){
		
		//cleaning
		var p = App.current.params;
		var email = StringTools.trim(p.get("email")).toLowerCase();
		var pass = StringTools.trim(p.get("password"));
		var firstName = StringTools.trim(p.get("firstName"));
		var lastName = StringTools.trim(p.get("lastName")).toUpperCase();
		
		if (!sugoi.form.validators.EmailValidator.check(email)){
			throw new Error(500,"L'adresse email que vous avez saisie est invalide");
		}
		
		if ( db.User.getSameEmail(email).length > 0 ) {
			throw new Error(409,"Il existe déjà un compte avec cet email.");
		}

		var user = new db.User();
		user.email = email;
		user.firstName = firstName;
		user.lastName = lastName;
		if(p.get("phone")!=null) user.phone = StringTools.trim(p.get("phone"));
		user.setPass(pass);
		user.insert();				
		
		var group = App.current.getCurrentGroup();	
		if (group != null){
			var w = new db.UserAmap();
			w.user = user;
			w.amap = group;
			w.insert();	
		}
		
		db.User.login(user, email);
		
		Sys.print(Json.stringify({success:true}));
	}
	
}