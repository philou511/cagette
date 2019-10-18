package test;
import Common;
import service.OrderService;
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
	
	var c : db.Catalog;
	var p : db.Product;
	var bob : db.User;
	
	/**
	 * get a contract + a user + a product + empty orders
	 */
	override function setup(){

		TestSuite.initDB();
		TestSuite.initDatas();
		
		db.Basket.emptyCache();

		c = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.contract;

		p = TestSuite.STRAWBERRIES;
		p.lock();
		p.stock = 8;
		p.update();
		
		bob = db.User.manager.get(1);

	}

	/**
	Test Basket creation and numbering
	**/
	public function testBasket(){

		var d = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;

		var o = OrderService.make(TestSuite.FRANCOIS, 3, TestSuite.STRAWBERRIES, d.id);
		assertEquals(1, o.basket.num);

		var o = OrderService.make(TestSuite.SEB, 1, TestSuite.STRAWBERRIES, d.id);
		assertEquals(2, o.basket.num);

		//order again, should keep existing basket number
		var o = OrderService.make(TestSuite.FRANCOIS, 1, TestSuite.APPLES, d.id);
		assertEquals(1, o.basket.num);

		//check bug of 2018-07 : changing the date and place of the distribution leads to lost basket (because basket were indexed on user-date-place)
		/*d.lock();
		d.date = new Date(2028,1,1,0,0,0);

		var place = new db.Place();
		place.name = "Chez Momo";
		place.zipCode = "54";
		place.amap = d.contract.amap;
		place.insert();

		d.place = place;
		d.update();*/
		

		//Seb's basket is still 2
		var basket = db.Basket.get(TestSuite.SEB,d.multiDistrib);
		assertEquals(2, basket.num);

		var o = OrderService.make(TestSuite.SEB, 1, TestSuite.APPLES, d.id);
		assertEquals(2, o.basket.num);

		var o2 = OrderService.edit(o,5,true,null,false);
  		assertEquals(2, o2.basket.num);

		//order to a different distrib in same contract should start a new numbering
		var d2 = service.DistributionService.create(d.contract,new Date(2026,6,6,0,0,0),new Date(2026,6,6,1,0,0),TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.place.id,new Date(2026,6,4,0,0,0),new Date(2026,6,5,0,0,0));
		var o = OrderService.make(TestSuite.SEB, 12, TestSuite.APPLES, d2.id);
		assertEquals(1, o.basket.num);

	}

	/**
	 * make orders & stock management
	 */
	public function testStocks(){
		
		var stock = p.stock;
		
		assertTrue(c.type == db.Catalog.TYPE_VARORDER);
		assertTrue(c.flags.has(db.Catalog.ContractFlags.StockManagement));
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
		var o = OrderService.make(bob, 3, p, TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.id);
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
		var o = OrderService.make(bob, 6, p, TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.id);
		assertTrue(p.stock == 0);
		assertTrue(o.quantity == 8);
		
		//bob orders again but cant order anything
		var o = OrderService.make(bob, 3, p, TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.id);
		assertTrue(p.stock == 0);
		assertTrue(o.quantity == 8);
		
	}
	
	/**
	 * test edit orders and stock management
	 */
	function testOrderEdit(){

		var o = db.UserOrder.manager.select( $user == bob && $product == p, true);	
		
		//no order, stock at 8
		assertEquals(p.stock , 8);
		assertEquals(o , null);
		
		//bob orders 3 strawberries
		var o = OrderService.make(bob, 3, p , TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE.id);		
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
		var o = OrderService.edit(o, 6);
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
		var o = OrderService.edit(o, 9);
		assertEquals(0.0 , p.stock);
		assertEquals(8.0 , o.quantity);
		
		//order more, but stock at 0
		var o = OrderService.edit(o, 12);
		assertEquals(0.0 , p.stock);
		assertEquals(8.0 , o.quantity);
		
		//order less
		var o = OrderService.edit(o, 6);
		assertEquals(2.0 , p.stock);
		assertEquals(6.0 , o.quantity);


		//floatQt : ordering float quantities should throw an exception
		var err = null;
		try{
			var o = OrderService.edit(o, 6.4);
		}catch(e:tink.core.Error){
			err = e.message;
		}
		assertTrue( err!=null );
	}
	
	/**
	 * test orders with multiweight product
	 */
	function testOrderWithMultiWeightProduct(){
		
		var POTATOES = TestSuite.POTATOES;
		var distrib = db.Distribution.manager.select($contract == POTATOES.contract, false);
		
		var order = OrderService.make(bob, 1, POTATOES, distrib.id);
		assertEquals(1.0, order.quantity);
		assertEquals(POTATOES.id, order.product.id);
		assertEquals(POTATOES.price, order.productPrice);
		
		//order 2 more, should not aggregate because multiWeight is true
		var order2 = OrderService.make(bob, 2, POTATOES, distrib.id);
		
		assertTrue(order2.id != order.id); 
		
		//we should get 3 different orders
		var orders = distrib.getOrders();
		
		//trace(OrderService.prepare(orders));
		
		assertEquals(3, orders.length);
		for ( o in orders){
			assertEquals(o.user.id, bob.id);
			assertEquals(o.product.id, POTATOES.id);
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
		
		var order = OrderService.make(bob, 1, fraises, distrib.id);
		
		order = OrderService.edit(order, 0);
		
		assertEquals(0.0, order.quantity);
		
		var order2 = OrderService.make(bob, 1, fraises, distrib.id);
		
		var bobOrders = [];
		for ( o in distrib.getOrders()) if (o.user.id == bob.id) bobOrders.push(o);
		
		assertFalse(fraises.multiWeight);
		assertEquals(1, bobOrders.length);
		assertEquals(1.0, bobOrders[0].quantity);
	}

	/**
	 *  Test order deletion and operation deletion in various contexts
	 	@author jbarbic
	 */
	function testDelete(){

		var t = sugoi.i18n.Locale.texts;

		//[Test case] Should throw an error when trying to delete order and that the quantity is not zero
		var amapDistrib = TestSuite.DISTRIB_CONTRAT_AMAP;
		var amapContract = amapDistrib.contract;
		var order = OrderService.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
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
		assertTrue(db.UserOrder.manager.get(orderId) != null);
		
		//[Test case] Amap contract and quantity zero with payments disabled
		//Check that order is deleted
		order = OrderService.edit(order, 0);
		var e2 = null;
		try {
			OrderService.delete(order);
		}
	    catch(x:tink.core.Error){
			e2 = x;
		}
		assertEquals(e2, null);
		assertEquals(db.UserOrder.manager.get(orderId), null);

		//[Test case] Amap contract and quantity zero with payments enabled and 2 orders
		//Check that first order is deleted but operation amount is at 0 
		//Check that operation is deleted only at the second order deletion
		var order1 = OrderService.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		order1 = OrderService.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);
		var order2 = OrderService.make(TestSuite.FRANCOIS, 1, TestSuite.PANIER_AMAP_LEGUMES, amapDistrib.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		order2 = OrderService.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);
		var operation = db.Operation.findCOrderOperation(amapContract, TestSuite.FRANCOIS);
		var operationId = operation.id;
		var e3 = null;
		try {
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e3 = x;
		}
		assertEquals(e3, null);
		assertEquals(db.UserOrder.manager.get(order1Id), null);
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
		assertEquals(null, e4);
		assertEquals(null, db.UserOrder.manager.get(order2Id));
		assertEquals(null, db.Operation.manager.get(operationId));

		//[Test case] Var Order contract and quantity zero with payments disabled
		//Check that order is deleted
		var variableDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;

		var g = variableDistrib.contract.amap;		
		g.lock();
		g.flags.unset(HasPayments);
		g.update();
		
		var order = OrderService.make(TestSuite.FRANCOIS, 2, TestSuite.STRAWBERRIES, variableDistrib.id);
		var orderId = order.id;
		db.Operation.onOrderConfirm([order]);
		order = OrderService.edit(order, 0);
		db.Operation.onOrderConfirm([order]);
		var e1 = null;
		try {
			service.OrderService.delete(order);
		}
	    catch(x:tink.core.Error){
			e1 = x;
		}
		assertEquals(false,variableDistrib.contract.amap.hasPayments() );
		assertEquals(null, e1);
		assertEquals(null, db.UserOrder.manager.get(orderId));

		//[Test case] Var Order contract and quantity zero with payments enabled and 2 orders
		//Check that first order is deleted
		//Check that operation is deleted only at the second order deletion
		variableDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		var variableContract = variableDistrib.contract;
		var g = variableDistrib.contract.amap;		
		g.lock();
		g.flags.set(HasPayments);
		g.update();
		assertTrue(variableContract.amap.hasPayments());

		var order1 = OrderService.make(TestSuite.FRANCOIS, 2, TestSuite.STRAWBERRIES, variableDistrib.id);
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		
		var order2 = OrderService.make(TestSuite.FRANCOIS, 3, TestSuite.APPLES, variableDistrib.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		
		order1 = OrderService.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);
		
		order2 = OrderService.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);

		assertEquals(2, variableContract.getUserOrders(TestSuite.FRANCOIS,variableDistrib).length); //François has 2 orders
		var basket = db.Basket.get(TestSuite.FRANCOIS,variableDistrib.multiDistrib);
		assertEquals(2, basket.getOrders().length);

		var operation1 = db.Operation.findVOrderOperation(order1.distribution.multiDistrib, TestSuite.FRANCOIS);
		var operation1Id = operation1.id;
		var operation2 = db.Operation.findVOrderOperation(order2.distribution.multiDistrib, TestSuite.FRANCOIS);
		var operation2Id = operation2.id;
		assertEquals(operation1Id,operation2Id);
		var e2 = null;
		try {
			//delete strawberries order
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e2 = x;
		}
		assertEquals(null, e2);
		assertEquals(null, db.UserOrder.manager.get(order1Id) ); //order 1 is deleted
		assertTrue( db.Operation.manager.get(operation1Id) != null); //operation should be here
		assertEquals(0.0,operation1.amount);
		assertEquals(1 , basket.getOrders().length);
		var e3 = null;
		try {
			//delete apple order
			service.OrderService.delete(order2);
		}
	    catch(x:tink.core.Error){
			e3 = x;
		}
		assertEquals(null, e3);
		assertEquals(null, db.UserOrder.manager.get(order2Id)); //order 2 is deleted
		assertEquals(null, db.Operation.manager.get(operation1Id)); //operation should be deleted
		assertEquals(0 , basket.getOrders().length);

		//[Test case] 2 VarOrderContracts and quantity zero with payments enabled and 1 order each
		//Check that first order is deleted but operation amount is at 0
		//Check that operation is deleted only at the second order deletion
		var variableDistrib1 = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var order1 = OrderService.make(TestSuite.FRANCOIS, 2, TestSuite.COURGETTES, variableDistrib1.id);
		assertTrue(order1.basket!=null);
		// trace("WE GOT A BASKET "+order1.basket.id);
		// trace("... THEN RE-GET BASKET  user "+TestSuite.FRANCOIS.id+" place "+variableDistrib1.place.id+" date "+variableDistrib1.date);
		var basket = db.Basket.get(TestSuite.FRANCOIS,variableDistrib1.multiDistrib);
		assertTrue(basket!=null);
		assertEquals(1, basket.getOrders().length);
		db.Operation.onOrderConfirm([order1]);
		var order1Id = order1.id;
		
		var variableDistrib2 = TestSuite.DISTRIB_PATISSERIES;
		var order2 = OrderService.make(TestSuite.FRANCOIS, 3, TestSuite.FLAN, variableDistrib2.id);
		db.Operation.onOrderConfirm([order2]);
		var order2Id = order2.id;
		
		order1 = OrderService.edit(order1, 0);
		db.Operation.onOrderConfirm([order1]);

		order2 = OrderService.edit(order2, 0);
		db.Operation.onOrderConfirm([order2]);

		//check basket
		var basket = db.Basket.get(TestSuite.FRANCOIS,variableDistrib1.multiDistrib);
		assertEquals(2, basket.getOrders().length);

		var operation = db.Operation.findVOrderOperation(order1.distribution.multiDistrib, TestSuite.FRANCOIS);
		var operationId = operation.id;


		var e4 = null;
		try {
			service.OrderService.delete(order1);
		}
	    catch(x:tink.core.Error){
			e4 = x;
		}
		assertEquals(e4, null);
		assertEquals(db.UserOrder.manager.get(order1Id), null);
		assertTrue(db.Operation.manager.get(operationId) != null);	//op should still be here
		assertEquals(0.0,operation.amount);//...with amount 0

		var e5 = null;
		try {
			service.OrderService.delete(order2);
		}
	    catch(x:tink.core.Error){
			e5 = x;
		}
		assertEquals(e5, null);
		assertEquals(db.UserOrder.manager.get(order2Id), null);
		assertEquals(db.Operation.manager.get(operation1Id), null);
		assertEquals(db.Operation.manager.get(operation2Id), null);
	}

	

}