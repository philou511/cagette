package test;

/**
 * Test payments
 * 
 * @author web-wizard
 */
class TestPayments extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	
	override function setup(){		
		TestSuite.initDB();
		TestSuite.initDatas();
		db.Basket.emptyCache();
	}
	
	function testValidateDistribution() {

		//Take a contract with payments enabled
		//Take 2 users and make orders for each
		var distrib = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var contract = distrib.contract;
		var product = TestSuite.COURGETTES;
		var francoisOrder = service.OrderService.make(TestSuite.FRANCOIS, 1, product, distrib.id);
		var francoisOrderOperation = db.Operation.onOrderConfirm([francoisOrder]);
		var sebOrder = service.OrderService.make(TestSuite.SEB, 3, product, distrib.id);
		var sebOrderOperation = db.Operation.onOrderConfirm([sebOrder]);
		//They both pay by check
		var francoisPayment = db.Operation.makePaymentOperation(TestSuite.FRANCOIS,contract.amap, payment.Check.TYPE, product.price, "Payment by check", francoisOrderOperation[0]);
		var sebPayment      = db.Operation.makePaymentOperation(TestSuite.SEB,contract.amap, payment.Check.TYPE, 3 * product.price, "Payment by check", sebOrderOperation[0] );	

		//Autovalidate this old distrib and check that all the payments are validated
		service.PaymentService.validateDistribution(distrib);
		
		//distrib should be validated
		assertTrue(contract.amap.hasPayments());
		assertEquals(true, distrib.validated);
		
		//orders should be marked as paid
		assertEquals(true, francoisOrder.paid);
		assertEquals(true, sebOrder.paid);

		//order operation is not pending
		var francoisOperation = db.Operation.findVOrderOperation(francoisOrder.distribution.multiDistrib, TestSuite.FRANCOIS, false);
		var sebOperation 	  = db.Operation.findVOrderOperation(sebOrder.distribution.multiDistrib, TestSuite.SEB, false);		
		assertEquals(francoisOperation.pending, false);
		assertEquals(sebOperation.pending, false);

		//payment operation is not pending
		assertEquals(francoisPayment.pending, false);
		assertEquals(sebPayment.pending, false);

		//basket are validated 
		var b = db.Basket.get(TestSuite.SEB,distrib.multiDistrib);
		assertEquals(true, b.isValidated());
		var b = db.Basket.get(TestSuite.FRANCOIS,distrib.multiDistrib);
		assertEquals(true, b.isValidated());
	}

	function testMakeOnTheSpotPaymentOperations()
	{
		//Take a contract with payments enabled
		//Make 2 orders
		var distrib = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var contract = distrib.contract;
		var product1 = TestSuite.COURGETTES;
		var julieOrder1 = service.OrderService.make(TestSuite.JULIE, 1, product1, distrib.id);
		var julieOrderOperation1 = db.Operation.onOrderConfirm([julieOrder1]);
		
		//Payment on the spot
		var juliePayment1 = db.Operation.makePaymentOperation(TestSuite.JULIE,contract.amap, payment.OnTheSpotPayment.TYPE, product1.price, "Payment on the spot", julieOrderOperation1[0]);

		var product2 = TestSuite.CARROTS;
		var julieOrder2 = service.OrderService.make(TestSuite.JULIE, 1, product2, distrib.id);
		var julieOrderOperation2 = db.Operation.onOrderConfirm([julieOrder2]);
		
		//Payment on the spot
		var juliePayment2 = db.Operation.makePaymentOperation(TestSuite.JULIE,contract.amap, payment.OnTheSpotPayment.TYPE, product2.price, "Payment on the spot", julieOrderOperation2[0]);

		//Check that the second payment is just an update of the first one
		assertEquals(juliePayment1.id, juliePayment2.id);
	}

}