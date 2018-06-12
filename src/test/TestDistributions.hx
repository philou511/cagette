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
		TestSuite.initDB();
		TestSuite.initDatas();
	}
	
	/**
	 * Check that we can add a distribution outside existing time range for a specific contract and place
	 * Check that we can't add a distribution overlapping with existing distribution for a specific contract and place
	 */
	function testOverlapping() {        
    	var existingDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		var e1 = null;
		try {
			var distrib1 = service.DistributionService.create(existingDistrib.contract,new Date(2018, 5, 1, 18, 0, 0),new Date(2018, 5, 1, 18, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2018, 4, 1, 18, 0, 0),new Date(2018, 4, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error) {
			e1 = x;
		}
		assertEquals(e1, null);

		//existingDistrib.date <= distrib2.date && existingDistrib.end >= distrib2.date
		var e2 = null;
		try {
			var distrib2 = service.DistributionService.create(existingDistrib.contract,new Date(2017, 5, 1, 19, 30, 0),new Date(2017, 5, 1, 20, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error) {
			e2 = x;
		}
		assertEquals(e2.message, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date <= distrib3.end && existingDistrib.end >= distrib3.end
		var e3 = null;
		try{
			var distrib3 = service.DistributionService.create(existingDistrib.contract,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 19, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error){
			e3 = x;
		}
		assertEquals(e3.message, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date >= distrib4.date && existingDistrib.end <= distrib4.end
		var e4 = null;
		try{
			var distrib4 = service.DistributionService.create(existingDistrib.contract,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 21, 30, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error){
			e4 = x;
		}
		assertEquals(e4.message, "There is already a distribution at this place overlapping with the time range you've selected.");

		//existingDistrib.date  > distrib5.end
		var e5 = null;
		try{
			var distrib5 = service.DistributionService.create(existingDistrib.contract,new Date(2017, 5, 1, 17, 30, 0),new Date(2017, 5, 1, 18, 59, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 4, 1, 18, 0, 0),new Date(2017, 4, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error){
			e5 = x;
		}
		assertEquals(e5, null);

		//existingDistrib.date  > distrib6.end
		var e6 = null;
		try{
			var distrib6 = service.DistributionService.create(existingDistrib.contract,new Date(2017, 3, 1, 17, 30, 0),new Date(2017, 3, 1, 18, 59, 0),
			existingDistrib.place.id,null,null,null,null,new Date(2017, 2, 1, 18, 0, 0),new Date(2017, 3, 30, 18, 30, 0));
		}
		catch(x:tink.core.Error){
			e6 = x;
		}
		assertEquals(e6.message, "The distribution start date must be set after the orders end date.");

	}

	/**
	 * Check that we can add a distribution outside existing time range for a specific contract and place
	 * Check that we can't add a distribution overlapping with existing distribution for a specific contract and place
	 */
	function testEdit() { 

		//TO DO
		assertEquals(true, true);
	}

	function testCreateCycle() {
		TestSuite.CONTRAT_LEGUMES.startDate = new Date(2018, 0, 1, 0, 0, 0);
		TestSuite.CONTRAT_LEGUMES.endDate = new Date(2019, 11, 31, 23, 59, 0);
		TestSuite.CONTRAT_LEGUMES.update();

		var weeklyDistribCycle = service.DistributionService.createCycle(TestSuite.CONTRAT_LEGUMES,Weekly,new Date(2018, 11, 24, 0, 0, 0),
		new Date(2019, 0, 24, 0, 0, 0),new Date(2018, 5, 4, 13, 0, 0),new Date(2018, 5, 4, 14, 0, 0),10,2,
		new Date(2018, 5, 4, 8, 0, 0),new Date(2018, 5, 4, 23, 0, 0),TestSuite.PLACE_DU_VILLAGE.id);

		var weeklyDistribs = Lambda.array(db.Distribution.manager.search($distributionCycle == weeklyDistribCycle, false));
		assertEquals(weeklyDistribs.length, 5);
		assertEquals(weeklyDistribs[0].date.toString(), new Date(2018, 11, 24, 13, 0, 0).toString());
		assertEquals(weeklyDistribs[0].end.toString(), new Date(2018, 11, 24, 14, 0, 0).toString());
		assertEquals(weeklyDistribs[1].date.toString(), new Date(2018, 11, 31, 13, 0, 0).toString());
		assertEquals(weeklyDistribs[1].end.toString(), new Date(2018, 11, 31, 14, 0, 0).toString());
		assertEquals(weeklyDistribs[2].date.toString(), new Date(2019, 0, 7, 13, 0, 0).toString());
		assertEquals(weeklyDistribs[2].end.toString(), new Date(2019, 0, 7, 14, 0, 0).toString());
		assertEquals(weeklyDistribs[3].date.toString(), new Date(2019, 0, 14, 13, 0, 0).toString());
		assertEquals(weeklyDistribs[3].end.toString(), new Date(2019, 0, 14, 14, 0, 0).toString());
		assertEquals(weeklyDistribs[4].date.toString(), new Date(2019, 0, 21, 13, 0, 0).toString());
		assertEquals(weeklyDistribs[4].end.toString(), new Date(2019, 0, 21, 14, 0, 0).toString());
		service.DistributionService.deleteCycleDistribs(weeklyDistribCycle);

		var monthlyDistribCycle = service.DistributionService.createCycle(TestSuite.CONTRAT_LEGUMES,Monthly,new Date(2018, 9, 30, 0, 0, 0),
		new Date(2019, 2, 31, 0, 0, 0),new Date(2018, 5, 4, 13, 0, 0),new Date(2018, 5, 4, 14, 0, 0),10,2,
		new Date(2018, 5, 4, 8, 0, 0),new Date(2018, 5, 4, 23, 0, 0),TestSuite.PLACE_DU_VILLAGE.id);

		var monthlyDistribs = Lambda.array(db.Distribution.manager.search($distributionCycle == monthlyDistribCycle, false));
		assertEquals(monthlyDistribs.length, 6);
		assertEquals(monthlyDistribs[0].date.toString(), new Date(2018, 9, 30, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[0].end.toString(), new Date(2018, 9, 30, 14, 0, 0).toString());
		assertEquals(monthlyDistribs[1].date.toString(), new Date(2018, 10, 27, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[1].end.toString(), new Date(2018, 10, 27, 14, 0, 0).toString());
		assertEquals(monthlyDistribs[2].date.toString(), new Date(2018, 11, 25, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[2].end.toString(), new Date(2018, 11, 25, 14, 0, 0).toString());
		assertEquals(monthlyDistribs[3].date.toString(), new Date(2019, 0, 29, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[3].end.toString(), new Date(2019, 0, 29, 14, 0, 0).toString());
		assertEquals(monthlyDistribs[4].date.toString(), new Date(2019, 1, 26, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[4].end.toString(), new Date(2019, 1, 26, 14, 0, 0).toString());
		assertEquals(monthlyDistribs[5].date.toString(), new Date(2019, 2, 26, 13, 0, 0).toString());
		assertEquals(monthlyDistribs[5].end.toString(), new Date(2019, 2, 26, 14, 0, 0).toString());
		service.DistributionService.deleteCycleDistribs(monthlyDistribCycle);
		
		var biweeklyDistribCycle = service.DistributionService.createCycle(TestSuite.CONTRAT_LEGUMES,BiWeekly,new Date(2018, 9, 30, 0, 0, 0),
		new Date(2019, 0, 31, 0, 0, 0),new Date(2018, 5, 4, 13, 0, 0),new Date(2018, 5, 4, 14, 0, 0),10,2,
		new Date(2018, 5, 4, 8, 0, 0),new Date(2018, 5, 4, 23, 0, 0),TestSuite.PLACE_DU_VILLAGE.id);

		var biweeklyDistribs = Lambda.array(db.Distribution.manager.search($distributionCycle == biweeklyDistribCycle, false));
		assertEquals(biweeklyDistribs.length, 7);
		assertEquals(biweeklyDistribs[0].date.toString(), new Date(2018, 9, 30, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[0].end.toString(), new Date(2018, 9, 30, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[1].date.toString(), new Date(2018, 10, 13, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[1].end.toString(), new Date(2018, 10, 13, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[2].date.toString(), new Date(2018, 10, 27, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[2].end.toString(), new Date(2018, 10, 27, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[3].date.toString(), new Date(2018, 11, 11, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[3].end.toString(), new Date(2018, 11, 11, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[4].date.toString(), new Date(2018, 11, 25, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[4].end.toString(), new Date(2018, 11, 25, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[5].date.toString(), new Date(2019, 0, 8, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[5].end.toString(), new Date(2019, 0, 8, 14, 0, 0).toString());
		assertEquals(biweeklyDistribs[6].date.toString(), new Date(2019, 0, 22, 13, 0, 0).toString());
		assertEquals(biweeklyDistribs[6].end.toString(), new Date(2019, 0, 22, 14, 0, 0).toString());
		service.DistributionService.deleteCycleDistribs(biweeklyDistribCycle);
	
		var triweeklyDistribCycle = service.DistributionService.createCycle(TestSuite.CONTRAT_LEGUMES,TriWeekly,new Date(2018, 9, 30, 0, 0, 0),
		new Date(2019, 0, 31, 0, 0, 0),new Date(2018, 5, 4, 13, 0, 0),new Date(2018, 5, 4, 14, 0, 0),10,2,
		new Date(2018, 5, 4, 8, 0, 0),new Date(2018, 5, 4, 23, 0, 0),TestSuite.PLACE_DU_VILLAGE.id);

		var triweeklyDistribs = Lambda.array(db.Distribution.manager.search($distributionCycle == triweeklyDistribCycle, false));
		assertEquals(triweeklyDistribs.length, 5);
		assertEquals(triweeklyDistribs[0].date.toString(), new Date(2018, 9, 30, 13, 0, 0).toString());
		assertEquals(triweeklyDistribs[0].end.toString(), new Date(2018, 9, 30, 14, 0, 0).toString());
		assertEquals(triweeklyDistribs[1].date.toString(), new Date(2018, 10, 20, 13, 0, 0).toString());
		assertEquals(triweeklyDistribs[1].end.toString(), new Date(2018, 10, 20, 14, 0, 0).toString());
		assertEquals(triweeklyDistribs[2].date.toString(), new Date(2018, 11, 11, 13, 0, 0).toString());
		assertEquals(triweeklyDistribs[2].end.toString(), new Date(2018, 11, 11, 14, 0, 0).toString());
		assertEquals(triweeklyDistribs[3].date.toString(), new Date(2019, 0, 1, 13, 0, 0).toString());
		assertEquals(triweeklyDistribs[3].end.toString(), new Date(2019, 0, 1, 14, 0, 0).toString());
		assertEquals(triweeklyDistribs[4].date.toString(), new Date(2019, 0, 22, 13, 0, 0).toString());
		assertEquals(triweeklyDistribs[4].end.toString(), new Date(2019, 0, 22, 14, 0, 0).toString());
		service.DistributionService.deleteCycleDistribs(triweeklyDistribCycle);
	}

	function testDelete() { 
		//A variable contract with a distribution that has orders
		var ordersDistrib = TestSuite.DISTRIB_LEGUMES_RUE_SAUCISSE;
		var chicken = TestSuite.CHICKEN;
		var order = db.UserContract.make(TestSuite.FRANCOIS, 1, chicken, ordersDistrib.id);

		var e = null;
		try{
			service.DistributionService.delete(ordersDistrib);
		}
		catch(x:tink.core.Error){
			e = x;
		}
		assertEquals(e.message, "Deletion non possible: some orders are saved for this delivery.");

		//A variable contract with a distribution that has no orders
		var noOrdersDistrib = TestSuite.DISTRIB_FRUITS_PLACE_DU_VILLAGE;
		
		var e = null;
		try{
			service.DistributionService.delete(noOrdersDistrib);
		}
		catch(x:tink.core.Error){
			e = x;
		}
		assertEquals(e, null);

		//An Amap contract with a distribution that has orders
		var amapDistrib = TestSuite.DISTRIB_CONTRAT_AMAP;
		var panier = TestSuite.PANIER_AMAP_LEGUMES;
		var amapOrder = db.UserContract.make(TestSuite.FRANCOIS, 1, panier, amapDistrib.id);

		var e = null;
		try{
			service.DistributionService.delete(amapDistrib);
		}
		catch(x:tink.core.Error){
			e = x;
		}
		assertEquals(e, null);

		
	}

}