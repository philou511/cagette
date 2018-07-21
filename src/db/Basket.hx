package db;
import sys.db.Object;
import sys.db.Types;

/**
 * Basket : represents the orders of a user for specific date + place
 */
@:index(userId,placeId,ddate,unique)
class Basket extends Object
{
	public var id : SId;
	public var cdate : SDateTime; //date when the order has been placed
	public var num : SInt;		 //order number
	
	@:relation(userId) public var user : db.User;
	@:relation(placeId) public var place : db.Place;
	public var ddate : SDate;	//date of the delivery
	
	public static var CACHE = new Map<String,db.Basket>();
	
	public function new(){
		super();
		cdate = Date.now();
	}
	
	public static function get(user:db.User, place:db.Place, date:Date, ?lock = false):db.Basket{
		
		date = Date.fromString(date.toString().substr(0, 10));
		var k = user.id + "-" + place.id + "-" + date.toString().substr(0, 10);
		var b = CACHE.get(k);
		date = tools.DateTool.setHourMinute(date, 0, 0);
		if (b == null){
			b = db.Basket.manager.select($user == user && $place == place && $ddate == date, lock);
			CACHE.set(k, b);
		}
		
		return b;
	}
	
	/**
	 * Get a Basket or create it if it doesn't exists.
	 * Also re-link existing orders to this basket
	 * @param user 
	 * @param place 
	 * @param date 
	 */
	public static function getOrCreate(user, place, date){
		var b = get(user, place, date, true);
		
		date = tools.DateTool.setHourMinute(date, 0, 0);
		
		if (b == null){
			
			b = new Basket();
			b.user = user;
			b.place = place;
			b.ddate = date;
			b.num = db.Basket.manager.count($place == place && $ddate == date) + 1;
			b.insert();
			
			//try to find orders and link them to the basket
			var md = MultiDistrib.get(date, place);
			var dids = tools.ObjectListTool.getIds(md.distributions);
			for ( o in db.UserContract.manager.search( ($distributionId in dids) && ($user == user), true)){
				o.basket = b;
				o.update();
			}
		}		
		return b;		
	}
	
	/**
	 *  Get basket's orders
	 */
	public function getOrders(){
		return db.UserContract.manager.search($basket == this, false);
	}
	
	/**
	 * Returns the list of operations which paid this basket
	 * @return
	 */
	public function getPayments():Iterable<db.Operation>{
		
		var op = getOrderOperation(false);
		if (op == null){
			return [];
		}else{			
			return op.getRelatedPayments();
		}
	}
	
	public function getOrderOperation(?onlyPending=true):db.Operation{
		var key = db.Distribution.makeKey(this.ddate, this.place);
		return db.Operation.findVOrderTransactionFor(key, this.user, this.place.amap,onlyPending);
		
	}
	
	public function isValidated(){

		var ordersPaid = Lambda.count(getOrders(), function(o) return !o.paid) == 0;
		var op = getOrderOperation(false);
		var orderOperationNotPending = op!=null ? op.pending == false : true;
		var paymentOperationsNotPending = Lambda.count(getPayments(), function(p) return p.pending) == 0;

		return ordersPaid && orderOperationNotPending && paymentOperationsNotPending;			
	}
	
}