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
			
			//create "order transactions" when orders have been made
			case MakeOrder(orders):
				
				if (orders.length == 0) return;

				var user = orders[0].user;
				var group = orders[0].product.contract.amap;
				
				//should not go further if group has not activated payements
				if (user==null || !group.hasPayments()) return;
				
				if (orders[0].product.contract.type == db.Contract.TYPE_VARORDER ){
					
					//find basket
					var basket = null;
					for ( o in orders) {
						if (o.basket != null) {
							basket = o.basket;
							break;
						}
					}
					
					// varying contract :
					//get all orders for the same place & date, in order to update related transaction.
					var k = orders[0].distribution.getKey();
					var allOrders = db.UserContract.getUserOrdersByMultiDistrib(k, user, group);	
					
					//existing transaction
					var existing = db.Operation.findVOrderTransactionFor( k , user, group);
					if (existing != null){
						db.Operation.updateOrderOperation(existing,allOrders,basket);	
					}else{
						db.Operation.makeOrderOperation(allOrders,basket);			
					}
					
					
					
				}else{
					
					// constant contract
					// create/update a transaction computed like $distribNumber * $price.
					var contract = orders[0].product.contract;
					
					var existing = db.Operation.findCOrderTransactionFor( contract , user);
					if (existing != null){
						db.Operation.updateOrderOperation(existing, contract.getUserOrders(user) );
					}else{
						db.Operation.makeOrderOperation( contract.getUserOrders(user) );
					}
					
					
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