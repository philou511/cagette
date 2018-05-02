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
	function testOverlapping() {        
    	var existingDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		var e1 = null;
		try {
			var distrib1 = service.DistributionService.create(existingDistrib.contract,null,new Date(2018, 5, 1, 18, 0, 0),new Date(2018, 5, 1, 18, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2018, 4, 1, 18, 0, 0),new Date(2018, 4, 30, 18, 30, 0));
		}
		catch(x:String) {
			e1 = x;
		}
		assertEquals(e1, null);

		//existingDistrib.date <= distrib2.date && existingDistrib.end >= distrib2.date
		var e2 = null;
		try {
			var distrib2 = service.DistributionService.create(existingDistrib.contract,null,new Date(2017, 5, 1, 19, 30, 0),new Date(2017, 5, 1, 20, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:String) {
			e2 = x;
		}
		assertEquals(e2, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date <= distrib3.end && existingDistrib.end >= distrib3.end
		var e3 = null;
		try{
			var distrib3 = service.DistributionService.create(existingDistrib.contract,null,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 19, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:String){
			e3 = x;
		}
		assertEquals(e3, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date >= distrib4.date && existingDistrib.end <= distrib4.end
		var e4 = null;
		try{
			var distrib4 = service.DistributionService.create(existingDistrib.contract,null,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 21, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:String){
			e4 = x;
		}
		assertEquals(e4, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date  > distrib5.end
		var e5 = null;
		try{
			var distrib5 = service.DistributionService.create(existingDistrib.contract,null,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 18, 59, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:String){
			e5 = x;
		}
		assertEquals(e5, null);

		//existingDistrib.date  > distrib6.end
		var e6 = null;
		try{
			var distrib6 = service.DistributionService.create(existingDistrib.contract,null,new Date(2017, 3, 1, 17, 30, 0),new Date(2017, 3, 1, 18, 59, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 2, 1, 18, 0, 0),new Date(2017, 3, 30, 18, 30, 0));
		}
		catch(x:String){
			e6 = x;
		}
		assertEquals(e6, "The distribution start date must be set after the orders end date.");

	}

	/**
	 * Check that we can add a distribution outside existing time range for a specific contract and place
	 * Check that we can't add a distribution overlapping with existing distribution for a specific contract and place
	 */
	function testEdit() { 

		//TO DO
    
}