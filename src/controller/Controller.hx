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

	public function checkIsLogged(){
		if(app.user==null) {
			throw new tink.core.Error(t._("You should be logged in to perform this action."));
		}
	}
	

}