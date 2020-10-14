package controller;
import sugoi.form.elements.Html;
import sugoi.form.elements.StringInput;
import sugoi.form.elements.Checkbox;
import db.UserOrder;
import sugoi.form.Form;

class Amap extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("amap/default.mtt")
	function doDefault() {
		var contracts = db.Catalog.getActiveContracts(app.user.getGroup(), true, false);
		for ( c in Lambda.array(contracts).copy()) {
			if (c.endDate.getTime() < Date.now().getTime() ) contracts.remove(c);
		}
		view.contracts = contracts;
	}
	
	@tpl("form.mtt")
	function doEdit() {
		
		if (!app.user.isAmapManager()) throw t._("You don't have access to this section");
		
		var group = app.user.getGroup();
		
		var form = form.CagetteForm.fromSpod(group);

		//remove "membership", "shop mode", "marge a la place des %", "unused" from flags
		var flags = form.getElement("flags");
		untyped flags.excluded = [0,1,3,9];

		//group mode
		var mode = group.flags.has(db.Group.GroupFlags.ShopMode) ? "Mode Boutique" : "Mode AMAP";
		var html = new sugoi.form.elements.Html("mode",mode,"Mode de commande");
		html.docLink = "https://wiki.cagette.net/admin:admin_boutique";
		form.addElement(html ,7);
	
		if (form.checkToken()) {
			
			if(form.getValueOf("id") != app.user.getGroup().id) {
				var editedGroup = db.Group.manager.get(form.getValueOf("id"),false);
				throw Error("/amap/edit",'Erreur, vous êtes en train de modifier "${editedGroup.name}" alors que vous êtes connecté à "${app.user.getGroup().name}"');
			}
			
			var shopMode = group.hasShopMode();

			form.toSpod(group);

			//keep shop mode
			if(shopMode) group.flags.set(db.Group.GroupFlags.ShopMode);

			if(group.betaFlags.has(db.Group.BetaFlags.ShopV2) && group.flags.has(db.Group.GroupFlags.CustomizedCategories)){
				App.current.session.addMessage("Vous ne pouvez pas activer les catégories personnalisées et la nouvelle boutique. La nouvelle boutique ne fonctionne pas avec les catégories personnalisées.",true);
				group.flags.unset(db.Group.GroupFlags.CustomizedCategories);
				group.update();
			}

			//warning AMAP+payments
			/* JB
			if( !group.flags.has(db.Group.GroupFlags.ShopMode) &&  group.hasPayments() ){
				//App.current.session.addMessage("ATTENTION : nous ne vous recommandons pas d'activer la gestion des paiements si vous êtes une AMAP. Ce cas de figure n'est pas bien géré par Cagette.net.",true);
				App.current.session.addMessage("L'activation de la gestion des paiements n'est pas autorisée si vous êtes une AMAP. Ce cas de figure n'est pas bien géré par Cagette.net.",true);
				group.flags.unset(db.Group.GroupFlags.HasPayments);
				group.update();
			} */
			
			if (group.extUrl != null){
				if ( group.extUrl.indexOf("http://") ==-1 &&  group.extUrl.indexOf("https://") ==-1 ){
					group.extUrl = "http://" + group.extUrl;
				}
			}
			
			group.update();
			throw Ok("/amapadmin", t._("The group has been updated."));
		}
		
		view.form = form;
	}

	@tpl('amap/subscriptionspayments.mtt')
	function doPayments( user : db.User, ?args: { account: Bool } ) {

		if ( args != null && args.account == true ) {

			view.account = args.account;
			
			app.breadcrumb = [ { id : 'account', name : 'Mon compte', link : '/account' }, { id : 'account', name : 'Mon compte', link : '/account' } ];
			// app.breadcrumb.push( { id : 'amap', name : 'Mon compte', link : '/amap' } );
			// app.breadcrumb.find( x -> x.id == 'amap' ).name = 'Mon compte';
		}
		else {

			app.breadcrumb = [ { id : 'member', name : 'Membres', link : '/member' }, { id : 'member', name : 'Membres', link : '/member' } ];
		}
		
	// 	service.PaymentService.updateUserBalance(m, app.user.getGroup());		
    //    var browse:Int->Int->List<Dynamic>;
		
	// 	//default display
	// 	browse = function(index:Int, limit:Int) {
	// 		return db.Operation.getOperationsWithIndex(m,app.user.getGroup(),index,limit,true);
	// 	}
		
	// 	var count = db.Operation.countOperations(m,app.user.getGroup());
	// 	var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
	// 	view.rb = rb;
		// view.member = m;
		// view.balance = db.UserGroup.get(m, app.user.getGroup()).balance;

		var subscriptionsByCatalog = service.SubscriptionService.getActiveSubscriptionsByCatalog( app.user, app.user.getGroup() );
		view.subscriptionsByCatalog = subscriptionsByCatalog;
		// view.subscriptionService = SubscriptionService;

		// var subscription = db.Subscription.manager.get( 372 );
		
		// view.operations = operations;
		view.member = user;
		// view.subscription = subscription;
		// view.subscriptionTotal = subscription.getTotalPrice();
		// view.subscriptionPayments = subscription.getPaymentsTotal();
		// view.nav.push( 'members' );

		var operationsBySubscription = new Map< db.Subscription, Array< db.Operation > >();

		for ( catalog in subscriptionsByCatalog.keys() ) {

			for ( subscription in subscriptionsByCatalog[catalog] ) {

				if ( operationsBySubscription[subscription] == null ) {
					operationsBySubscription[subscription] = [];
				}

				var operations = db.Operation.manager.search( $user == user && $subscription == subscription, null, false ).array();
				operationsBySubscription[subscription] = operationsBySubscription[subscription].concat( operations );
			}
		}

		view.operationsBySubscription = operationsBySubscription;
		
		checkToken();
	}
	
}