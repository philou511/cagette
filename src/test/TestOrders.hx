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
		
		c = db.Contract.manager.get(2);
		
		p = c.getProducts().first();
		p.lock();
		p.stock = 8;
		p.update();
		
		bob = db.User.manager.get(1);
		
		sys.db.Manager.cnx.request("TRUNCATE TABLE UserContract;");
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
		var o = db.UserContract.make(bob, 3, p);//return null		
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
	
}