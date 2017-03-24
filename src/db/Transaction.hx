package db;
import sys.db.Types;

enum TransactionType{
	TTVOrder; //order on a varying order contract
	TTCOrder;//order on a constant order contract
	TTPayment;
	TTMembership;	
}

typedef TPaymentInfos = {type:String, ?remoteOpId:Int};
typedef TVOrderInfos = {basketId:Int};
typedef TCOrderInfos = {contractId:Int};


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
	public var type : SEnum<TransactionType>;
	public var data : SData<Dynamic>;
	@hideInForms @:relation(relationId) public var relation : SNull<db.Transaction>; //linked to another transaction : ie a payment pays an order
	
	@:relation(userId) public var user : db.User;
	@hideInForms @:relation(groupId) public var group : db.Amap;
		
	public var pending : SBool; //a pending payment means the payment has not been confirmed, a pending order means the ordre can still change before closing.
	
	public function getTypeIndex(){
		var e : TransactionType = type;		
		return e.getIndex();
	}
	
	/**
	 * if transaction is a payment, give the payment type
	 */
	public function getPaymentType():String{
		switch(type){
			case TTPayment: 
				var x : TPaymentInfos = this.data;
				if (data == null){
					return null;
				}else{
					return x.type;
				}				
			default : return null;
		}		
	}	
	
	/**
	 * get payments linked to this order transaction
	 */
	public function getRelatedPayments(){
		return db.Transaction.manager.search($relation == this, false);
	}
	
	public function getOrderInfos(){
		switch(type){
			case TTCOrder, TTVOrder : return this.data;				
			default : return null;
		}
	}
	
	public static function getTransactions(user:db.User,group:db.Amap){		
		return manager.search($user == user && $group == group,{orderBy:date},false);		
	}
	
	public static function getOrderTransactions(user:db.User,group:db.Amap){		
		return manager.search($user == user && $group == group && $type!=TTPayment,{orderBy:date},false);		
	}
	
	/**
	 * Create a new transaction
	 * @param	orders
	 */
	public static function makeOrderTransaction(orders: Array<db.UserContract>, ?basket:db.Basket){
		
		if (orders == null) throw "orders are null";
		if (orders.length == 0) throw "no orders";
		if (orders[0].user == null ) throw "no user in order";
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var contract = orders[0].product.contract;
		
		var t = new db.Transaction();
		
		if (contract.type == db.Contract.TYPE_CONSTORDERS){
			//Constant orders			
			var dNum = contract.getDistribs(false).length;
			t.name = "" + contract.name + " (" + contract.vendor.name+") "+ dNum+" distributions";			
			t.amount = dNum * (0 - _amount);
			t.date = Date.now();
			t.type = TTCOrder;
			var data : db.Transaction.TCOrderInfos = {contractId:contract.id};
			t.data = data;
			var u = orders[0].user;
			t.user = u;
			var g = orders[0].product.contract.amap;
			t.group = g;
			t.pending = true;					
			
		}else{
			
			if (basket == null) throw "varying contract orders should have a basket";
			
			//varying orders
			t.name = "Commande pour le " + App.current.view.dDate(orders[0].distribution.date);
			t.amount = 0 - _amount;
			t.date = Date.now();
			t.type = TTVOrder;
			var data : db.Transaction.TVOrderInfos = {basketId:basket.id};
			t.data = data;
			var u = orders[0].user;
			t.user = u;
			var g = orders[0].product.contract.amap;
			t.group = g;
			t.pending = true;		
		}
		
		t.insert();
		
		updateUserBalance(t.user, App.current.user.amap);
	
	}
	
	
	public static function updateOrderTransaction(t:db.Transaction, orders: Array<db.UserContract>, ?basket:db.Basket){
		
		t.lock();
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var contract = orders[0].product.contract;
		if (contract.type == db.Contract.TYPE_CONSTORDERS){
			//Constant orders			
			var dNum = contract.getDistribs(false).length;
			t.name = "" + contract.name + " (" + contract.vendor.name+") "+ dNum+" distributions";			
			t.amount = dNum * (0 - _amount);
			t.date = Date.now();			
			
		}else{
			
			if (basket == null) throw "varying contract orders should have a basket";
			
			t.amount = 0 - _amount;
			t.date = Date.now();			
		}
		
		
		t.update();
		
		updateUserBalance(t.user, App.current.user.amap);
	}
	
	/**
	 * Store a payment transaction
	 * @param	type
	 * @param	amount
	 * @param	name
	 * @param	relation
	 */
	public static function makeOrderPayment(type:String, amount:Float, name:String, relation:db.Transaction ){
		
		var t = new db.Transaction();
		t.amount = Math.abs(amount);
		t.date = Date.now();
		t.name = name;
		var g = App.current.user.amap;
		t.group = g;
		t.pending = true;
		var u = App.current.user;
		t.user = u;
		t.type = TTPayment;
		var data : TPaymentInfos = {type:type};
		t.data = data;
		t.relation = relation;
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
		var transactions = manager.search($user == user && $group == group && $pending == true && $type==TTVOrder , {orderBy:date}, true);
		var basket = db.Basket.get(user, db.Place.manager.get(placeId,false), Date.fromString(date));
		
		for ( t in transactions){
			
			switch(t.type){
				
				case TTVOrder :
					var data : TVOrderInfos = t.data;
					if ( data == null) continue;
					if (data.basketId == basket.id) return t;
					
					
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
		
		var transactions = manager.search($user == user && $group == contract.amap && $amount<0 && $type==TTCOrder, {orderBy:date,limit:100}, true);
		
		for ( t in transactions){
			
			switch(t.type){
				
				case TTCOrder :
					
					//var id = Lambda.find(orders, function(x) return db.UserContract.manager.get(x, false) != null);					
					//if (id == null) {						
						////all orders in this transaction dont exists anymore
						//t.delete();
						//continue;
					//}else{
						//for ( i in orders){
							//var order = db.UserContract.manager.get(i);
							//if (order == null) continue;
							//if (order.product.contract.id == contract.id) return t;
						//}	
					//}
					var data : db.Transaction.TCOrderInfos = t.data;
					if (data == null) continue;
					if (data.contractId == contract.id) return t;
					
					
				default : 
					continue;				
			}
		}
		
		return null;
		
	}
	
	public static function getPaymentTypes(group:db.Amap):Array<payment.Payment>{
		var out :Array<payment.Payment> = [];
		
		//populate with activated payment types.
		var all = payment.Payment.getPaymentTypes();
		if ( group.allowedPaymentsType == null ) return [];
		for ( t in group.allowedPaymentsType){
			
			var found = Lambda.find(all, function(a) return a.type == t);
			if (found != null) out.push(found);
		}
		return out;
	}
}