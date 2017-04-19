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