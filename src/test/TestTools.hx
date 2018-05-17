package test;
import Common;

/**
 * Test various tools
 * 
 * @author fbarbut
 */
class TestTools extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	

	function testDateRanges(){        
        // test last hour range
		var now = Date.fromString("2018-01-01 00:30:12");
		var r = tools.DateTool.getLastHourRange(now);
        assertEquals("2017-12-31 23:00:00",r.from.toString());
		assertEquals("2018-01-01 00:00:00",r.to.toString());

		// test last minute
		var now = Date.fromString("2018-01-01 00:30:12");
		var r = tools.DateTool.getLastMinuteRange(now);
        assertEquals("2018-01-01 00:29:00",r.from.toString());
		assertEquals("2018-01-01 00:30:00",r.to.toString());
	}

/*
	@admin
	public function doTests() {
		
		var assertTrue = function(val, ?desc="") {
			if (val) {
				Sys.println("OK : <br/>");
			}else {
				Sys.println("ERROR : "+desc+"<br/>");
			}
		}
		
		
		//test les fonctions de cotisation
		
		var amap = db.Amap.manager.get(1);
		
		amap.membershipRenewalDate = new Date(2015, 0, 1,0,0,0);
		amap.update();
		
		assertTrue(amap.getMembershipYear(new Date(2015, 3, 3, 0, 0, 0) ) == 2015);
		assertTrue(amap.getPeriodName(new Date(2015, 3, 3, 0, 0, 0)) == "2015");
		
		assertTrue(amap.getMembershipYear(new Date(2014, 8, 8, 0, 0, 0) ) == 2014);
		assertTrue(amap.getPeriodName(new Date(2014, 8, 8, 0, 0, 0) ) == "2014");
		
		assertTrue(amap.getMembershipYear(new Date(2013, 11, 12, 0, 0, 0) ) == 2013);
		assertTrue(amap.getPeriodName(new Date(2013, 11, 12, 0, 0, 0) ) == "2013");
		
		amap.membershipRenewalDate = new Date(2015, 8, 1,0,0,0);
		amap.update();
		
		assertTrue(amap.getMembershipYear(new Date(2015, 3, 3, 0, 0, 0) ) == 2014);
		assertTrue(amap.getPeriodName(new Date(2015, 3, 3, 0, 0, 0)) == "2014-2015");
		
		var d = amap.getMembershipYear(new Date(2015, 8, 8, 0, 0, 0) );
		assertTrue( d == 2015, "le 8 sept 2015, on doit etre en cotis 2015, la c " + d);
		assertTrue(amap.getPeriodName(new Date(2015, 8, 8, 0, 0, 0)) == "2015-2016");
		
		var d = new Date(2013, 11, 12, 0, 0, 0) ;
		assertTrue( amap.getMembershipYear(d) == 2013, "le 12 oct 2013, on doit etre en cotis 2013 , là c " + amap.getMembershipYear(d) );
		assertTrue(amap.getPeriodName(d) == "2013-2014", "le 12 oct 2013, on doit etre en 2013-2014 , là c " + amap.getPeriodName(d) );
		
		
	}*/

}