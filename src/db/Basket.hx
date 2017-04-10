package db;
import sys.db.Object;
import sys.db.Types;

/**
 * 
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
		}
		
		return b;
		
	}
	
	
	public function getOrders(){
		return db.UserContract.manager.search($basket == this, false);
	}
	
	/**
	 * Returns the list of operations which paid this basket
	 * @return
	 */
	public function getPayments():Iterable<db.Operation>{
		
		var key = db.Distribution.makeKey(this.ddate, this.place);		
		var op = db.Operation.findVOrderTransactionFor(key, this.user, this.place.amap);
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
		
		return Lambda.count(getOrders(), function(o) return !o.paid) == 0;
		
	}
	
}