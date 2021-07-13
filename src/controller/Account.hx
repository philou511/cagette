package controller;
import db.Subscription;
import service.OrderService;
import db.MultiDistrib;
import service.SubscriptionService;
import sugoi.form.Form;
import sugoi.form.elements.StringSelect;
import db.Operation;
import Common;
using Std;
import plugin.Tutorial;

class Account extends Controller
{

	public function new()
	{
		super();
	}
	
	/**
	 * "my account" page
	 */
	@logged
	@tpl("account/default.mtt")
	function doDefault() {

		var group =  app.user.getGroup();
		if (group!=null) {
			view.groupId = group.id;
		}

		//Create the list of links to change the language
		var langs = App.config.get("langs").split(";");
		var langNames = App.config.get("langnames").split(";");
		var i=0;
		var langLinks = "";
		for (lang in langs){
			langLinks += "<li><a href=\"?lang=" + langs[i] + "\">" + langNames[i] + "</a></li>";
			i++;
		}
		view.langLinks = langLinks;
		view.langText = langNames[langs.indexOf(app.session.lang)];

		//change account lang
		if (app.params.exists("lang") && app.user!=null){
			app.user.lock();
			app.user.lang = app.params.get("lang");
			app.user.update();
		}
	}

	/**
		Edit notifications.  Should work even if user is not logged in. ( link in emails footer )
	**/
	@tpl('account/editNotif.mtt')
	function doEditNotif(user:db.User,key:String){

		if (haxe.crypto.Sha1.encode(App.config.KEY+user.id) != key){
			throw Error("/","Lien invalide");
		}

		view.member = user;

		var form = db.User.getForm(user);
		form.removeElement(form.getElement("firstName"));
		form.removeElement(form.getElement("lastName"));
		form.removeElement(form.getElement("email"));
		form.removeElement(form.getElement("phone"));
		form.removeElement(form.getElement("firstName2"));
		form.removeElement(form.getElement("lastName2"));
		form.removeElement(form.getElement("email2"));
		form.removeElement(form.getElement("phone2"));
		form.removeElement(form.getElement("address1"));
		form.removeElement(form.getElement("address2"));
		form.removeElement(form.getElement("zipCode"));
		form.removeElement(form.getElement("city"));
		form.removeElement(form.getElement("birthDate"));
		form.removeElement(form.getElement("nationality"));
		form.removeElement(form.getElement("countryOfResidence"));
		
		if (form.isValid()) {
			var url = app.user==null ? "/user/" : "/user/choose?show=1";
			form.toSpod(user); 
			user.update();
			throw Ok(url, t._("Your account has been updated"));
		}
		
		view.form = form;
	}

	public function doQuitGroup(groupId:Int) {
		if (App.current.session.data.amapId == groupId) {
			App.current.session.data.amapId = null;
			Sys.println("Deleted");
		} 

		Sys.println("Not deleted");
	}
	
}