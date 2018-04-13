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

}