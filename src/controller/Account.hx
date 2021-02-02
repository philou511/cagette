package controller;
import db.Subscription;
import service.OrderService;
import db.MultiDistrib;
import service.SubscriptionService;
import sugoi.form.Form;
import sugoi.form.elements.StringSelect;
import Common;
using Std;
import plugin.Tutorial;

class Account extends Controller
{

	public function new()
	{
		super();
	}
	
	/**
	 * "my account" page
	 */
	@logged
	@tpl("account/default.mtt")
	function doDefault() {
		
		//Create the list of links to change the language
		var langs = App.config.get("langs").split(";");
		var langNames = App.config.get("langnames").split(";");
		var i=0;
		var langLinks = "";
		for (lang in langs)
		{
			langLinks += "<li><a href=\"?lang=" + langs[i] + "\">" + langNames[i] + "</a></li>";
			i++;
		}
		view.langLinks = langLinks;
		view.langText = langNames[langs.indexOf(app.session.lang)];

		//change account lang
		if (app.params.exists("lang") && app.user!=null){
			app.user.lock();
			app.user.lang = app.params.get("lang");
			app.user.update();
		}
		
		var ua = db.UserGroup.get(app.user, app.user.getGroup());
		if (ua == null) throw Error("/", t._("You are not a member of this group"));
		
		var varOrders = new Map<String,Array<db.UserOrder>>();
		
		var group = App.current.user.getGroup();		
		var oneMonthAgo = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30);
		var inOneMonth = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 30);
		
		//constant orders
		view.subscriptionsByCatalog = SubscriptionService.getActiveSubscriptionsByCatalog( app.user, group );
		view.subscriptionService = SubscriptionService;
				
		//variable orders, grouped by date
		var distribs = MultiDistrib.getFromTimeRange( group , oneMonthAgo , inOneMonth  );
		//sort by date desc
		distribs.sort(function(a,b){
			return Math.round(b.distribStartDate.getTime()/1000) - Math.round(a.distribStartDate.getTime()/1000);
		});
		view.distribs = distribs;
		view.prepare = OrderService.prepare;
		
		// tutorials
		if (app.user.isAmapManager()) {
			
			//actions
			if (app.params.exists('startTuto') ) {
				
				//start a tuto
				app.user.lock();
				var t = app.params.get('startTuto'); 
				app.user.tutoState = {name:t,step:0};
				app.user.update();
			}
		
			//tuto state
			var tutos = new Array<{name:String,completion:Float,key:String}>();
			
			for ( k in Tutorial.all().keys() ) {	
				var t = Tutorial.all().get(k);
				
				var completion = null;
				if (app.user.tutoState!=null && app.user.tutoState.name == k) completion = app.user.tutoState.step / t.steps.length;
				
				tutos.push( { name:t.name, completion:completion , key:k } );
			}
			
			view.tutos = tutos;
		}
		
		//should be able to stop tuto in any case
		if (app.params.exists('stopTuto')) {
			//stopped tuto from a tuto window
			app.user.lock();
			app.user.tutoState = null;
			app.user.update();	
			view.stopTuto = true;
		}
		
		checkToken();
		view.userGroup = ua;
	}
	
	@logged
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
		View a basket in a popup
	**/
	@logged
	@tpl('account/basket.mtt')
	function doBasket(basket : db.Basket, ?type:Int){
		view.basket = basket;
		view.orders = service.OrderService.prepare(basket.getOrders(type));
		view.print = app.params["print"]!=null;
	}
	
	/**
	 * user payments history
	 */
	@logged
	@tpl('account/payments.mtt')
	function doPayments(){
		var m = app.user;
		var browse:Int->Int->List<Dynamic>;
		
		//default display
		browse = function(index:Int, limit:Int) {
			return db.Operation.getOperationsWithIndex(m,app.user.getGroup(),index,limit,true);
		}
		
		var count = db.Operation.countOperations(m,app.user.getGroup());
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.rb = rb;
		view.member = m;
		view.balance = db.UserGroup.get(m,app.user.getGroup()).balance;
	}

	/**
		view orders in a CSA contract
    **/
	@logged
	@tpl("account/csaorders.mtt")
	function doOrders( catalog : db.Catalog ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));
	
		var	catalogDistribs = db.Distribution.manager.search( $catalog == catalog , { orderBy : date }, false ).array();
		view.distribs = catalogDistribs;
		view.prepare = OrderService.prepare;
		view.catalog = catalog;
		// view.account = true;
		view.now = Date.now();
		view.member = app.user;
		
		// checkToken();
	}

	/**
		view orders of a subscription
	**/
	@tpl("account/csaorders.mtt")
	function doSubscriptionOrders( sub : Subscription ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));
	
		view.distribs = SubscriptionService.getSubscriptionDistribs(sub);
		view.prepare = OrderService.prepare;
		view.catalog = sub.catalog;
		// view.account = true;
		view.now = Date.now();
		view.member = app.user;
		
		// checkToken();
	}

	@tpl("account/subscriptionpayments.mtt")
	function doSubscriptionPayments( sub : Subscription ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));
	
		
		
		var operations = SubscriptionService.getOperations(sub);
		
		view.member = sub.user;
		view.subscription = sub;
		view.operations = operations;
	}

	/**
		Edit notifications.  Should work even if user is not logged in. ( link in emails footer )
	**/
	@tpl('account/editNotif.mtt')
	function doEditNotif(user:db.User,key:String){

		if (haxe.crypto.Sha1.encode(App.config.KEY+user.id) != key){
			throw Error("/","Lien invalide"+haxe.crypto.Sha1.encode(App.config.KEY+user.id)+"___"+key);
		}

		view.member = user;

		var form = db.User.getForm(app.user);
		form.removeElement(form.getElement("firstName"));
		form.removeElement(form.getElement("lastName"));
		form.removeElement(form.getElement("email"));
		form.removeElement(form.getElement("phone"));
		form.removeElement(form.getElement("firstName2"));
		form.removeElement(form.getElement("lastName2"));
		form.removeElement(form.getElement("email2"));
		form.removeElement(form.getElement("phone2"));
		form.removeElement(form.getElement("address1"));
		form.removeElement(form.getElement("address2"));
		form.removeElement(form.getElement("zipCode"));
		form.removeElement(form.getElement("city"));
		form.removeElement(form.getElement("birthDate"));
		form.removeElement(form.getElement("nationality"));
		form.removeElement(form.getElement("countryOfResidence"));
		
		if (form.isValid()) {
			var url = app.user==null ? "/user/" : "/user/choose?show=1";
			form.toSpod(app.user); 
			app.user.update();
			throw Ok(url, t._("Your account has been updated"));
		}
		
		view.form = form;
	}

}