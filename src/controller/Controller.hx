package controller;

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
	

}