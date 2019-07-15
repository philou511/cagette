package controller;
import sugoi.form.Form;
import sugoi.form.elements.StringSelect;

class Account extends Controller
{

	public function new()
	{
		super();
	}
	
	function doDefault() {}
	
	@tpl('form.mtt')
	function doEdit() {
		
		var form = db.User.getForm(app.user);
		
		if (form.isValid()) {
			
			if (app.user.id != form.getValueOf("id")) {
				throw "access forbidden";
			}
			var admin = app.user.isAdmin();
			
			form.toSpod(app.user); 
			
			//check email is valid
			if (!sugoi.form.validators.EmailValidator.check(app.user.email)){
				throw Error("/account/edit", t._("Email ::em:: is invalid", {em:app.user.email}));
			}
			
			if (app.user.email2!=null && !sugoi.form.validators.EmailValidator.check(app.user.email2)){
				throw Error("/account/edit", t._("Email ::em:: is invalid", {em:app.user.email2}));
			}

			//check email is available
			var sameEmail = db.User.getSameEmail(app.user.email,app.user.email2);
			if( sameEmail.length > 0 && sameEmail.first().id!=app.user.id){
				throw Error("/account/edit", t._("This email is already used by another account."));
			}
			
			if (!admin) { app.user.rights.unset(Admin); }

			//Check that the user is at least 18 years old
			if (!service.UserService.isBirthdayValid(app.user.birthDate)) {
				app.user.birthDate = null;
			 }
			
			app.user.update();
			throw Ok('/contract', t._("Your account has been updated"));
		}
		
		view.form = form;
		view.title = t._("Modify my account");
	}
	
	/**
		Quit group
	**/
	function doQuit(){
		if (checkToken()){
			var name = app.user.amap.name;
			var ua = db.UserAmap.get(app.user, app.user.amap,true);
			ua.delete();
			App.current.session.data.amapId = null;
			throw Ok("/user/choose?show=1", t._("You left the group ::groupName::", {groupName:name}));
		}
	}

	/**
		View a basket in a popup
	**/
	@tpl('account/basket.mtt')
	function doBasket(basket : db.Basket){
		view.basket = basket;
		view.orders = service.OrderService.prepare(basket.getOrders());
	}
	
	/**
	 * user payments history
	 */
	@tpl('account/payments.mtt')
	function doPayments(){
		var m = app.user;
		var browse:Int->Int->List<Dynamic>;
		
		//default display
		browse = function(index:Int, limit:Int) {
			return db.Operation.getOperationsWithIndex(m,app.user.amap,index,limit,true);
		}
		
		var count = db.Operation.countOperations(m,app.user.amap);
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.rb = rb;
		view.member = m;
		view.balance = db.UserAmap.get(m,app.user.amap).balance;
	}
	
	
}