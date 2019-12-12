package test;
import Common;
import service.DistributionService;
import service.OrderService;
import service.SubscriptionService;

/**
 * Test subscriptions
 * 
 * @author web-wizard
 */
class TestSubscriptions extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	
	var catalog : db.Catalog;
	var micheline : db.User;
	var botteOignons : db.Product;
	var panierAmap : db.Product;
	
	/**
	 * get a contract + a user + a product + empty orders
	 */
	override function setup(){

		TestSuite.initDB();
		TestSuite.initDatas();

		catalog = TestSuite.CONTRAT_AMAP;

		botteOignons = TestSuite.BOTTE_AMAP;
		panierAmap = TestSuite.PANIER_AMAP_LEGUMES;

		micheline = db.User.manager.get(1);

	}

	/**
	Test Get subscription orders
	**/
	public function testSubscriptionOrders() {

		var subscription = new db.Subscription();
		subscription.user = micheline;
		subscription.catalog = catalog;
		subscription.startDate = catalog.startDate;
		subscription.endDate = catalog.endDate;
		subscription.insert();

		var distributions = db.Distribution.manager.search( $catalog == catalog && $date >= subscription.startDate && $end <= subscription.endDate );
		for ( distrib in distributions ) {

			OrderService.make( micheline, 3 , botteOignons,  distrib.id, false , null, false, subscription );
			OrderService.make( micheline, 2 , panierAmap,  distrib.id, false , null, false, subscription );
		}

		var subscriptionOrders = SubscriptionService.getSubscriptionOrders( subscription );

		assertEquals( subscriptionOrders.length, 2 );
		var order1 = Lambda.array( subscriptionOrders )[0];
		var order2 = Lambda.array( subscriptionOrders )[1];
		assertEquals( order1.product.id, botteOignons.id );
		assertEquals( order1.quantity, 3 );
		assertEquals( order2.product.id, panierAmap.id );
		assertEquals( order2.quantity, 2 );

	}


	public function testDeleteSubscription() {

		DistributionService.create( catalog, new Date(2030, 5, 1, 19, 0, 0), new Date(2030, 5, 1, 20, 0, 0), TestSuite.PLACE_DU_VILLAGE.id, new Date(2030, 4, 1, 20, 0, 0), new Date(2030, 4, 30, 20, 0, 0) );
		DistributionService.create( catalog, new Date(2030, 6, 1, 19, 0, 0), new Date(2030, 6, 1, 20, 0, 0), TestSuite.PLACE_DU_VILLAGE.id, new Date(2030, 5, 1, 20, 0, 0), new Date(2030, 5, 30, 20, 0, 0) );

		//-----------------------------------------------
		//Test case : There are orders for past distribs
		//-----------------------------------------------
		var subscription = new db.Subscription();
		subscription.user = micheline;
		subscription.catalog = catalog;
		subscription.startDate = catalog.startDate;
		subscription.endDate = catalog.endDate;
		subscription.insert();

		var distributions = db.Distribution.manager.search( $catalog == catalog && $date >= subscription.startDate && $date <= subscription.endDate );
		for ( distrib in distributions ) {

			OrderService.make( micheline, 3 , botteOignons,  distrib.id, false , null, false, subscription );
			OrderService.make( micheline, 2 , panierAmap,  distrib.id, false , null, false, subscription );
		}

		
		assertEquals( SubscriptionService.getSubscriptionOrders( subscription ).length, 2 );

		//Check : When trying to delete the subscription there should be an error because there are orders for past distributions
		var error1 = null;
		try {
			
			SubscriptionService.deleteSubscription( subscription );
		}
	    catch( e : tink.core.Error ) {

			error1 = e;
		}
		assertEquals( error1.data, PastOrders );
		assertEquals( SubscriptionService.getSubscriptionOrders( subscription ).length, 2 );

		//Test case : There are no past distribs
		//---------------------------------------
		subscription.lock();
		subscription.startDate = Date.now();
		subscription.update();

		assertEquals( SubscriptionService.getSubscriptionOrders( subscription ).length, 2 );

		//Check : I can delete this subscription because thete are no orders for past distributions
		var error2 = null;
		var copiedSubscription = subscription;
		try {
			
			SubscriptionService.deleteSubscription( subscription );
		}
	    catch( e : tink.core.Error ) {

			error2 = e;
		}
		assertEquals( error2, null );
		assertEquals( SubscriptionService.getSubscriptionOrders( copiedSubscription ).length, 0 );

	}
	

}