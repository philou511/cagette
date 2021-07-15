package controller;


class Notifications extends Controller
{

	public function new()
	{
		super();
	}
	
	/**
	 * notifications page
	 */
	@logged
	@tpl("notifications/default.mtt")
	function doDefault() { }

}