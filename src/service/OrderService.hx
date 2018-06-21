package service;
import Common;

/**
 * Order Service
 * @author web-wizard
 */
class OrderService
{
	
	public static function delete(order:db.UserContract) {

		var t = sugoi.i18n.Locale.texts;
		if (order.quantity == 0) {
			var user = order.user;
			var place = order.distribution.place;
			order.lock();
			order.delete();

			//Get the basket for this user
			var basket = db.Basket.get(user, place, order.distribution.date);

			//Get all the orders for this basket
			var orders = basket.getOrders();

			//Check there is no orders left to delete the related operation
			if( orders.length == 0 && place.amap.hasPayments())
			{
				var operation = db.Operation.findVOrderTransactionFor(order.distribution.getKey(), user, place.amap);
				operation.delete();
			}
		}
		else {
			throw new tink.core.Error(t._("Deletion non possible: quantity is not zero."));
		}

	}
	
}