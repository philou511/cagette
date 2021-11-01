package controller;
import service.PaymentService;
import service.SubscriptionService;
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
		var contracts = db.Catalog.getActiveContracts(app.user.getGroup(), true, false).array();
		for ( c in contracts.copy()) {
			if( c.endDate.getTime() < Date.now().getTime() ) contracts.remove(c);
			if( c.vendor.isDisabled()) contracts.remove(c);
		}
		view.contracts = contracts;
		view.group = app.user.getGroup();
	}
	
	@tpl("form.mtt")
	function doEdit() {
		
		if (!app.user.isAmapManager()) throw t._("You don't have access to this section");
		
		var group = app.user.getGroup();
		
		var form = form.CagetteForm.fromSpod(group);

		form.removeElementByName("betaFlags");
		// var flags = form.getElement("betaFlags");
		// untyped flags.excluded = [0];

		//remove "membership", "shop mode", "marge a la place des %", "unused" from flags
		var flags = form.getElement("flags");
		untyped flags.excluded = [0,1,3,5,9];
		if(!group.hasShopMode()) untyped flags.excluded.push(2);

		//group mode
		var mode = group.flags.has(db.Group.GroupFlags.ShopMode) ? "Mode Marché" : "Mode AMAP";
		var html = new sugoi.form.elements.Html("mode",mode,"Mode de commande");
		html.docLink = "https://wiki.cagette.net/admin:admin_boutique";
		form.addElement(html ,7);
	
		if(group.hasShopMode()){
			//payment help
			var html = new sugoi.form.elements.Html("payments","<p class='desc'><a href='https://formation.alilo.fr/mod/page/view.php?id=821' target='_blank'><i class=\"icon icon-info\"></i> En savoir plus sur la gestion des paiements</a></p>","");
			form.addElement(html ,9);
		}

		if (form.checkToken()) {
			
			if(form.getValueOf("id") != app.user.getGroup().id) {
				var editedGroup = db.Group.manager.get(form.getValueOf("id"),false);
				throw Error("/amap/edit",'Erreur, vous êtes en train de modifier "${editedGroup.name}" alors que vous êtes connecté à "${app.user.getGroup().name}"');
			}
			
			var shopMode = group.hasShopMode();
			var hasPayments = group.hasPayments();

			form.toSpod(group);

			//keep shop mode
			if(shopMode) group.flags.set(db.Group.GroupFlags.ShopMode);

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

	/**
		Displays payments page for CSA groups.
		If user is sent in param, displays user's payment, otherwise displays current user payments.
	**/
	// @tpl('amap/subscriptionspayments.mtt')
	// function doPayments( ?member : db.User ) {

	// 	if ( member==null ) {			
	// 		app.breadcrumb = [ { id : 'account', name : 'Mon compte', link : '/account' }, { id : 'account', name : 'Mon compte', link : '/account' } ];
	// 		member = app.user;
	// 	} else {
	// 		app.breadcrumb = [ { id : 'member', name : 'Membres', link : '/member' }, { id : 'member', name : 'Membres', link : '/member' } ];
	// 	}

	// 	var group = app.getCurrentGroup();

	// 	if(member!=null && !app.user.canAccessMembership()){
	// 		throw Error("/","Accès interdit");
	// 	}
	
	// 	var subscriptionsByCatalog = service.SubscriptionService.getActiveSubscriptionsByCatalog( member, group );
	// 	var operationsBySubscription = new Map<db.Subscription,Array<db.Operation>>();
	// 	for ( catalog in subscriptionsByCatalog.keys() ) {

	// 		for ( subscription in subscriptionsByCatalog[catalog] ) {

	// 			if ( operationsBySubscription[subscription] == null ) {
	// 				operationsBySubscription[subscription] = [];
	// 			}

	// 			var operations = db.Operation.manager.search( $user == member && $subscription == subscription, { orderBy : -date }, false ).array();
	// 			operationsBySubscription[subscription] = operationsBySubscription[subscription].concat( operations );
	// 		}
	// 	}

	// 	var activeSubscriptions = service.SubscriptionService.getActiveSubscriptions( member, group );
	// 	activeSubscriptions.sort( function( b, a ) {
	// 		return  (a.getPaymentsTotal() - a.getTotalPrice()) < (b.getPaymentsTotal() - b.getTotalPrice()) ? 1 : -1;
	// 	} );

		
	// 	PaymentService.updateUserBalance(member,group);

	// 	var ug = db.UserGroup.get( member, group );
	// 	view.globalbalance = ug.balance;
	// 	view.member = member;
	// 	view.subscriptions = activeSubscriptions;
	// 	view.operationsBySubscription = operationsBySubscription;
		
	// 	checkToken();
	// }
	
}