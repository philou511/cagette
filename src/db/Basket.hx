package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Basket : represents the orders of a user for specific date + place
 */
//@:index(userId,placeId,ddate,unique)
class Basket extends Object
{
	public var id : SId;
	public var cdate : SDateTime; //date when the order has been placed
	public var num : SInt;		 //order number

	//TODO : link baskets to a multidistrib ID.
	
	//2018-07-21 fbarbut : we cannot use keys like this, because some distribution's place or date may change after orders are made.
	//@:relation(userId) public var user : db.User;
	//@:relation(placeId) public var place : db.Place;
	//public var ddate : SDate;	//date of the delivery

	public var data : SNull<SData<Map<Int,RevenueAndFees>>>; //store shared revenue
	
	public static var CACHE = new Map<String,db.Basket>();
	
	public function new(){
		super();
		cdate = Date.now();
	}

	public static function emptyCache(){
		CACHE = new Map<String,db.Basket>();
	}
	
	public static function get(user:db.User, place:db.Place, date:Date, ?lock = false):db.Basket{
		
		date = tools.DateTool.setHourMinute(date, 0, 0);

		//caching
		// var k = user.id + "-" + place.id + "-" + date.toString().substr(0, 10);
		// var b = CACHE.get(k);
		var b = null;
		// if (b == null){
			var md = MultiDistrib.get(date, place,db.Contract.TYPE_VARORDER);
			var orders = md.getUserOrders(user);
			
			for( o in orders){
				if(o.basket!=null) {
					b = o.basket;
					break;
				}
			}
			// CACHE.set(k, b);
		// }
		
		return b;
	}
	
	/**
	 * Get a Basket or create it if it doesn't exists.
	 * Also link existing orders to this basket
	 * @param user 
	 * @param place 
	 * @param date 
	 */
	public static function getOrCreate(user, place, date){
		var b = get(user, place, date, true);
		
		date = tools.DateTool.setHourMinute(date, 0, 0);
		
		if (b == null){
			
			//compute basket number
			var md = MultiDistrib.get(date, place,db.Contract.TYPE_VARORDER);
			
			b = new Basket();
			b.num = md.getUsers().length + 1;
			//TODO : should be more safe to do something like "b.num = MAX(num)+1 FROM Basket"
			b.insert();
			
			//try to find orders and link them to the basket			
			var dids = tools.ObjectListTool.getIds(md.getDistributions());
			for ( o in db.UserContract.manager.search( ($distributionId in dids) && ($user == user), true)){
				o.basket = b;
				o.update();
			}
		}		
		return b;		
	}

	public function getUser():db.User{
		return getOrders().first().user;
	}
	
	/**
	 *  Get basket's orders
	 */
	public function getOrders() {
		return db.UserContract.manager.search($basket == this, false);
	}
	
	/**
	 * Returns the list of operations which paid this basket
	 * @return
	 */
	public function getPaymentsOperations():Array<db.Operation> {
		
		var op = getOrderOperation(false);
		if (op == null){
			return [];
		}else{			
			return Lambda.array(op.getRelatedPayments());
		}
	}

	/**
	 * Returns the total amount of payments
	 * @return Float
	 */
	public function getTotalPaid() : Float {
		
		var payments = getPaymentsOperations();
		var totalPaid = 0.0;

		//Let's sum up all the payments
		for( payment in payments ) {
			totalPaid += payment.amount;
		}

		return totalPaid;

	}

	/**
	 * Returns the total amount of all the orders in this basket
	 * @return Float
	 */
	public function getOrdersTotal() : Float {

		var total = 0.0;
		for( order in getOrders())
		{
			total += order.quantity * order.productPrice;
		}

		return total;

	}
	
	public function getOrderOperation(?onlyPending=true):db.Operation {

		var order = getOrders().first();
        if(order==null) return null;

		var key = db.Distribution.makeKey(order.distribution.date, order.distribution.place);
		return db.Operation.findVOrderTransactionFor(key, order.user, order.distribution.place.amap, onlyPending);
		
	}
	
	public function isValidated() {

		var ordersPaid = Lambda.count(getOrders(), function(o) return !o.paid) == 0;
		var op = getOrderOperation(false);
		var orderOperationNotPending = op!=null ? op.pending == false : true;
		var paymentOperationsNotPending = Lambda.count(getPaymentsOperations(), function(p) return p.pending) == 0;

		return ordersPaid && orderOperationNotPending && paymentOperationsNotPending;			
	}

	public function getGroup() : db.Amap {
		return getOrders().first().distribution.contract.amap;
	}


	public function canBeValidated()
	{
		var t = sugoi.i18n.Locale.texts;
		var hasPendingOnTheSpotPayments = Lambda.count(getPaymentsOperations(), function(x) return x.pending && x.data.type == payment.OnTheSpotPayment.TYPE) != 0;

		if (hasPendingOnTheSpotPayments)
		{
			throw new tink.core.Error(t._("You need to select manually the type of pending payments on the spot to be able to validate this distribution."));
		}
		
		return !hasPendingOnTheSpotPayments;			
	}
	
}