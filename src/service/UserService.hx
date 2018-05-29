package service;
import tink.core.Error;

/**
 * User Service
 * @author fbarbut
 */
class UserService
{
	
	var user : db.User;
	
	public function new(u:db.User) 
	{
		this.user = u;		
	}
	
	/**
	 * Login service
	 * @param	email
	 * @param	password
	 */
	public static function login(email:String, password:String){
		
		var t  = sugoi.i18n.Locale.texts;
		
		//user exists ?
		var user = db.User.manager.select( $email == email || $email2 == email , true);
		if (user == null) throw new Error(404,t._("There is no account with this email"));
		
		//new account
		if (!user.isFullyRegistred()) {
			user.sendInvitation();
			throw t._("Your account have not been validated yet. We sent an e-mail to ::email:: to finalize your subscription!",{email:user.email});			
		}
		
		var pass = haxe.crypto.Md5.encode( App.config.get('key') + password );
		
		if (user.pass != pass) {
			throw new Error(403,t._("Invalid password"));
		}
		
		db.User.login(user, email);
		
		//register the user to the current group if needed
		var group = App.current.getCurrentGroup();	
		if (group != null && group.regOption == db.Amap.RegOption.Open && db.UserAmap.get(user, group) == null){
			user.makeMemberOf(group);			
		}
		
	}
	
	
	public static function register(firstName:String, lastName:String, email:String, phone:String, pass:String){
		
		var t  = sugoi.i18n.Locale.texts;
		
		if (!sugoi.form.validators.EmailValidator.check(email)){
			throw new Error(500,t._("Invalid email address"));
		}
		
		if ( db.User.getSameEmail(email).length > 0 ) {
			throw new Error(409,t._("We already have an account with this email address"));
		}

		var user = new db.User();
		user.email = email;
		user.firstName = firstName;
		user.lastName = lastName;
		user.phone = phone;
		user.setPass(pass);
		user.insert();				
		
		
		var group = App.current.getCurrentGroup();	
		if (group != null && group.regOption == db.Amap.RegOption.Open){
			user.makeMemberOf(group);	
		}
		
		db.User.login(user, email);		
	}

	/**
	 *  get users belonging to a group
	 *  @param group - 
	 *  @return Array<db.User>
	 */
	public static function getFromGroup(group:db.Amap):Array<db.User>{
		return Lambda.array( group.getMembers() );
	}
}