package controller;

import service.SubscriptionService;

/**
 * Member subscription controller
 */
class Subscriptions extends controller.Controller
{

    /**
	 * Create or update my CSA subscription 
	 */
	 @tpl("contract/order.mtt")
     function doContract( catalog : db.Catalog ) {
         view.catalog = catalog;
         view.userId = app.user.id;
 
         var sub = SubscriptionService.getCurrentOrComingSubscription(app.user,catalog);
         view.subscriptionId = sub==null ? null : sub.id;
     }

    /**
		the user deletes his subscription
	**/
	function doDelete(subscription:db.Subscription){
		if( subscription.user.id!=app.user.id ) throw Error( '/', t._('Access forbidden') );
		
		try {
			SubscriptionService.deleteSubscription( subscription );
		} catch( error : tink.core.Error ) {
			throw Error( '/subscriptions/contract/' + subscription.catalog.id, error.message );
		}
		throw Ok( '/' + subscription.catalog.id, 'La souscription a bien été supprimée.' );		
	}

}