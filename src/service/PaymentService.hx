package service;
import Common;

/**
 * Payment Service
 * @author web-wizard
 */
class PaymentService
{
	/**
	 * Get all available payment types, including one from plugins
	 */
	public static function getAllPaymentTypes(){
		var types = [
			new payment.Cash(),
			new payment.Check(),
			new payment.Transfer(),	
			new payment.MoneyPot(),						
		];
		
		var e = App.current.event(GetPaymentTypes({types:types}));
		return switch(e){
			case GetPaymentTypes(d): d.types;
			default : null;
		}
		
	}

	public static function getAllowedPaymentTypes(group:db.Amap):Array<payment.Payment>{
		var out :Array<payment.Payment> = [];
		
		//populate with activated payment types.
		var all = getAllPaymentTypes();
		if ( group.allowedPaymentsType == null ) return [];
		for ( t in group.allowedPaymentsType){
			
			var found = Lambda.find(all, function(a) return a.type == t);
			if (found != null) out.push(found);
		}
		return out;
	}

	public static function getPaymentTypesForManualEntry(group:db.Amap){

		var out = [];
		var paymentTypes = [];
		var allowedPaymentTypes = service.PaymentService.getAllowedPaymentTypes(group);
		if ( !Lambda.exists(allowedPaymentTypes, function(obj) return obj.type == "moneypot" ) ) {
			paymentTypes = allowedPaymentTypes;
		}
		else {
			paymentTypes = service.PaymentService.getAllPaymentTypes();
		}
		for ( t in paymentTypes ){
			if(t.type != "moneypot") out.push({label:t.name,value:t.type});
		} 
		
		return out;
	}

	/**
	 * Auto validate a distribution.
	 * This is called by the hourly cron
	 *  
	 * @param distrib
	 */
	public static function validateDistribution(distrib:db.Distribution) {

		for ( user in distrib.getUsers()){
				
			var basket = db.Basket.get(user, distrib.place, distrib.date);
			validateBasket(basket);

		}
			
		//finally validate distrib
		distrib.lock();
		distrib.validated = true;
		distrib.update();
	}

	/**
	 * Auto validate a basket
	 *  
	 * @param basket
	 */
	public static function validateBasket(basket:db.Basket) {

		if (basket == null || basket.isValidated()) return false;
		
		//mark orders as paid
		var orders = basket.getOrders();
		for ( order in orders ){

			order.lock();
			order.paid = true;
			order.update();				
		}

		//validate order operation and payments
		var operation = basket.getOrderOperation(false);
		if (operation != null){

			operation.lock();
			operation.pending = false;
			operation.update();
			
			for ( payment in basket.getPayments()){

				if ( payment.pending){
					payment.lock();
					payment.pending = false;
					payment.update();
				}
			}

			var o = orders.first();
			updateUserBalance(o.user, o.distribution.place.amap);	
		}

		App.current.event(ValidateBasket(basket));

		return true;
	}


	/**
	 * update user balance
	 */
	public static function updateUserBalance(user:db.User,group:db.Amap){
		
		var ua = db.UserAmap.getOrCreate(user, group);
		var b = sys.db.Manager.cnx.request('SELECT SUM(amount) FROM Operation WHERE userId=${user.id} and groupId=${group.id} and !(type=2 and pending=1)').getFloatResult(0);
		b = Math.round(b * 100) / 100;
		ua.balance = b;
		ua.update();
	}
}