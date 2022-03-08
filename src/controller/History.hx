package controller;
import db.Subscription;
import service.OrderService;
import db.MultiDistrib;
import service.SubscriptionService;
import sugoi.form.Form;
import sugoi.form.elements.StringSelect;
import db.Operation;
import Common;
using Std;
// import plugin.Tutorial;

class History extends Controller
{

	public function new()
	{
		super();
	}
	
	/**
	 * history page
	 */
	@logged
	@tpl("history/default.mtt")
	function doDefault() {
		
		var ua = db.UserGroup.get(app.user, app.user.getGroup());
		if (ua == null) throw Error("/", t._("You are not a member of this group"));
		
		var varOrders = new Map<String,Array<db.UserOrder>>();
		
		var group = App.current.user.getGroup();		
		var from  = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30);
		var to 	  = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 30 * 6);
		
		//constant orders
		view.subscriptionsByCatalog = SubscriptionService.getActiveSubscriptionsByCatalog( app.user, group );
		view.subscriptionService = SubscriptionService;
				
		//variable orders, grouped by date
		var distribs = MultiDistrib.getFromTimeRange( group , from , to  );
		//sort by date desc
		distribs.sort(function(a,b){
			return Math.round(b.distribStartDate.getTime()/1000) - Math.round(a.distribStartDate.getTime()/1000);
		});
		view.distribs = distribs;
		view.prepare = OrderService.prepare;
		
		// // tutorials
		// if (app.user.isAmapManager()) {
			
		// 	//actions
		// 	if (app.params.exists('startTuto') ) {
				
		// 		//start a tuto
		// 		app.user.lock();
		// 		var t = app.params.get('startTuto'); 
		// 		app.user.tutoState = {name:t,step:0};
		// 		app.user.update();
		// 	}
		
		// 	//tuto state
		// 	var tutos = new Array<{name:String,completion:Float,key:String}>();
			
		// 	for ( k in Tutorial.all().keys() ) {	
		// 		var t = Tutorial.all().get(k);
				
		// 		var completion = null;
		// 		if (app.user.tutoState!=null && app.user.tutoState.name == k) completion = app.user.tutoState.step / t.steps.length;
				
		// 		tutos.push( { name:t.name, completion:completion , key:k } );
		// 	}
			
		// 	view.tutos = tutos;
		// }
		
		// //should be able to stop tuto in any case
		// if (app.params.exists('stopTuto')) {
		// 	//stopped tuto from a tuto window
		// 	app.user.lock();
		// 	app.user.tutoState = null;
		// 	app.user.update();	
		// 	view.stopTuto = true;
		// }
		
		checkToken();
		view.userGroup = ua;
	}


	/**
		View a basket in a popup
	**/
	@logged
	@tpl('history/basket.mtt')
	function doBasket(basket : db.Basket, ?type:Int){
		view.basket = basket;
		view.orders = service.OrderService.prepare(basket.getOrders(type));
		view.print = app.params["print"]!=null;
	}
	
	/**
	 * user payments history -----> a quel moment c'est utilisé ça ?
	 */
	@logged
	@tpl('history/payments.mtt')
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
	@tpl("history/csaorders.mtt")
	function doOrders( catalog : db.Catalog ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));
	
		var	catalogDistribs = db.Distribution.manager.search( $catalog == catalog , { orderBy : date }, false ).array();
		view.distribs = catalogDistribs;
		view.prepare = OrderService.prepare;
		view.catalog = catalog;
		// view.history = true;
		view.now = Date.now();
		view.member = app.user;
		
		// checkToken();
	}

	/**
		view orders of a subscription
	**/
	@logged
	@tpl("history/csaorders.mtt")
	function doSubscriptionOrders( sub : Subscription ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));
	
		view.distribs = SubscriptionService.getSubscriptionDistributions(sub);
		view.prepare = OrderService.prepare;
		view.catalog = sub.catalog;
		view.now = Date.now();
		view.member = app.user;
	}
	
	@logged
	@tpl("history/subscriptionpayments.mtt")
	function doSubscriptionPayments( subscription : db.Subscription ) {
		
		var ug = db.UserGroup.get(app.user, app.user.getGroup());
		if (ug == null) throw Error("/", t._("You are not a member of this group"));

		var user = subscription.user;
		var payments = db.Operation.manager.search( $subscription == subscription && $type == OperationType.Payment, { orderBy : -date }, false );
		view.subscriptionTotal = SubscriptionService.createOrUpdateTotalOperation( subscription );		
		view.payments = payments;
		view.member = user;
		view.subscription = subscription;
		
	}
	
}