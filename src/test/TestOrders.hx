package test;
import Common;
/**
 * Test order making, updating and deleting
 * 
 * @author fbarbut
 */
class TestOrders extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	
	var c : db.Contract;
	var p : db.Product;
	var bob : db.User;
	
	/**
	 * get a contract + a user + a product + empty orders
	 */
	override function setup(){

		TestSuite.initDB();
		TestSuite.initDatas();

		c = db.Contract.manager.get(2);
		
		p = c.getProducts().first();
		p.lock();
		p.stock = 8;
		p.update();
		
		bob = db.User.manager.get(1);
		
		sys.db.Manager.cnx.request("TRUNCATE TABLE UserContract;");
		//print("setup");
		
	}


	/**
	 * make orders & stock management
	 */
	public function testStocks(){
		
		var stock = p.stock;
		
		assertTrue(c.type == db.Contract.TYPE_VARORDER);
		assertTrue(c.flags.has(db.Contract.ContractFlags.StockManagement));
		assertTrue(stock == 8);
		
		//bob orders 3 strawberries, stock fall to 2
		//order is update to 6 berries
		App.current.eventDispatcher.addOnce(function(e:Event){
			switch(e){
				case StockMove(e):
					assertTrue(e.move==-3);
					assertTrue(e.product==p);
				default:	
			}
		});
		var o = db.UserContract.make(bob, 3, p);
		assertTrue(p.stock == 5);
		assertTrue(o.quantity == 3);
		
		//bob orders 6 more. stock fall to 0, order is reduced to 5
		//quantity is not 9 but 8
		App.current.eventDispatcher.addOnce(function(e:Event){
			switch(e){
				case StockMove(e):
					assertTrue(e.move==-5);
					assertTrue(e.product==p);
				default:	
			}
		});
		var o = db.UserContract.make(bob, 6, p);
		assertTrue(p.stock == 0);
		assertTrue(o.quantity == 8);
		
		//bob orders again but cant order anything
		var o = db.UserContract.make(bob, 3, p);
		assertTrue(p.stock == 0);
		assertTrue(o.quantity == 8);
		
	}
	
	/**
	 * test edit orders and stock management
	 */
	function testOrderEdit(){

		var o = db.UserContract.manager.select( $user == bob && $product == p, true);	
		
		//no order, stock at 8
		assertEquals(p.stock , 8);
		assertEquals(o , null);
		
		//bob orders 3 strawberries
		var o = db.UserContract.make(bob, 3, p);		
		assertEquals(o.product.name, p.name);
		assertEquals(o.quantity, 3);
		assertEquals(p.stock , 5);
		
		//order edit, order 6 berries
		App.current.eventDispatcher.addOnce(function(e:Event){
			switch(e){
				case StockMove(e):
					assertTrue(e.move==-3);
					assertTrue(e.product==p);
				default:	
			}
		});
		var o = db.UserContract.edit(o, 6);
		assertTrue(p.stock == 2);
		assertTrue(o.quantity == 6);
		
		//order edit, order 9 berries. ( 3 more, but stock fall to 0, reduced to 2 )
		App.current.eventDispatcher.addOnce(function(e:Event){
			switch(e){
				case StockMove(e):
					assertEquals( -2.0 , e.move );
					assertEquals( p , e.product);
				default:	
			}
		});
		var o = db.UserContract.edit(o, 9);
		assertEquals(0.0 , p.stock);
		assertEquals(8.0 , o.quantity);
		
		//order more, but stock at 0
		var o = db.UserContract.edit(o, 12);
		assertEquals(0.0 , p.stock);
		assertEquals(8.0 , o.quantity);
		
		//order less
		var o = db.UserContract.edit(o, 6);
		assertEquals(2.0 , p.stock);
		assertEquals(6.0 , o.quantity);
	}
	
	/**
	 * test orders with multiweight product
	 */
	function testOrderWithMultiWeightProduct(){
		
		var chicken = TestSuite.CHICKEN;
		var distrib = db.Distribution.manager.select($contract == chicken.contract, false);
		
		var order = db.UserContract.make(bob, 1, chicken, distrib.id);
		assertEquals(1.0, order.quantity);
		assertEquals(chicken.id, order.product.id);
		assertEquals(chicken.price, order.productPrice);
		
		//order 2 more, should not aggregate because multiWeight is true
		var order2 = db.UserContract.make(bob, 2, chicken, distrib.id);
		
		assertTrue(order2.id != order.id); 
		
		//we should get 3 different orders
		var orders = distrib.getOrders();
		
		//trace(db.UserContract.prepare(orders));
		
		assertEquals(3, orders.length);
		for ( o in orders){
			assertEquals(o.user.id, bob.id);
			assertEquals(o.product.id, chicken.id);
			assertEquals(1.0, o.quantity);
		}
		
	}
	
	/**
	 * @author fbarbut
	 * @date 2018-01-26
	 * order a product, edit and set qt to zero, order again.
	 * the same record should be re-used ( if not multiweight )
	 */
	function testMakeOrderAndZeroQuantity(){
		var fraises = TestSuite.STRAWBERRIES;
		var distrib = db.Distribution.manager.select($contract == fraises.contract, false);
		
		var order = db.UserContract.make(bob, 1, fraises, distrib.id);
		
		order = db.UserContract.edit(order, 0);
		
		assertEquals(0.0, order.quantity);
		
		var order2 = db.UserContract.make(bob, 1, fraises, distrib.id);
		
		var bobOrders = [];
		for ( o in distrib.getOrders()) if (o.user.id == bob.id) bobOrders.push(o);
		
		//trace(db.UserContract.prepare(bobOrders));
		
		assertFalse(fraises.multiWeight);
		assertEquals(1, bobOrders.length);
		assertEquals(1.0, bobOrders[0].quantity);
	}

	/**
	 *  
	 */
	function testDelete(){

		var t = sugoi.i18n.Locale.texts;

		//[Test case] Order quantity non zero
		//Check that it throws error when trying to delete order and that the order is not deleted
		var amapDistrib = TestSuite.DISTRIB_CONTRAT_AMAP;
		var amapContract = amapDistrib.contract;
		var order = db.UserContract.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
		var orderId = order.id;
		db.Operation.onOrderConfirm([order]);
		var e1 = null;
		try {
			service.OrderService.delete(order);
		}
	    catch(x:tink.core.Error){
			e1 = x;
		}
		assertEquals(e1.message, "Deletion not possible: quantity is not zero.");
		assertTrue(db.UserContract.manager.get(orderId) != null);
		
		//[Test case] Amap contract and quantity zero with payments disabled
		//Check that order is deleted
		order = db.UserContract.edit(order, 0);
		var e2 = null;
		try {
			service.OrderService.delete(order);
		}
	    catch(x:tink.core.Error){
			e2 = x;
		}
		assertEquals(e2, null);
		assertEquals(db.UserContract.manager.get(orderId), null);

		//[Test case] Amap contract and quantity zero with payments enabled and 2 orders
		//Check that first order is deleted but operation amount is at 0 
		//Check that operation is deleted only at the second order deletion
		var order1 = db.UserContract.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		order1 = db.UserContract.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);
		var order2 = db.UserContract.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		order2 = db.UserContract.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);
		var operation = db.Operation.findCOrderTransactionFor(amapContract, TestSuite.FRANCOIS);
		var operationId = operation.id;
		var e3 = null;
		try {
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e3 = x;
		}
		assertEquals(e3, null);
		assertEquals(db.UserContract.manager.get(order1Id), null);
		assertTrue(db.Operation.manager.get(operationId) != null);
		assertEquals(operation.name, "Contrat AMAP Légumes (La ferme de la Galinette) 1 deliveries");
		assertEquals(operation.amount, 0);
		var e4 = null;
		try {
			service.OrderService.delete(order2);
		}
	    catch(x:tink.core.Error){
			e4 = x;
		}
		assertEquals(e4, null);
		assertEquals(db.UserContract.manager.get(order2Id), null);
		assertEquals(db.Operation.manager.get(operationId), null);

		//[Test case] Var Order contract and quantity zero with payments disabled
		//Check that order is deleted
		var variableDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		var variableContract = variableDistrib.contract;
		var order = db.UserContract.make(TestSuite.FRANCOIS, 2, TestSuite.STRAWBERRIES, variableDistrib.id);
		var orderId = order.id;
		db.Operation.onOrderConfirm([order]);
		order = db.UserContract.edit(order, 0);
		db.Operation.onOrderConfirm([order]);
		var e1 = null;
		try {
			service.OrderService.delete(order);
		}
	    catch(x:tink.core.Error){
			e1 = x;
		}
		assertEquals(e1, null);
		assertEquals(db.UserContract.manager.get(orderId), null);

		//[Test case] Var Order contract and quantity zero with payments enabled and 2 orders
		//Check that first order is deleted
		//Check that operation is deleted only at the second order deletion
		var order1 = db.UserContract.make(TestSuite.FRANCOIS, 2, TestSuite.STRAWBERRIES, variableDistrib.id);
		assertTrue(variableContract.amap.hasPayments());
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		order1 = db.UserContract.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);
		var order2 = db.UserContract.make(TestSuite.FRANCOIS, 3, TestSuite.STRAWBERRIES, variableDistrib.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		order2 = db.UserContract.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);
		var operation1 = db.Operation.findVOrderTransactionFor(order1.distribution.getKey(), TestSuite.FRANCOIS, variableContract.amap);
		var operation1Id = operation1.id;
		var operation2 = db.Operation.findVOrderTransactionFor(order2.distribution.getKey(), TestSuite.FRANCOIS, variableContract.amap);
		var operation2Id = operation2.id;
		var e2 = null;
		try {
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e2 = x;
		}
		assertEquals(e2, null);
		assertEquals(db.UserContract.manager.get(order1Id), null);
		assertTrue(db.Operation.manager.get(operation1Id) != null);
		assertTrue(db.Operation.manager.get(operation2Id) != null);
		assertEquals(operation1.amount, 0);
		assertEquals(operation2.amount, 0);
		var e3 = null;
		try {
			service.OrderService.delete(order2);
		}
	    catch(x:tink.core.Error){
			e3 = x;
		}
		assertEquals(e3, null);
		assertEquals(db.UserContract.manager.get(order2Id), null);
		assertEquals(db.Operation.manager.get(operation1Id), null);
		assertEquals(db.Operation.manager.get(operation2Id), null);

		//[Test case] 2 Var Order contracts and quantity zero with payments enabled and 1 order each
		//Check that first order is deleted but operation amount is at 0
		//Check that operation is deleted only at the second order deletion
		var variableDistrib1 = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var order1 = db.UserContract.make(TestSuite.FRANCOIS, 2, TestSuite.COURGETTES, variableDistrib1.id);
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		order1 = db.UserContract.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);
		var variableDistrib2 = TestSuite.DISTRIB_PATISSERIES;
		var order2 = db.UserContract.make(TestSuite.FRANCOIS, 3, TestSuite.FLAN, variableDistrib2.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		order2 = db.UserContract.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);
		var operation1 = db.Operation.findVOrderTransactionFor(order1.distribution.getKey(), TestSuite.FRANCOIS, variableDistrib1.contract.amap);
		var operation1Id = operation1.id;
		var operation2 = db.Operation.findVOrderTransactionFor(order2.distribution.getKey(), TestSuite.FRANCOIS, variableDistrib2.contract.amap);
		var operation2Id = operation2.id;
		var e4 = null;
		try {
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e4 = x;
		}
		assertEquals(e4, null);
		assertEquals(db.UserContract.manager.get(order1Id), null);
		assertTrue(db.Operation.manager.get(operation1Id) != null);
		assertTrue(db.Operation.manager.get(operation2Id) != null);
		assertEquals(operation1.amount, 0);
		assertEquals(operation2.amount, 0);
		var e5 = null;
		try {
			service.OrderService.delete(order2);
		}
	    catch(x:tink.core.Error){
			e5 = x;
		}
		assertEquals(e5, null);
		assertEquals(db.UserContract.manager.get(order2Id), null);
		assertEquals(db.Operation.manager.get(operation1Id), null);
		assertEquals(db.Operation.manager.get(operation2Id), null);

	}

	function testVendorOrdersByProduct(){
		// Take 3 vendors
		// Each has their own distrib for one inactive multidistrib
		// Take 3 users
		// Each user makes different purchases in this multidistrib but also for other distribs
		// Check that totals are what we expect by vendor products

		//User 1 buys products for a multidistrib
		var distrib1 = test.TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var distrib2 = test.TestSuite.DISTRIB_LAITUE;
		var distrib3 = test.TestSuite.DISTRIB_CAROTTES;
		var francoisOrder1 = db.UserContract.make(test.TestSuite.FRANCOIS, 1, test.TestSuite.CHICKEN, distrib1.id);
		var francoisOrder2 = db.UserContract.make(test.TestSuite.FRANCOIS, 2, test.TestSuite.LAITUE, distrib2.id);
		var francoisOrderOperation = db.Operation.onOrderConfirm([francoisOrder1, francoisOrder2]);
		//User 2 buys products for a multidistrib
		var sebOrder1 = db.UserContract.make(test.TestSuite.SEB, 3, test.TestSuite.COURGETTES, distrib1.id);
		var sebOrder2 = db.UserContract.make(test.TestSuite.SEB, 7, test.TestSuite.CAROTTES, distrib3.id);
		var sebOrderOperation = db.Operation.onOrderConfirm([sebOrder1, sebOrder2]);
		//User 3 buys products for the same multidistrib
		var julieOrder1 = db.UserContract.make(test.TestSuite.JULIE, 3, test.TestSuite.LAITUE, distrib2.id);
		var julieOrder2 = db.UserContract.make(test.TestSuite.JULIE, 5, test.TestSuite.CAROTTES, distrib3.id);
		var julieOrderOperation = db.Operation.onOrderConfirm([julieOrder1, julieOrder2]);
		//They all pay by credit card
		var francoisPayment = db.Operation.makePaymentOperation(test.TestSuite.FRANCOIS,distrib1.contract.amap, payment.Transfer.TYPE, test.TestSuite.CHICKEN.price + 2 * test.TestSuite.LAITUE.price, "Payment by transfer", francoisOrderOperation[0]);
		var sebPayment = db.Operation.makePaymentOperation(test.TestSuite.SEB,distrib1.contract.amap, payment.Transfer.TYPE, 3 * test.TestSuite.COURGETTES.price + 7 * test.TestSuite.CAROTTES.price, "Payment by transfer", sebOrderOperation[0]);
		var juliePayment = db.Operation.makePaymentOperation(test.TestSuite.JULIE,distrib1.contract.amap, payment.Transfer.TYPE, 3 * test.TestSuite.LAITUE.price + 5 * test.TestSuite.CAROTTES.price, "Payment by transfer", julieOrderOperation[0]);
		//Get all the repartition
		var vendorDataByVendorId = service.OrderService.getMultiDistribVendorOrdersByProduct(distrib1.date, distrib1.place);
    
		//Check this is what we expect for each vendor
		assertEquals(vendorDataByVendorId.get(test.TestSuite.VENDOR1.id).orders[0].total, 3 * test.TestSuite.COURGETTES.price);
		assertEquals(vendorDataByVendorId.get(test.TestSuite.VENDOR1.id).orders[1].total, 1 * test.TestSuite.CHICKEN.price);
		assertEquals(vendorDataByVendorId.get(test.TestSuite.VENDOR2.id).orders[0].total, 5 * test.TestSuite.LAITUE.price);
		assertEquals(vendorDataByVendorId.get(test.TestSuite.VENDOR3.id).orders[0].total, 12 * test.TestSuite.CAROTTES.price);
		
	}

}