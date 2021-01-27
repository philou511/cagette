package controller;
import db.Catalog;
import db.Message;
import db.UserOrder;
import sugoi.form.ListData;
import sugoi.form.elements.*;
import sugoi.form.Form;

class Messages extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.canAccessMessages()) throw Redirect("/");
	}
	
	@tpl("messages/default.mtt")
	function doDefault() {}
	
	public function doMessage(msg:Message) {
		throw Redirect('/messages');
	}
	
}