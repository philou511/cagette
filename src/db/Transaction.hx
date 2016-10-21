package db;
import sys.db.Types;

enum TransactionType{
	TTOrder(orders:Array<Int>);
	TTAmapOrder(contract:Int);
	TTPayment(paymentType:String,?OpId:Int);//payemnt type : check/paypal/currency + remote operation ID
	TTMembership(year:Int);	
}



/**
 * Money Transaction 
 * 
 * @author fbarbut
 */
class Transaction extends sys.db.Object
{

	public var id : SId;
	public var name : SString<128>;
	public var amount : SFloat;
	public var date : SDateTime;
	public var type : SData<TransactionType>;
	@:relation(userId) public var user : db.User;
	@:relation(groupId) public var group : db.Amap;
	
	public var pending : SBool;
	
	public function getTypeIndex(){
		var e : TransactionType = type;
		
		return e.getIndex();
	}
	
	
	public static function getTransactions(user:db.User,group:db.Amap){
		
		return manager.search($user == user && $group == group,{orderBy:date},false);
		
	}
	
	/**
	 * 
	 * @param	orders
	 */
	public static function makeOrderTransaction(orders: Array<db.UserContract>){
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var t = new db.Transaction();
		t.name = "Commande pour le " + orders[0].distribution.date.toString().substr(0, 10);
		t.amount = 0 - _amount;
		t.date = Date.now();
		t.type = TTOrder(Lambda.array(Lambda.map(orders, function(x) return x.id)));
		t.user = orders[0].user;
		t.group = App.current.user.amap;
		t.pending = true;
		
		t.insert();
		
		updateUserBalance(t.user, App.current.user.amap);
	
	}
	
	/**
	 * update user balance
	 */
	public static function updateUserBalance(user:db.User,group:db.Amap){
		
		var ua = db.UserAmap.get(user, group, true);
		ua.balance = sys.db.Manager.cnx.request('SELECT SUM(amount) FROM Transaction WHERE userId=${user.id} and groupId=${group.id}').getFloatResult(0);
		ua.update();
	}
	
	/**
	 * when updating a (varying) order , we need to update the existing pending transaction
	 */
	public static function findVOrderTransactionFor(dkey:String, user:db.User, group:db.Amap):db.Transaction{
		
		var date = dkey.split("|")[0];
		var placeId = Std.parseInt(dkey.split("|")[1]);
		var transactions = manager.search($user == user && $group == group && $pending == true , {orderBy:date}, false);
		
		for ( t in transactions){
			
			switch(t.type){
				
				case TTOrder(orders) :
					var o = db.UserContract.manager.get(orders[0], false);
					if ( o.distribution.date.toString().substr(0, 10) == date){
						if (o.distribution.place.id == placeId){
							return t;	
						}						
					}					
				default : 
					continue;				
			}
		}
		
		return null;
	}
	
}