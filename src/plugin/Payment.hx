package plugin;
import Common;

/**
 * Payment internal plugin
 * 
 */
class Payment extends plugin.PlugIn implements plugin.IPlugIn
{
	public function new() {
		super();	
		App.current.eventDispatcher.add(onEvent);		
	}
	
	/**
	 * catch events
	 */
	public function onEvent(e:Event) {
		
		switch(e) {
			
			//orders have been made
			case MakeOrder(orders):
				
				var user = orders[0].user;
				var group = orders[0].product.contract.amap;
					
				
				if (orders[0].product.contract.type == db.Contract.TYPE_VARORDER ){
					
					var basket = null;
					for ( o in orders) {
						if (o.basket != null) {
							basket = o.basket;
							break;
						}
					}
					
					// varying contract :
					//get all orders for the same place & date, in order to update related transaction.
					var date = orders[0].distribution.date;
					var place = orders[0].distribution.place;
					
					var dkey = date.toString().substr(0, 10) + "|" + place.id;
					var allOrders = db.UserContract.getUserOrdersByMultiDistrib(dkey, user, group);		
					//delete existing transaction
					var existing = db.Transaction.findVOrderTransactionFor( dkey , user, group);
					if (existing != null){
						existing.delete();
					}
					db.Transaction.makeOrderTransaction(allOrders,basket);		
					
				}else{
					
					// constant contract
					// create/update a transaction computed like $distribNumber * $price.
					var contract = orders[0].product.contract;
					
					var existing = db.Transaction.findCOrderTransactionFor( contract , user);
					if (existing != null){
						existing.delete();
					}
					db.Transaction.makeOrderTransaction( contract.getUserOrders(user) );
					
				}
				
				

			default : 
		}
	}

	
	
	public function getName() {
		return "Payment Plugin";
	}
	
	public function getController() { return null; }
	public function isInstalled() { return true; }
	public function install(){}
	
}