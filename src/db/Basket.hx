package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Basket : represents the orders of a user for specific date + place
 */
//@:index(userId,placeId,ddate,unique)
@:index(ref)
class Basket extends Object
{
	public var id : SId;
	public var ref : SNull<SString<256>>; //basket unique ref, used also by tmpBasket
	public var cdate : SDateTime; //date when the order has been placed
	public var num : SInt;		 //order number

	@:relation(userId) public var user : db.User;
	@:relation(multiDistribId) public var multiDistrib : db.MultiDistrib;

	public var data : SNull<SData<Map<Int,RevenueAndFees>>>; //store shared revenue
	
	public static var CACHE = new Map<String,db.Basket>();
	
	public function new(){
		super();
		cdate = Date.now();
	}

	public static function emptyCache(){
		CACHE = new Map<String,db.Basket>();
	}
	
	/*public static function get(user:db.User,distrib:db.MultiDistrib, ?lock = false):db.Basket{
		return manager.select($user==user && $multiDistrib==distrib,lock);
	}*/
	public static function get(user:db.User,md:db.MultiDistrib, ?lock = false):db.Basket{
		
		//date = tools.DateTool.setHourMinute(date, 0, 0);

		//caching
		// var k = user.id + "-" + place.id + "-" + date.toString().substr(0, 10);
		// var b = CACHE.get(k);
		var b = null;
		// if (b == null){
			//var md = db.MultiDistrib.get(date, place);
			if(md==null) return null;
			for( o in md.getUserOrders(user)){
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
	 */
	public static function getOrCreate(user, distrib:db.MultiDistrib){
		var b = get(user, distrib, true);
			
		if (b == null){
			
			//compute basket number

			b = new Basket();
			b.num = distrib.getUsers().length + 1;
			b.multiDistrib = distrib;
			b.user = user;
			//TODO : should be more safe to do something like "b.num = MAX(num)+1 FROM Basket"
			b.insert();
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
	
	/**
		Get order operation related to this basket
	**/
	public function getOrderOperation(?onlyPending=true):db.Operation {

		var order = Lambda.find(getOrders(),function(o) return o.distribution!=null );
        if(order==null) return null;

		//var key = db.Distribution.makeKey(order.distribution.multiDistrib.getDate(), order.distribution.multiDistrib.getPlace());
		return db.Operation.findVOrderOperation(this.multiDistrib,this.user, onlyPending );
		
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