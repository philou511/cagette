package controller.api;
import haxe.Json;
import tink.core.Error;
import service.OrderService;
import Common;

/**
 * Public order API
 */
class Order extends Controller
{
	public function doCatalogs( multiDistrib : db.MultiDistrib, ?args : { catalogType : Int } ) {

		var catalogs = new Array<ContractInfo>();
		var type = ( args != null && args.catalogType != null ) ? args.catalogType : null;
		for( distrib in multiDistrib.getDistributions(type) ) {
			
			var image = distrib.catalog.vendor.image == null ? null : view.file( distrib.catalog.vendor.image );
			catalogs.push( { id : distrib.catalog.id, name : distrib.catalog.name, image : image } );
		}

		Sys.print( Json.stringify({ success : true, catalogs : catalogs }) );

	}

	function checkRights(user:db.User,catalog:db.Catalog,multiDistrib:db.MultiDistrib){

		if( catalog==null && multiDistrib==null ) throw new Error("You should provide at least a catalog or a multiDistrib");
		if( catalog!=null && catalog.type==db.Catalog.TYPE_CONSTORDERS && multiDistrib!=null ) throw new Error("You cant edit a CSA catalog for a multiDistrib");
		
		//rights	
		if (catalog==null && !app.user.canManageAllContracts()) throw new Error(403,t._("Forbidden access"));
		if (catalog!=null && !app.user.canManageContract(catalog)) throw new Error(403,t._("You do not have the authorization to manage this catalog"));
		if ( multiDistrib != null && multiDistrib.isValidated() ) throw new Error(t._("This delivery has been already validated"));
	}

	/**
		Get orders of a user for a multidistrib.
		Possible to filter for a distribution only
		(Used by OrderBox react component)

		catalog arg : we want to edit the orders of one single catalog/contract
		multiDistrib arg : we want to edit the orders of the whole distribution
	 */	
	public function doGet( user : db.User, args : { ?catalog : db.Catalog, ?multiDistrib : db.MultiDistrib } ) {

		checkIsLogged();
		var catalog = ( args != null && args.catalog != null ) ? args.catalog : null;
		var multiDistrib = ( args != null && args.multiDistrib != null ) ? args.multiDistrib : null;

		checkRights( user, catalog, multiDistrib );

		if ( catalog != null && catalog.type == db.Catalog.TYPE_CONSTORDERS ) {

			//The user needs a subscription for this catalog to have orders
			var subscription = db.Subscription.manager.select( $user == user && $catalog == catalog, false );
			if ( subscription == null ) {
				
				throw new Error( "Il n\'y a pas de souscription à ce nom. Il faut d\'abord créer une souscription pour cette personne pour pouvoir ajouter des commandes."  );
			}
		}

		//get datas
		var orders =[];

		if(catalog==null){
			//we edit a whole multidistrib, edit only var orders.
			orders = multiDistrib.getUserOrders(user , db.Catalog.TYPE_VARORDER);
		}else{
			//edit a single catalog, may be CSA or variable
			var d = null;
			if(multiDistrib!=null){
				d = multiDistrib.getDistributionForContract(catalog);
			}
			orders = catalog.getUserOrders(user, d, false);			
		}

		var orders = OrderService.prepare(orders);		
		Sys.print( tink.Json.stringify({success:true,orders:orders}) );
	}
	
	/**
	 * Update orders of a user ( from react OrderBox component )
	 * @param	userId
	 */
	public function doUpdate( user : db.User, args : { ?catalog : db.Catalog, ?multiDistrib : db.MultiDistrib } ) {

		checkIsLogged();
		var catalog = ( args != null && args.catalog != null ) ? args.catalog : null;
		var multiDistrib = ( args != null && args.multiDistrib != null ) ? args.multiDistrib : null;
		checkRights( user, catalog, multiDistrib );
		
		//POST payload
		var ordersData = new Array< { id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int } >();
		var raw = StringTools.urlDecode( sugoi.Web.getPostData() );
		
		if( raw == null ) {

			throw new Error( 'Order datas are null' );
		}
		else {

			ordersData = haxe.Json.parse(raw).orders;
		}
		
		// Save orders
		// --------------------
		// Find existing orders
		var existingOrders = [];
		if ( catalog == null ) {

			// Edit a whole multidistrib
			existingOrders = multiDistrib.getUserOrders( user );
		}
		else {

			// Edit a single catalog
			var distrib = null;
			if( multiDistrib != null ) {

				distrib = multiDistrib.getDistributionForContract( catalog );
			}
			existingOrders = catalog.getUserOrders( user, distrib );			
		}
				
		var orders = [];
		for ( order in ordersData ) {
			
			// Get product
			var product = db.Product.manager.get( order.productId, false );
			
			// Find existing order				
			var existingOrder = Lambda.find( existingOrders, function(x) return x.id == order.id );
				
			// User2 + Invert
			var user2 : db.User = null;
			var invert = false;
			if ( order.userId2 != null ) {

				user2 = db.User.manager.get( order.userId2, false );
				if ( user2 == null ) throw t._( "Unable to find user #::num::", { num : order.userId2 } );
				if ( !user2.isMemberOf( product.catalog.group ) ) throw t._( "::user:: is not part of this group", { user : user2 } );
				if ( user.id == user2.id ) throw t._( "Both selected accounts must be different ones" );
				
				invert = order.invertSharedOrder;
			}
			
			// Save order
			if ( existingOrder != null ) {

				// Edit existing order
				var updatedOrder = OrderService.edit( existingOrder, order.qt, order.paid , user2, invert );
				if ( updatedOrder != null ) orders.push( updatedOrder );
			}
			else {

				// Insert new order
				var distrib = null; //no need if csa catalog
				if( multiDistrib != null ) {  //RAJOUTER CONDITION VARORDERS

					distrib = multiDistrib.getDistributionFromProduct( product );
					var newOrder =  OrderService.make( user, order.qt , product, distrib == null ? null : distrib.id, order.paid , user2, invert );
					if ( newOrder != null ) orders.push( newOrder );
				}
				else {
					
					// Faire une loop sur les distributions pour créer une order par distribution

					var subscription = db.Subscription.manager.select( $user == user && $catalog == catalog, false );
					if ( subscription == null ) {
						
						throw new Error( "Il n\'y a pas de souscription à ce nom. Il faut d\'abord créer une souscription pour cette personne pour pouvoir ajouter des commandes."  );
					}

					var distributions = db.Distribution.manager.search( $catalog == catalog && $date >= subscription.startDate && $end <= subscription.endDate );

					for ( distrib in distributions ) {

						var newOrder =  OrderService.make( user, order.qt , product,  distrib.id, order.paid , user2, invert, subscription );
						if ( newOrder != null ) orders.push( newOrder );
					}
					
>>>>>>> WIP Subscriptions
				}
				
			}

		}
		
		app.event( MakeOrder( orders ) );
		db.Operation.onOrderConfirm( orders );
		
		Sys.print( Json.stringify( { success : true, orders : ordersData } ) );
	}


	
	
}