package controller.api;
import service.MembershipService;
import haxe.Json;
import tink.core.Error;
import service.PaymentService;
import Common;
import jwt.JWT;

/**
 * Public user API
 */
class User extends Controller
{

	public function doDefault(user:db.User){
		//get a user
	}

	public function doMe() {
		if (App.current.user == null) throw new Error(Unauthorized, "Access forbidden");
		var current = App.current.user;

		if (sugoi.Web.getMethod() == "GET") {
			return Sys.print(haxe.Json.stringify(current.infos()));
		} else if (sugoi.Web.getMethod() == "POST") {
			var request = sugoi.tools.Utils.getMultipart( 1024 * 1024 * 10 ); //10Mb	

			current.lock();
			
			if (request.exists("address1")) current.address1 = request.get("address1");
			if (request.exists("address2")) current.address2 = request.get("address2");
			if (request.exists("city")) current.city = request.get("city");
			if (request.exists("zipCode")) current.zipCode = request.get("zipCode");
			if (request.exists("phone")) current.phone = request.get("phone");

			current.update();

			return Sys.print(haxe.Json.stringify(current.infos()));
		} else throw new Error(405, "Method Not Allowed");
	}
	
	/**
	 * Login
	 */
	public function doLogin(){
		
		//cleaning
		var email = StringTools.trim(App.current.params.get("email")).toLowerCase();
		var pass = StringTools.trim(App.current.params.get("password"));
		var user = service.UserService.login(email, pass);
		var token : String = JWT.sign({ email: email, id: user.id }, App.config.get("key"));
		Sys.print(
			Json.stringify({ 
				success: true,
				token:token 
			})
		);
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
		var address = p.exists("address1") ? StringTools.trim(p.get("address1")) : null;
		var zipCode = p.exists("zipCode") ? StringTools.trim(p.get("zipCode")) : null;
		var city = p.exists("city") ? StringTools.trim(p.get("city")) : null;
		var tos = p.get("tos")=="1";

		
		service.UserService.register(firstName, lastName, email, phone, pass, address, zipCode, city, tos);
		
		json({success:true});
	}


	/**
	 *  get users of current group
	 */
	@logged
	function doGetFromGroup(){

		if(!app.user.canAccessMembership() && !app.user.isContractManager()) {
			throw new tink.core.Error(403,"Access forbidden");
		}

		var members:Array<UserInfo> = service.UserService.getFromGroup(app.user.getGroup()).map( m -> m.infos() );
		Sys.print(tink.Json.stringify({users:members}));
	}


	@logged
	function doGetToken() {
		var token : String = JWT.sign({ email: App.current.user.email, id: App.current.user.id }, App.config.get("key"));
		Sys.print(
			Json.stringify({ 
				token:token 
			})
		);
	} 
	
}