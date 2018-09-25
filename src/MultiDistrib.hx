package;
import Common;
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
	public static function getFromTimeRange(group:db.Amap,from:Date,to:Date){
		var multidistribs = [];
		var start = tools.DateTool.setHourMinute(from, 0, 0);
		var end = tools.DateTool.setHourMinute(to, 23, 59);
		var cids = group.getContracts().getIds();
		var distributions = db.Distribution.manager.search(($contractId in cids) && ($date >= start) && ($date <= end) , { orderBy:date }, false).array();
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

	/**
	 * TODO : refacto this to use getFromTimeRange();
	 */
	public static function getNextMultiDeliveries(group:db.Amap){
		
		var out = new Map < String, {
			place:db.Place, 		//common delivery place
			startDate:Date, 		//global delivery start
			endDate:Date,			//global delivery stop
			orderStartDate:Date, 	//global orders opening date
			orderEndDate:Date,		//global orders closing date
			active:Bool,
			products:Array<ProductInfo>, //available products ( if no order )
			myOrders:Array<{distrib:db.Distribution,orders:Array<UserOrder>}>	//my orders			
		}>();
		
		var n = Date.now();
		var now = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
	
		var contracts = db.Contract.getActiveContracts(group);
		var cids = Lambda.map(contracts, function(p) return p.id);
		
		//var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		//var out =  UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, lock);	
		
		//available deliveries
		var inSixMonth = DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30 * 6);
		var distribs = db.Distribution.manager.search(($contractId in cids) && $date >= now && $date <= inSixMonth , { orderBy:date }, false);
		
		for (d in distribs) {			
			
			//we had the distribution key ( place+date ) and the contract type in order to separate constant and varying contracts
			var key = d.getKey() + "|" + d.contract.type;
			var o = out.get(key);
			if (o == null) o = {place:d.place, startDate:d.date, active:null, endDate:d.end, products:[], myOrders:[], orderStartDate:null,orderEndDate:null};
			
			//user orders
			var orders = [];
			if(App.current.user!=null) orders = d.contract.getUserOrders(App.current.user,d);
			if (orders.length > 0){
				o.myOrders.push({distrib:d,orders:service.OrderService.prepare(orders)});
			}else{
				//no "order block" if no shop mode	
				if (!group.hasShopMode() ) {		
					continue;		
				}		

				//if its a constant order contract, skip this delivery		
				if (d.contract.type == db.Contract.TYPE_CONSTORDERS){		
					continue;		
				}
				
				//products preview if no orders
				for ( p in d.contract.getProductsPreview(9)){
					o.products.push( p.infos(null,false) );	
				}	
			}
			
			if (d.contract.type == db.Contract.TYPE_VARORDER){
				
				//old distribs may have an empty orderStartDate
				if (d.orderStartDate == null) {
					continue;
				}
				
				//if order opening is more far than 1 month, skip it
				/*if (d.orderStartDate.getTime() > inOneMonth.getTime() ){
					continue;
				}*/
				
				//display closest opening date
				if (o.orderStartDate == null){
					o.orderStartDate = d.orderStartDate;
				}else if (o.orderStartDate.getTime() > d.orderStartDate.getTime()){
					o.orderStartDate = d.orderStartDate;
				}
				
				//display most far closing date
				if (o.orderEndDate == null){
					o.orderEndDate = d.orderEndDate;
				}else if (o.orderEndDate.getTime() < d.orderEndDate.getTime()){
					o.orderEndDate = d.orderEndDate;
				}
				
				out.set(key, o);	
				
			}else{
				//in constant orders, add block only if there is an order
				if(o.myOrders.length>0) out.set(key, o);
				
			}
		}
		
		//shuffle and limit product lists		
		for ( o in out){
			o.products = thx.Arrays.shuffle(o.products);			
			o.products = o.products.slice(0, 9);
		}
		
		//decide if active or not
		var now = Date.now();
		for( o in out){
			
			if (o.orderStartDate == null) continue; //constant orders
			
			if (now.getTime() >= o.orderStartDate.getTime()  && now.getTime() <= o.orderEndDate.getTime() ){
				//order currently open
				o.active = true;
				
			}else {
				o.active = false;
				
			}
		}	
		
		return Lambda.array(out);
	}

	public function getPlace(){
		if(distributions.length==0) throw "This multidistrib is empty";
		return distributions[0].place;
	}

	public function getDate(){
		if(distributions.length==0) throw "This multidistrib is empty";
		return distributions[0].date;
	}

	public function getEndDate(){
		if(distributions.length==0) throw "This multidistrib is empty";
		return distributions[0].end;
	}

	public function getProductsExcerpt(){
		var products = [];
		for( d in distributions){
			for ( p in d.contract.getProductsPreview(9)){
				products.push( p.infos(null,false) );	
			}
		}
		products = thx.Arrays.shuffle(products);			
		products = products.slice(0, 9);
		return products;	

	}

	public function userHasOrders(user:db.User):Bool{
		for ( d in distributions){
			var pids = Lambda.map( d.contract.getProducts(false), function(x) return x.id);		
			if( db.UserContract.manager.count( $userId == user.id && $distributionId==d.id && $productId in pids) > 0 ){
				return true;
			}			
		}
		return false;
	}
	
	/**
	orders currently open ?
	**/
	public function isActive(){

		if (getOrdersStartDate() == null) return false; //constant orders
			
		var now = Date.now();	
		if (now.getTime() >= getOrdersStartDate().getTime()  && now.getTime() <= getOrdersEndDate().getTime() ){			
			return true;				
		}else {
			return false;				
		}
	}

	public function getOrdersStartDate(){
		var date = null;

		for( d in distributions ){
			if(d.orderStartDate==null) continue;
			//display closest opening date
			if (date == null){
				date = d.orderStartDate;
			}else if (date.getTime() > d.orderStartDate.getTime()){
				date = d.orderStartDate;
			}
		}
		return date;
		
	}

	public function getOrdersEndDate(){
		var date = null;

		for( d in distributions ){
			if(d.orderEndDate==null) continue;
			//display most far closing date
			if (date == null){
				date = d.orderEndDate;
			}else if (date.getTime() < d.orderEndDate.getTime()){
				date = d.orderEndDate;
			}
		}
		return date;
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