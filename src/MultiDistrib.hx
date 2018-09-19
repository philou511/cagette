package;
using tools.ObjectListTool;
using Lambda;

/**
 *  MultiDistrib represents many db.Distribution
 	which happen on the same day + same place.
 * 
 * @author fbarbut
 */
class MultiDistrib
{
	public var distributions : Array<db.Distribution>;
	public var contracts : Array<db.Contract>;

	public function new(){
		distributions  = [];
		contracts = [];
	}
	
	public static function get(date:Date, place:db.Place){
		var m = new MultiDistrib();
		
		var start = tools.DateTool.setHourMinute(date, 0, 0);
		var end = tools.DateTool.setHourMinute(date, 23, 59);
		
		var cids = place.amap.getContracts().getIds();
		m.distributions = db.Distribution.manager.search(($contractId in cids) && ($date >= start) && ($date <= end) && $place==place, { orderBy:date }, false).array();
		
		return m;
	}

	/**
	Get multidistribs from a time range + place
	**/
	public static function getFromTimeRange(from:Date,to:Date,place:db.Place){
		var multidistribs = [];
		var start = tools.DateTool.setHourMinute(from, 0, 0);
		var end = tools.DateTool.setHourMinute(to, 23, 59);
		var cids = place.amap.getContracts().getIds();
		var distributions = db.Distribution.manager.search(($contractId in cids) && ($date >= start) && ($date <= end) && $place==place, { orderBy:date }, false).array();
		//sort by day-place
		var multidistribs = new Map<String,MultiDistrib>();
		for ( d in distributions){
			var key = d.getKey();
			if(multidistribs[key]==null){
				var m = new MultiDistrib();
				m.distributions.push(d);
				multidistribs[key] = m;
			}else{
				multidistribs[key].distributions.push(d);
			}
		}
		var multidistribs = Lambda.array(multidistribs);
		multidistribs.sort(function(x,y){
			return Math.round( x.getDate().getTime()/1000) - Math.round(y.getDate().getTime()/1000 );
		});

		return multidistribs;
	}

	public function getPlace(){
		if(distributions.length==0) throw "This multidistrib is empty";
		return distributions[0].place;
	}

	public function getDate(){
		if(distributions.length==0) throw "This multidistrib is empty";
		return distributions[0].date;
	}
	
	/**
	 * Get all orders involved in this multidistrib
	 */
	public function getOrders(){
		var out = [];
		for ( d in distributions){
			out = out.concat(d.getOrders().array());
		}
		return out;		
	}

	/**
	 * Get orders for a user in this multidistrib
	 * @param user 
	 */
	public function getUserOrders(user:db.User){
		var out = [];
		for ( d in distributions){
			var pids = Lambda.map( d.contract.getProducts(false), function(x) return x.id);		
			var userOrders =  db.UserContract.manager.search( $userId == user.id && $distributionId==d.id && $productId in pids , false);	
			for( o in userOrders ){
				out.push(o);
			}
		}
		return out;		
	}
	
	public function getUsers(){
		var users = [];
		for ( o in getOrders()) users.push(o.user);
		return users.deduplicate();		
	}
	
	
	
	public function isConfirmed():Bool{
		//cannot be in future
		if(getDate().getTime()>Date.now().getTime()) return false;

		return Lambda.count( distributions, function(d) return d.validated) == distributions.length;
	}
	
	public function checkConfirmed():Bool{
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