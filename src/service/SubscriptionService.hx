package service;
import Common;
import tink.core.Error;
using tools.DateTool;

/**
 * Subscription service
 * @author web-wizard
 */
class SubscriptionService
{

	/**
	 * Checks if dates are correct and if there is no other subscription for this user in that same time range
	 * @param subscription
	 */
	public static function isSubscriptionValid( subscription : db.Subscription ) : Bool {

		var view = App.current.view;
	
		if ( subscription.startDate == null || subscription.endDate == null ) {

			throw new Error( 'Cette souscription a des dates de début et de fin non définies.' );
		}
		if ( subscription.startDate.getTime() < subscription.catalog.startDate.getTime() || subscription.startDate.getTime() >= subscription.catalog.endDate.getTime() ) {

			throw new Error( 'La date de début de la souscription doit être comprise entre les dates de début et de fin du catalogue.' );
		}
		if ( subscription.endDate.getTime() <= subscription.catalog.startDate.getTime() || subscription.endDate.getTime() > subscription.catalog.endDate.getTime() ) {

			throw new Error( 'La date de fin de la souscription doit être comprise entre les dates de début et de fin du catalogue.' );
		}	

		var subscriptions1;
		var subscriptions2;	
		var subscriptions3;	
		//We are checking that there is no existing subscription with an overlapping time frame for the same user and catalog
		if ( subscription.id == null ) { //We need to check there the id as $id != null doesn't work in the manager.search

			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog 
															 && $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog
															 && $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog
															 && $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		}
		else {

			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		}
			
		if ( subscriptions1.length != 0 || subscriptions2.length != 0 || subscriptions3.length != 0 ) {

			throw new Error( 'Il y a déjà une souscription pour ce membre pendant la période choisie.' );
		}
 
		return true;

	}

	 /**
	  *  Creates a new subscription and prevents subscription overlapping and other checks
	  *  @return db.Subscription
	  */
	 public static function create( user : db.User, catalog : db.Catalog, startDate : Date, endDate : Date ) : db.Subscription {

		var subscription = new db.Subscription();
		subscription.user = user;
		subscription.catalog = catalog;
		subscription.startDate = startDate;
		subscription.endDate = endDate;

		// var obj = subscription;
		// for( field in Reflect.fields(obj) ) {
		// trace(" obj." + field + " = " + Reflect.field(obj, field));

		if ( isSubscriptionValid( subscription ) ) {

			subscription.insert();
		}

		return subscription;

	}


	 /**
	  *  Deletes a subscription if there is no orders that occurred in the past
	  *  @return db.Subscription
	  */
	 public static function delete( subscription : db.Subscription ) {

		if ( !hasPastOrders( subscription ) ) {

			//Delete all the orders for this subscription
			var subscriptionOrders = db.UserOrder.manager.search( $subscription == subscription, false );
			for ( order in subscriptionOrders ) {

				order.lock();
				order.delete();
			}
			//Delete the subscription
			subscription.lock();
			subscription.delete();
		}

	}

	/**
	 *  Checks whether there are orders with non zero quantity in the past
	 *  @param d - 
	 *  @return Bool
	 */
	public static function hasPastOrders( subscription : db.Subscription ) : Bool {

		//Check if there are orders for distributions in the past for this subscription
		var subscriptionOrders = db.UserOrder.manager.search( $subscription == subscription, false );
		var pastOrders = new Array<db.UserOrder>();
		for ( order in subscriptionOrders ) {

			if ( order.distribution.end.getTime() <= Date.now().getTime() ) {

				pastOrders.push(order);
			}
		}
		
		return pastOrders.length != 0;
		
	}

}