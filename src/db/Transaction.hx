package db;
import sys.db.Types;

enum TransactionType{
	TTOrder(distribKey:String,basketId:Int,orders:Array<Int>);
	TTAmapOrder(contract:Int);
	TTPayment(paymentType:String,distribKey:String,?remoteOpId:Int);//payemnt type : check/transfer/money + remote operation ID
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
	@hideInForms @:relation(groupId) public var group : db.Amap;
	
	public var pending : SBool;
	
	public function getTypeIndex(){
		var e : TransactionType = type;		
		return e.getIndex();
	}
	
	/**
	 * if transaction is a payment, give the payment type
	 */
	public function getPaymentType():String{
		switch(type){
			case TTPayment(pt,distribKey,opId): return pt;
			default : return null;
		}		
	}	
	
	
	public function getOrderInfos(){
		switch(type){
			case TTOrder(dk,basketId,orders) : return {distribKey:dk, order:orders};
			default : return null;
		}
	}
	
	public static function getTransactions(user:db.User,group:db.Amap){		
		return manager.search($user == user && $group == group,{orderBy:date},false);		
	}
	
	/**
	 * Create a new transaction
	 * @param	orders
	 */
	public static function makeOrderTransaction(orders: Array<db.UserContract>,?basket:db.Basket){
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var contract = orders[0].product.contract;
		
		var t = new db.Transaction();
		
		if (contract.type == db.Contract.TYPE_CONSTORDERS){
			//Constant orders			
			t.name = "Contrat " + contract.name + "(" + contract.vendor.name+")";
			var dNum = contract.getDistribs(false).length;
			t.amount = dNum * (0 - _amount);
			t.date = Date.now();
			t.type = TTOrder("",null,Lambda.array(Lambda.map(orders, function(x) return x.id)));
			t.user = orders[0].user;
			t.group = orders[0].product.contract.amap;
			t.pending = false;					
			
		}else{
			
			//varying orders
			t.name = "Commande pour le " + App.current.view.dDate(orders[0].distribution.date);
			t.amount = 0 - _amount;
			t.date = Date.now();
			t.type = TTOrder(orders[0].distribution.getKey(),basket.id,Lambda.array(Lambda.map(orders, function(x) return x.id)));
			t.user = orders[0].user;
			t.group = orders[0].product.contract.amap;
			t.pending = true;					
		}
		
		t.insert();
		
		updateUserBalance(t.user, App.current.user.amap);
	
	}
	
	public static function makeOrderPayment(type:String, amount:Float, name:String ){
		
		var t = new db.Transaction();
		t.amount = Math.abs(amount);
		t.date = Date.now();
		t.name = name;
		t.group = App.current.user.amap;
		t.pending = true;
		t.user = App.current.user;
		t.type = TTPayment(type,"");
		t.insert();
		
		updateUserBalance(App.current.user, App.current.user.amap);
		
		return t;
		
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
		var transactions = manager.search($user == user && $group == group && $pending == true , {orderBy:date}, true);
		
		for ( t in transactions){
			
			switch(t.type){
				
				case TTOrder(_dkey,_basketId, orders) :
					/*var id = Lambda.find(orders, function(x) return db.UserContract.manager.get(x, false) != null);
					
					if (id == null) {						
						//all orders in this transaction dont exists anymore
						t.delete();
						continue;
					}
					var o = db.UserContract.manager.get(id, false);
					
					if (o.distribution == null) throw 'order #${o.id} should be linked to a distribution';
					if ( o.distribution.date.toString().substr(0, 10) == date){
						if (o.distribution.place.id == placeId){
							return t;	
						}						
					}*/
					if (dkey == _dkey) return t;
					
					
				default : 
					continue;				
			}
		}
		
		return null;
	}
	
	/**
	 * when updating a constant order, we need to update the existing transaction.
	 * 
	 */
	public static function findCOrderTransactionFor(contract:db.Contract, user:db.User){
		
		if (contract.type != db.Contract.TYPE_CONSTORDERS) throw "contract type should be TYPE_CONSTORDERS";
		
		var transactions = manager.search($user == user && $group == contract.amap && $amount<0, {orderBy:date,limit:100}, true);
		
		for ( t in transactions){
			
			switch(t.type){
				
				case TTOrder(dkey,basketId,orders) :
					
					var id = Lambda.find(orders, function(x) return db.UserContract.manager.get(x, false) != null);					
					if (id == null) {						
						//all orders in this transaction dont exists anymore
						t.delete();
						continue;
					}else{
						for ( i in orders){
							var order = db.UserContract.manager.get(i);
							if (order == null) continue;
							if (order.product.contract.id == contract.id) return t;
						}	
					}
					
					
				default : 
					continue;				
			}
		}
		
		return null;
		
	}
	
	public static function getPaymentTypes(group:db.Amap):Array<payment.Payment>{
		var out :Array<payment.Payment> = [];
		for ( t in group.allowedPaymentsType){
			switch(t){
				case "cash" : out.push(new payment.Cash());
				case "transfer" : out.push(new payment.Transfer());
				case "check" : out.push(new payment.Check());
			}
			
		}
		return out;
	}
}