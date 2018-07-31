package;
using tools.ObjectListTool;
using Lambda;

/**
 * This class represents many db.Distribution which happen on a same day / same place.
 * 
 * @author fbarbut
 */
class MultiDistrib
{
	public var distributions : Array<db.Distribution>;
	public var contracts : Array<db.Contract>;

	public function new() 
	{
		
	}
	
	
	public static function get(date:Date, place:db.Place){
		var m = new MultiDistrib();
		
		var start = tools.DateTool.setHourMinute(date, 0, 0);
		var end = tools.DateTool.setHourMinute(date, 23, 59);
		
		var cids = place.amap.getContracts().getIds();
		m.distributions = db.Distribution.manager.search(($contractId in cids) && ($date >= start) && ($date <= end) && $place==place, { orderBy:date }, false).array();
		
		return m;
	}
	
	public function getOrders(){
		var out = [];
		for ( d in distributions){
			out = out.concat(d.getOrders().array());
		}
		return out;		
	}
	
	public function getUsers(){
		
		var users = [];
		for ( o in getOrders()) users.push(o.user);
		
		return users.deduplicate();		
	}
	
	
	
	public function isConfirmed(){
		return Lambda.count( distributions, function(d) return d.validated) == distributions.length;
	}
	
	public function checkConfirmed(){
		var orders = getOrders();
		var c = Lambda.count( orders, function(d) return d.paid) == orders.length;
		
		if (c){
			for ( d in distributions){
				if (!d.validated){
					d.lock();
					d.validated = true;
					d.update();
				}
			}
		}
		
		return c;
	}
	
}