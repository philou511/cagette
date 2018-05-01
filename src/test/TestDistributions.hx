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
		var distrib1 = new db.Distribution();
		distrib1.date = new Date(2018, 5, 1, 18, 0, 0);
		distrib1.end = new Date(2018, 5, 1, 18, 30, 0);
		distrib1.orderStartDate = new Date(2018, 4, 1, 18, 0, 0);
		distrib1.orderEndDate = new Date(2018, 4, 30, 18, 30, 0);
		distrib1.contract = existingDistrib.contract;
		distrib1.place = existingDistrib.place;
		var e1 = null;
		try{
			service.DistributionService.checkDistrib(distrib1);
		}
		catch(x:String){
			e1 = x;
		}
		assertEquals(e1, null);

		//existingDistrib.date <= distrib2.date && existingDistrib.end >= distrib2.date
		var distrib2 = new db.Distribution();
		distrib2.date = new Date(2017, 5, 1, 19, 30, 0);
		distrib2.end = new Date(2017, 5, 1, 20, 30, 0);
		distrib2.orderStartDate = new Date(2017, 4, 1, 18, 0, 0);
		distrib2.orderEndDate = new Date(2017, 4, 30, 18, 30, 0);
		distrib2.contract = existingDistrib.contract;
		distrib2.place = existingDistrib.place;
		var e2 = null;
		try{
			service.DistributionService.checkDistrib(distrib2);
		}
		catch(x:String){
			e2 = x;
		}
		assertEquals(e2, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date <= distrib3.end && existingDistrib.end >= distrib3.end
		var distrib3 = new db.Distribution();
		distrib3.date = new Date(2017, 5, 1, 17, 30, 0);
		distrib3.end = new Date(2017, 5, 1, 19, 30, 0);
		distrib3.orderStartDate = new Date(2017, 4, 1, 18, 0, 0);
		distrib3.orderEndDate = new Date(2017, 4, 30, 18, 30, 0);
		distrib3.contract = existingDistrib.contract;
		distrib3.place = existingDistrib.place;
		var e3 = null;
		try{
			service.DistributionService.checkDistrib(distrib3);
		}
		catch(x:String){
			e3 = x;
		}
		assertEquals(e3, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date >= distrib4.date && existingDistrib.end <= distrib4.end
		var distrib4 = new db.Distribution();
		distrib4.date = new Date(2017, 5, 1, 17, 30, 0);
		distrib4.end = new Date(2017, 5, 1, 21, 30, 0);
		distrib4.orderStartDate = new Date(2017, 4, 1, 18, 0, 0);
		distrib4.orderEndDate = new Date(2017, 4, 30, 18, 30, 0);
		distrib4.contract = existingDistrib.contract;
		distrib4.place = existingDistrib.place;
		var e4 = null;
		try{
			service.DistributionService.checkDistrib(distrib4);
		}
		catch(x:String){
			e4 = x;
		}
		assertEquals(e4, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date  > distrib5.end
		var distrib5 = new db.Distribution();
		distrib5.date = new Date(2017, 5, 1, 17, 30, 0);
		distrib5.end = new Date(2017, 5, 1, 18, 59, 0);
		distrib5.orderStartDate = new Date(2017, 4, 1, 18, 0, 0);
		distrib5.orderEndDate = new Date(2017, 4, 30, 18, 30, 0);
		distrib5.contract = existingDistrib.contract;
		distrib5.place = existingDistrib.place;
		var e5 = null;
		try{
			service.DistributionService.checkDistrib(distrib5);
		}
		catch(x:String){
			e5 = x;
		}
		assertEquals(e5, null);

		//existingDistrib.date  > distrib6.end
		var distrib6 = new db.Distribution();
		distrib6.date = new Date(2017, 5, 1, 17, 30, 0);
		distrib6.end = new Date(2017, 5, 1, 18, 59, 0);
		distrib6.orderStartDate = new Date(2017, 4, 1, 18, 0, 0);
		distrib6.orderEndDate = new Date(2017, 5, 30, 18, 30, 0);
		distrib6.contract = existingDistrib.contract;
		distrib6.place = existingDistrib.place;
		var e6 = null;
		try{
			service.DistributionService.checkDistrib(distrib6);
		}
		catch(x:String){
			e6 = x;
		}
		assertEquals(e6, "The distribution start date must be set after the orders end date.");

	}

}