package controller.api;
import service.MembershipService;
import haxe.Json;
import tink.core.Error;
import service.PaymentService;
import Common;

/**
 * Public user API
 */
class User extends Controller
{

	public function doDefault(user:db.User){
		//get a user
	}

	/**
		get membership status of a user in a group
	**/
	public function doMembership(user:db.User,group:db.Group){
		var ug = db.UserGroup.get(user,group);
		if(ug==null){
			throw new Error(403,"Not found");
		}else{
			var out = {
				userName:null,
				availableYears: new Array<{name:String,id:Int}>(),
				memberships: new Array<{name:String,id:Int,date:Date}>(),
				membershipFee:null,
				distributions: new Array<{name:String,id:Int}>(),
				paymentTypes: new Array<{id:String,name:String}>(),
			};

			out.userName = user.getName();
			out.membershipFee = group.membershipFee;
			if(group.hasPayments()){
				out.paymentTypes = PaymentService.getPaymentTypes(PaymentContext.PCManualEntry, group).map(p -> return {id:p.type,name:p.name});
			}
			var ms = new MembershipService(group);
			out.memberships = ms.getUserMemberships(user).map(m->{
				return {
					id : m.year ,
					name : ms.getPeriodName(m.year),
					date : m.date
				};
			});
			

			Sys.print(haxe.Json.stringify(out));
		}
	}
	
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
		var address = p.exists("address1") ? StringTools.trim(p.get("address1")) : null;
		var zipCode = p.exists("zipCode") ? StringTools.trim(p.get("zipCode")) : null;
		var city = p.exists("city") ? StringTools.trim(p.get("city")) : null;
		
		service.UserService.register(firstName, lastName, email, phone, pass, address, zipCode, city);
		
		Sys.print(Json.stringify({success:true}));
	}


	/**
	 *  get users of current group
	 */
	@logged
	function doGetFromGroup(){

		if(!app.user.canAccessMembership() && !app.user.isContractManager()) {
			throw new tink.core.Error(403,"Access forbidden");
		}

		var members:Array<UserInfo> = service.UserService.getFromGroup(app.user.getGroup()).map(function(m) return m.infos() );
		Sys.print(tink.Json.stringify({users:members}));
	}
	
}