package tools;

/**
 * Date tool
 * @author fbarbut
 */
class DateTool
{

	public static function now():Date{
		return Date.now();
	}
	
	public static function deltaDays(d:Date,n:Int):Date{
		return DateTools.delta(d, n * 1000 * 60 * 60 * 24.0);
	}
	
	public static function setHourMinute(d:Date, hour:Int, minute:Int):Date{
		return new Date(d.getFullYear(), d.getMonth(), d.getDate(), hour, minute, 0);
	}
	
	public static function setDateMonth(d:Date, date:Int, month:Int):Date{
		return new Date(d.getFullYear(), month, date, d.getHours(), d.getMinutes(), 0);
	}


	public static function getLastHourRange(?now:Date){
		if(now==null) now = Date.now();
		var HOUR = 1000.0 * 60 * 60;
		var to = setHourMinute(now,now.getHours(),0);
		var from = DateTools.delta(to, -HOUR );
		return {from:from,to:to};
	}

	public static function getLastMinuteRange(?now:Date){
		if(now==null) now = Date.now();
		var MIN = 1000.0 * 60;
		var to = setHourMinute(now,now.getHours(),now.getMinutes());
		var from = DateTools.delta(to, -MIN );
		return {from:from,to:to};
	}
}