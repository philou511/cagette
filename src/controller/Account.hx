package controller;
import sugoi.form.Form;

class Account extends Controller
{

	public function new()
	{
		super();
		
	}
	
	
	function doDefault() {
		
	}
	
		
	
	
	@tpl('form.mtt')
	function doEdit() {
		
		var form = sugoi.form.Form.fromSpod(app.user);
		//form.removeElement(form.getElement("amapId"));
		form.removeElement(form.getElement("lang"));
		form.removeElement(form.getElement("pass"));
		form.removeElement(form.getElement("rights"));
		form.removeElement(form.getElement("cdate"));
		form.removeElement(form.getElement("ldate"));
		
		if (form.isValid()) {
			
			if (app.user.id != form.getValueOf("id")) {
				throw "access forbidden";
			}
			var admin = app.user.isAdmin();
			
			form.toSpod(app.user); 
			
			//check email is valid
			if (!sugoi.form.validators.EmailValidator.check(app.user.email)){
				throw Error("/account/edit",'Email "${app.user.email}" invalide');
			}
			
			if (app.user.email2!=null && !sugoi.form.validators.EmailValidator.check(app.user.email2)){
				throw Error("/account/edit",'Email "${app.user.email2}" invalide');
			}
			
			if (!admin) { app.user.rights.unset(Admin); }
			
			app.user.update();
			throw Ok('/contract','Votre compte a été mis à jour');
		}
		
		view.form = form;
		view.title = "Modifier mon compte";
	}
	
	function doQuit(){
		
		if (checkToken()){
			
			var name = app.user.amap.name;
			
			
			var ua = db.UserAmap.get(app.user, app.user.amap,true);
			ua.delete();
			
			App.current.session.data.amapId = null;
			throw Ok("/user/choose?show=1", "Vous avez quitté le groupe "+name);
			
		}
		
	}
	
	
	
}