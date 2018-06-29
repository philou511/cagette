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
	
	/**
	 * 
	 */
	override function setup(){		
		TestSuite.initDB();
		TestSuite.initDatas();
	}
	
	function testValidateDistribution() {

		//Take a contract with payments enabled
		//Take 2 users and make orders for each
		var distrib = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var contract = distrib.contract;
		var product = TestSuite.COURGETTES;
		var francoisOrder = db.UserContract.make(TestSuite.FRANCOIS, 1, product, distrib.id);
		var francoisOrderOperation = db.Operation.onOrderConfirm([francoisOrder]);
		var sebOrder = db.UserContract.make(TestSuite.SEB, 3, product, distrib.id);
		var sebOrderOperation = db.Operation.onOrderConfirm([sebOrder]);
		//They both pay by check
		var francoisPayment = db.Operation.makePaymentOperation(TestSuite.FRANCOIS,contract.amap, payment.Check.TYPE, product.price, "Payment by check", francoisOrderOperation[0]);
		var sebPayment = db.Operation.makePaymentOperation(TestSuite.SEB,contract.amap, payment.Check.TYPE, 3 * product.price, "Payment by check", sebOrderOperation[0] );	

		//Autovalidate this old distrib and check that all the payments are validated
		service.PaymentService.validateDistribution(distrib);

		assertTrue(contract.amap.hasPayments());
		assertEquals(distrib.validated, true);
		assertEquals(francoisOrder.paid, true);
		assertEquals(sebOrder.paid, true);

		var francoisOperation = db.Operation.findVOrderTransactionFor(francoisOrder.distribution.getKey(), TestSuite.FRANCOIS, contract.amap, false);
		var sebOperation = db.Operation.findVOrderTransactionFor(sebOrder.distribution.getKey(), TestSuite.SEB, contract.amap, false);
		assertEquals(francoisOperation.pending, false);
		assertEquals(sebOperation.pending, false);

		assertEquals(francoisPayment.pending, false);
		assertEquals(sebPayment.pending, false);
	
	}

}