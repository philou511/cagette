package service;
import Common;

/**
 * Payment Service
 * @author web-wizard
 */
class PaymentService
{
	/**
	 * Auto validate a distribution this is called by the hourly cron
	 *  
	 * @param distrib
	 */
	public static function validateDistribution(distrib:db.Distribution) {

		for ( user in distrib.getUsers()){
				
			var basket = db.Basket.get(user, distrib.place, distrib.date);
			validateBasket(basket);

		}
			
		//finally validate distrib
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
		for ( order in basket.getOrders() ){

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
		}

		return true;
	}
}