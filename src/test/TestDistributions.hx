package test;

/**
 * Test distribution creation
 * 
 * @author web-wizard
 */
class TestDistributions extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	
	/**
	 * 
	 */
	override function setup(){		
	}
	
	/**
	 * Check that we can add a distribution outside existing time range for a specific contract and place
	 * Check that we can't add a distribution overlapping with existing distribution for a specific contract and place
	 */
	function testUnicity(){        
    	var existingDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		var newDistrib = new db.Distribution();
		newDistrib.date = new Date(2018, 5, 1, 18, 0, 0);
		newDistrib.end = new Date(2018, 5, 1, 18, 30, 0);
		newDistrib.contract = existingDistrib.contract;
		newDistrib.place = existingDistrib.place;
		var e = null;
		try{
			service.DistributionService.checkDistrib(newDistrib);
		}
		catch(x:String){
			e = x;
		}
		assertEquals(null,e);
	}

}