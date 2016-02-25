package plugin;
import Common;

/**
 * Tutorials internal plugin
 */
class Tutorial extends plugin.PlugIn implements plugin.IPlugIn
{
	public function new() {
		super();	
		App.current.eventDispatcher.add(onEvent);		
	}
	
	/**
	 * catch events
	 */
	public function onEvent(e:Event) {
		//no need to continue if tutos are disabled
		if ( !App.current.user.flags.has(Tuto) ) return;

		switch(e) {
			
			case Page(uri):
				
				var ts = App.current.user.tutoState;
				if (ts == null) return;
				var tuto = Common.Data.TUTOS.get(ts.name);
				var step = tuto.steps[ts.step];
				if (step == null) return;
				
				//skip steps if action is "next"
				
				while (step.action.equals(TANext)) {
					ts.step++;
					step = tuto.steps[ts.step];
				}
				
				trace( "tuto active, listening to step="+ts.step );
				
				if (step.action.equals(TAPage(uri))) {
				
					var _uri = step.action.getParameters()[0];
					trace(""+_uri+"="+uri+" ?");
					if (_uri == uri) {
						trace("ok");
						var u = App.current.user;
						u.lock();
						
						if ( tuto.steps[ts.step+1] == null ) {
							//tuto finished
							u.tutoState = null;
							u.flags.unset(Tuto);
						}else {
							//next step
							u.tutoState.step = ts.step+1;	
						}
						
						u.update();
					}
					
					
				}
				
			default : 
		}
	}

	
	public static function all() {
		return Data.TUTOS;
	}
	
	public function getName() {
		return "Tutorial Plugin";
	}
	
	public function getController() { return null; }
	public function isInstalled() { return true; }
	public function install(){}
	
}