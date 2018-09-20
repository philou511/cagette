package controller;
import Common;
/**
 * Base Cagette.net Controller
 * @author fbarbut
 */
class Controller extends sugoi.BaseController
{

	var t: sugoi.i18n.GetText;
	
	public function new() 
	{
		super();
		
		//gettext translator
		this.t = sugoi.i18n.Locale.texts;
		
	}

	function nav(id:String):Array<Link>{
		//trigger a "Nav" event
		var nav = new Array<Link>();
		var e = Nav(nav,id);
		app.event(e);
		return e.getParameters()[0];
	}
	

}