package test;
import Common;
/**
 * Test order reports
 * 
 * @author fbarbut
 */
class TestReports extends haxe.unit.TestCase
{
	
	public function new(){
			
		super();
	}
	
	/**
	 * run once at the beginning
	 */
	override function setup(){
		
		sys.db.Manager.cnx.request("TRUNCATE TABLE UserContract;");
		
		var bubar = db.User.manager.get(1);
		var seb = db.User.manager.get(2);
		
		//fruits from group 1
		var fraises = db.Product.manager.get(2);
		fraises.stock = 30;
		var pommes = db.Product.manager.get(3);
		var distrib = fraises.contract.getDistribs().first();
		
		db.UserContract.make(bubar, 4, fraises, distrib.id);
		db.UserContract.make(seb, 2, pommes, distrib.id);
		
		//vegetables from group 2
		var courgettes = db.Product.manager.get(4);
		var carottes = db.Product.manager.get(5);
		var distrib = courgettes.contract.getDistribs().first();
		
		db.UserContract.make(bubar, 1, carottes ,distrib.id);
		db.UserContract.make(seb, 5, courgettes ,distrib.id);
		
		
	}
	

	/**
	 * test a simple report with just a time frame
	 */
	public function testTimeFrameReport(){
		
		var fraises = db.Product.manager.get(2);
		var pommes = db.Product.manager.get(3);
		var courgettes = db.Product.manager.get(4);
		var carottes = db.Product.manager.get(5);
		
		//check we got the right products
		assertEquals("Fraises",fraises.name);
		assertEquals("Pommes",pommes.name);
		assertEquals("Courgettes",courgettes.name);
		assertEquals("Carottes", carottes.name);
		
		var options = { startDate:new Date(2017, 5, 1, 0, 0, 0), endDate:new Date(2017, 5, 31, 0, 0, 0), groups:[], contracts:[] };
		
		var rep = new pro.OrderReport(options);
		
		var data = rep.byProduct();
		
		assertEquals(4,data.length); //should be the 4 products
		
		for ( d in data){
			switch(d.pname){
				case "Fraises": assertEquals(d.qt, 4);
				case "Pommes": assertEquals(d.qt, 2);
				case "Carottes": assertEquals(d.qt, 1);
				case "Courgettes": assertEquals(d.qt, 5);			
			}
		}
		
	}
	
	
	/**
	 * test a report with time frame + group
	 */
	public function testGroupReport(){
		
		var options = { startDate:new Date(2017, 5, 1, 0, 0, 0), endDate:new Date(2017, 5, 31, 0, 0, 0), groups:[1], contracts:[] };
		
		var rep = new pro.OrderReport(options);
		
		var data = rep.byProduct();
		
		assertEquals(2,data.length); //should be the 2 products
		
		for ( d in data){
			switch(d.pname){
				case "Fraises": assertEquals(d.qt, 4);
				case "Pommes": assertEquals(d.qt, 2);				
			}
		}
		
		
	}
	
	
	
}