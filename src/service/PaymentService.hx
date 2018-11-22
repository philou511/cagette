package service;
import Common;

/**
 * Payment Service
 * @author web-wizard
 */
class PaymentService
{
	/**
	 * Retuns an array of payment types depending on the use case
	 * @param context 
	 * @param group 
	 * @return Array<payment.PaymentType>
	 */
	public static function getPaymentTypes(context: String, ?group: db.Amap) : Array<payment.PaymentType>
	{
		var out : Array<payment.PaymentType> = [];

		switch(context)
		{
			case "All":
				var types = [
					new payment.Cash(),
					new payment.Check(),
					new payment.Transfer(),	
					new payment.MoneyPot(),
					new payment.OnTheSpotPayment(),						
				];
				var e = App.current.event(GetPaymentTypes({types:types}));
				out = switch(e) {
						case GetPaymentTypes(d): d.types;
						default : null;
					}


			case "GroupAdmin":
				var allPaymentTypes = getPaymentTypes("All");
				//Exclude On the spot payment
				var onTheSpot = Lambda.find(allPaymentTypes, function(x) return x.type == payment.OnTheSpotPayment.TYPE);
				allPaymentTypes.remove(onTheSpot);
				out = allPaymentTypes;


			//For the payment page
			case "Payment":
				var all = getPaymentTypes("All");
				if ( group.allowedPaymentsType == null ) return [];
				var onTheSpotPaymentTypes = [payment.Cash.TYPE, payment.Check.TYPE, payment.Transfer.TYPE];
				var hasOnTheSpotPaymentTypes = false;
				var onTheSpotPaymentType = new payment.OnTheSpotPayment();
				for ( paymentType in group.allowedPaymentsType )
				{
					var found = Lambda.find(all, function(a) return a.type == paymentType);
					if (found != null)  {
						if (Lambda.has(onTheSpotPaymentTypes, found.type))
						{
							hasOnTheSpotPaymentTypes = true;
							onTheSpotPaymentType.allowedPaymentTypes.push(found);
							continue; //On the spot payment types are excluded
						}
						out.push(found);
					}
				}
				if(hasOnTheSpotPaymentTypes)
				{
					out.push(onTheSpotPaymentType);
				}

			
			//For when a coordinator does a manual refund or adds manually a payment
			case "ManualEntry":
				//Exclude the MoneyPot payment
				var paymentTypesInAdmin = getPaymentTypes("GroupAdmin");
				var moneyPot = Lambda.find(paymentTypesInAdmin, function(x) return x.type == payment.MoneyPot.TYPE);
				paymentTypesInAdmin.remove(moneyPot);
				out = paymentTypesInAdmin;
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

	public static function unvalidateDistribution(distrib:db.Distribution) {

		for ( user in distrib.getUsers()){
			var basket = db.Basket.get(user, distrib.place, distrib.date);
			unvalidateBasket(basket);
		}
		//finally validate distrib
		distrib.lock();
		distrib.validated = false;
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

		return true;
	}

	public static function unvalidateBasket(basket:db.Basket) {

		if (basket == null || !basket.isValidated()) return false;
		
		//mark orders as paid
		var orders = basket.getOrders();
		for ( order in orders ){

			order.lock();
			order.paid = false;
			order.update();				
		}

		//validate order operation and payments
		var operation = basket.getOrderOperation(false);
		if (operation != null){

			operation.lock();
			operation.pending = true;
			operation.update();
			
			for ( payment in basket.getPayments()){

				if (!payment.pending){
					payment.lock();
					payment.pending = true;
					payment.update();
				}
			}

			var o = orders.first();
			updateUserBalance(o.user, o.distribution.place.amap);	
		}

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