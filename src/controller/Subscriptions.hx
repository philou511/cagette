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
		var url = '/subscriptions/contract/${subscription.catalog.id}';
		try {
			SubscriptionService.deleteSubscription( subscription );
		} catch( error : tink.core.Error ) {
			throw Error( url , error.message );
		}
		throw Ok( url , 'La souscription a bien été supprimée.' );		
	}

}