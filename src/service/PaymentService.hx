package service;
import Common;

enum PaymentContext{
	PCAll;
	PCGroupAdmin;
	PCPayment;
	PCManualEntry;
}

/**
 * Payment Service
 * @author web-wizard,fbarbut
 */
class PaymentService
{
	/**
	 * Retuns an array of payment types depending on the use case
	 * @param context 
	 * @param group 
	 * @return Array<payment.PaymentType>
	 */
	public static function getPaymentTypes(context: PaymentContext, ?group: db.Amap) : Array<payment.PaymentType>
	{
		var out : Array<payment.PaymentType> = [];

		switch(context)
		{
			case PCAll:
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


			case PCGroupAdmin:
				var allPaymentTypes = getPaymentTypes(PCAll);
				//Exclude On the spot payment
				var onTheSpot = Lambda.find(allPaymentTypes, function(x) return x.type == payment.OnTheSpotPayment.TYPE);
				allPaymentTypes.remove(onTheSpot);
				out = allPaymentTypes;


			//For the payment page
			case PCPayment:
				if ( group.allowedPaymentsType == null ) return [];
				var onTheSpotPaymentTypes = payment.OnTheSpotPayment.getPaymentTypes();
				var hasOnTheSpotPaymentTypes = false;
				var onTheSpotPaymentType = new payment.OnTheSpotPayment();
				var all = getPaymentTypes(PCAll);
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
			case PCManualEntry:
				//Exclude the MoneyPot payment
				var paymentTypesInAdmin = getPaymentTypes(PCGroupAdmin);
				var moneyPot = Lambda.find(paymentTypesInAdmin, function(x) return x.type == payment.MoneyPot.TYPE);
				paymentTypesInAdmin.remove(moneyPot);
				out = paymentTypesInAdmin;
		}

		return out;
	}


	/**
	 * Returns all the payment types that are on the spot and that are allowed for this group
	 * @param group 
	 * @return Array<payment.PaymentType>
	 */
	public static function getOnTheSpotAllowedPaymentTypes(group: db.Amap) : Array<payment.PaymentType>
	{
		if ( group.allowedPaymentsType == null ) return [];
		var onTheSpotAllowedPaymentTypes : Array<payment.PaymentType> = [];
		var onTheSpotPaymentTypes = payment.OnTheSpotPayment.getPaymentTypes();
		var all = getPaymentTypes(PCAll);
		for (paymentType in onTheSpotPaymentTypes)
		{
			if (Lambda.has(group.allowedPaymentsType, paymentType))
			{
				var found = Lambda.find(all, function(a) return a.type == paymentType);
				if (found != null) 
				{
					onTheSpotAllowedPaymentTypes.push(found);
				}			
			}
		}
	
		return onTheSpotAllowedPaymentTypes;
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

		//This will throw an error if for example there are pending payments of type on the spot
		basket.canBeValidated();
		
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
			
			for ( payment in basket.getPaymentsOperations()){

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
			
			for ( payment in basket.getPaymentsOperations()){

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


	public static function getPaymentInfosString(group:db.Amap):String {
		var out = "";
		var allowedPaymentTypes = getPaymentTypes(PCPayment,group);
		out = Lambda.map(allowedPaymentTypes,function(m) return m.name).join(", ");
		return out;
	}

	/**
		Get multidistrib turnover by payment type
	**/
	public static function getMultiDistribTurnoverByPaymentType(md:db.MultiDistrib):Map<String,{ht:Float,ttc:Float}>{
		var out = new Map<String,{ht:Float,ttc:Float}>();

		/*for( b in md.getBaskets()){
			for( op in b.getPaymentsOperations()){
				
			}
		}*/
		return out;
	}
}