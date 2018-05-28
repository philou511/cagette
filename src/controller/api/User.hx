package controller.api;
import haxe.Json;
import tink.core.Error;
import Common;

/**
 * Public user API
 */
class User extends Controller
{
	
	/**
	 * Login
	 */
	public function doLogin(){
		
		//cleaning
		var email = StringTools.trim(App.current.params.get("email")).toLowerCase();
		var pass = StringTools.trim(App.current.params.get("password"));
		
		service.UserService.login(email, pass);
		
		Sys.print(Json.stringify({success:true}));
	}
	
	/**
	 * Register
	 */
	public function doRegister(){
		
		//cleaning
		var p = app.params;
		var email = StringTools.trim(p.get("email")).toLowerCase();
		var pass = StringTools.trim(p.get("password"));
		var firstName = StringTools.trim(p.get("firstName"));
		var lastName = StringTools.trim(p.get("lastName")).toUpperCase();
		var phone = p.exists("phone") ? StringTools.trim(p.get("phone")) : null;
		
		service.UserService.register(firstName, lastName, email, phone, pass);
		
		Sys.print(Json.stringify({success:true}));
	}


	/**
	 *  get users of current group
	 */
	@logged
	function doGetFromGroup(){

		if(!app.user.canAccessMembership()) throw new tink.core.Error(403,"Access forbidden");

		var members:Array<UserInfo> = service.UserService.getFromGroup(app.user.amap).map(function(m) return m.infos() );
		Sys.print(tink.Json.stringify({users:members}));
	}
	
}