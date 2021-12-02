package controller;
import haxe.crypto.Md5;
import pro.db.CagettePro;
import pro.db.VendorStats;
import sugoi.Web;
import sugoi.form.Form;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.Input;
import sugoi.form.elements.IntInput;
import sugoi.form.elements.StringInput;
import sugoi.form.validators.EmailValidator;
import ufront.mail.*;

class User extends Controller
{
	public function new() 
	{
		super();
	}
	
	@tpl("user/default.mtt")
	function doDefault() {
		
	}
	
	
	@tpl("user/login.mtt")
	function doLogin() {
		
		if (App.current.user != null) {
			throw Redirect('/');
		}

		service.UserService.prepareLoginBoxOptions(view);

		view.sid = App.current.session.sid;
		
		//if its needed to redirect after login
		if (app.params.exists("redirect")){
			view.redirect = app.params.exists("redirect");
		}else if (getParam("__redirect")!=null) {
			view.redirect = getParam("__redirect");
		} else {
			view.redirect = '/';
		}
}

	/**
	 * Choose which group to connect to.
	 */
	@logged
	@tpl("user/choose.mtt")
	function doChoose(?args: { group:db.Group } ) {

		//home page
		app.breadcrumb = [];
		
		//need to check new ToS
		if(app.user.tosVersion != sugoi.db.Variable.getInt('tosVersion')){
			throw Redirect("/user/tos");
		} 
		
		var groups = app.user.getGroups();
		
		view.noGroup = true; //force template to not display current group
				
		if (args!=null && args.group!=null) {
			//select a group
			var which = app.session.data==null ? 0 : app.session.data.whichUser ;
			if(app.session.data==null) app.session.data = {};
			app.session.data.order = null;
			app.session.data.newGroup = null;
			app.session.data.amapId = args.group.id;
			app.session.data.whichUser = which;
			throw Redirect('/home');
		}
		
		view.groups = groups;
		view.wl = db.WaitingList.manager.search($user == app.user, false);
		
		#if plugins
		//vendor accounts
		var cagettePros = service.VendorService.getCagetteProFromUser(app.user);
		view.cagettePros = cagettePros;
		view.discovery = cagettePros.find(cp -> cp.type==Discovery)!=null;

		//list tmpVendor that are not certified yet
		view.tmpVendors = sys.db.Manager.cnx.request('select * from TmpVendor where userId = ${app.user.id} and certificationStatus < 2').results();
		// view.isBlocked = pro.db.PUserCompany.getUserCompanies(app.user).find(uc -> return uc.disabled) != null;

		//find free or invited vendor
		/*var vendor = db.Vendor.manager.select($email==app.user.email,false);
		if(vendor!=null){
			var vs = VendorStats.getOrCreate(vendor);
			if( vs.type == VTFree || vs.type == VTInvited || vs.type == VTInvitedPro ){
				view.isFreeVendor = true;
			}
		}*/	
		#end

		view.isGroupAdmin = app.user.getUserGroups().find(ug -> return ug.isGroupManager()) != null;		

	}
	
	function doLogout() {
		service.BridgeService.logout(App.current.user);
		Web.setHeader("Set-Cookie", "Authentication=; HttpOnly; Path=/; Max-Age=0");
		Web.setHeader("Set-Cookie", "Refresh=; HttpOnly; Path=/; Max-Age=0");
		Web.setHeader("Set-Cookie", "Auth_sid=; HttpOnly; Path=/; Max-Age=0");

		App.current.session.delete();

		throw Redirect('/');
	}
	
	/**
	 * Ask for password renewal by mail
	 * when password is forgotten
	 */
	@tpl("user/forgottenPassword.mtt")
	function doForgottenPassword(?key:String, ?u:db.User, ?definePassword:Bool){
		
		//STEP 1
		var step = 1;
		var error : String = null;
		var url = "/user/forgottenPassword";
		
		//ask for mail
		var askmailform = new Form("askemail");
		askmailform.addElement(new StringInput("email", t._("Please key-in your E-Mail address"),null,true));
	
		//change pass form
		var chpassform = new Form("chpass");
		
		var pass1 = new StringInput("pass1", t._("Your new password"),null,true);
		pass1.password = true;
		chpassform.addElement(pass1);
		
		var pass2 = new StringInput("pass2", t._("Again your new password"),null,true);
		pass2.password = true;
		chpassform.addElement(pass2);
		
		var uid = new IntInput("uid","uid", u == null?null:u.id);
		uid.inputType = ITHidden;
		chpassform.addElement(uid);
		
		if (askmailform.isValid()) {
			//STEP 2
			//send password renewal email
			step = 2;
			
			var email :String = askmailform.getValueOf("email");
			var user = db.User.manager.select(email == $email, false);
			//could be user 2
			if(user==null) user = db.User.manager.select(email == $email2, false);
			
			//user not found
			if (user == null) throw Error(url, t._("This E-mail is not linked to a known account"));
			
			//create token
			var token = haxe.crypto.Md5.encode("chp"+Std.random(1000000000));
			sugoi.db.Cache.set(token, user.id, 60 * 60 * 24 * 30);
			
			var m = new sugoi.mail.Mail();
			m.setSender(App.config.get("default_email"), t._("Cagette.net"));					
			m.setRecipient(email, user.getName());					
			m.setSubject( "["+App.config.NAME+"] : "+t._("Password change"));
			m.setHtmlBody( app.processTemplate('mail/forgottenPassword.mtt', { user:user, link:'http://' + App.config.HOST + '/user/forgottenPassword/'+token+"/"+user.id }) );
			App.sendMail(m);	
		}
		
		if (key != null && u!=null) {
			//check key and propose to change pass
			step = 3;
			
			if ( u.id == sugoi.db.Cache.get(key) ) {
				view.form = chpassform;
			}else {
				error = t._("Invalid request");
			}
		}
		
		if (chpassform.isValid()) {
			//change pass
			step = 4;
						
			if ( chpassform.getValueOf("pass1") == chpassform.getValueOf("pass2")) {
				
				var uid = Std.parseInt( chpassform.getValueOf("uid") );
				var user = db.User.manager.get(uid, true);
				var pass = chpassform.getValueOf("pass1");
				user.setPass(pass);
				user.update();

				var m = new sugoi.mail.Mail();
				m.setSender(App.config.get("default_email"), t._("Cagette.net"));					
				m.setRecipient(user.email, user.getName());					
				if(user.email2!=null) m.setRecipient(user.email2, user.getName());					
				m.setSubject( "["+App.config.NAME+"] : "+t._("New password confirmed"));
				var emails = [user.email];
				if(user.email2!=null) emails.push(user.email2);
				var params = {
					user:user,
					emails:emails.join(", "),
					password:pass,
					NAME:App.config.NAME
				}
				m.setHtmlBody( app.processTemplate('mail/newPasswordConfirmed.mtt', params) );
				App.sendMail(m);	
				
			}else {
				error = t._("You must key-in two times the same password");
			}
		}
			
		if (step == 1) {
			view.form = askmailform;
		}
		
		view.step = step;
		view.error = error;
		view.title = definePassword == null ? "Changement de mot de passe" : t._("Create a password for your account");

	}
	
	
	/**
	 * generate a custom key for transactionnal emails, valid during the current day
	 */
	//function getKey(m:db.User) {
		//return haxe.crypto.Md5.encode(App.config.get("key")+m.email+(Date.now().getDate())).substr(0,12);
	//}
	
	
	@logged
	@tpl("form.mtt")
	function doDefinePassword(?key:String, ?u:db.User){
		
		if (app.user.isFullyRegistred()) throw Error("/", t._("You already have a password"));

		var form = new Form("definepass");
		var pass1 = new StringInput("pass1", t._("Your new password"));
		var pass2 = new StringInput("pass2", t._("Again your new password"));
		pass1.password = true;
		pass2.password = true;
		form.addElement(pass1);
		form.addElement(pass2);
		
		if (form.isValid()) {
			
			if ( form.getValueOf("pass1") == form.getValueOf("pass2")) {
				
				app.user.lock();
				app.user.setPass(form.getValueOf("pass1"));
				app.user.update();
				throw Ok('/', t._("Congratulations, your account is now protected by a password."));
				
			}else {
				form.addError( t._("You must key-in two times the same password"));
			}
		}
		view.form = form;
		view.title = t._("Create a password for your account");
	}
	
	/**
	 * landing page when coming from an invitation
	 * @param	k
	 */
	public function doValidate(k:String ) {
		
		var uid = Std.parseInt(sugoi.db.Cache.get("validation" + k));
		if (uid == null || uid==0) throw Error('/user/login', t._("Your invitation is invalid or expired ($k)"));
		var user = db.User.manager.get(uid, true);
		
		var groups = user.getGroups();
		if(groups.length>0)	app.session.data.amapId = groups[0].id;
		
		sugoi.db.Cache.destroy("validation" + k);

		// Create change password token
		var token = haxe.crypto.Md5.encode("chp"+Std.random(1000000000));
		sugoi.db.Cache.set(token, user.id, 60 * 60 * 24 * 30);
	
		throw Ok('http://' + App.config.HOST + '/user/forgottenPassword/'+token+'/'+user.id+'/true', t._("Congratulations ::userName::, your account is validated!", {userName:user.getName()}) + " Définissez un mot de passe puis connectez-vous pour finaliser votre inscription.");
	}

	/**
		The user just registred or logged in, and want to be a member of this group
	**/
	function doJoingroup(){

		if(app.user==null) throw "no user";

		var group = App.current.getCurrentGroup();
		if(group==null) throw "no group selected";
		if(group.regOption!=db.Group.RegOption.Open) throw "this group is not open";

		/*var user = app.user;
		user.lock();
		user.flags.set(HasEmailNotif24h);
		user.flags.set(HasEmailNotifOuverture);
		user.update();*/
		db.UserGroup.getOrCreate(app.user,group);

		//warn manager by mail
		if(group.contact!=null){
			var url = "http://" + App.config.HOST + "/member/view/" + app.user.id;
			var text = t._("A new member joined the group without ordering : <br/><strong>::newMember::</strong><br/> <a href='::url::'>See contact details</a>",{newMember:app.user.getCoupleName(),url:url});
			App.quickMail(
				group.contact.email,
				group.name +" - "+ t._("New member") + " : " + app.user.getCoupleName(),
				app.processTemplate("mail/message.mtt", { text:text } ) 
			);	
		}

		throw Ok("/", t._("You're now a member of \"::group::\" ! You'll receive an email as soon as next order will open", {group:group.name}));
	}

	/**
		Quit a group.  Should work even if user is not logged in. ( link in emails footer )
	**/
	@tpl('account/quit.mtt')
	function doQuitGroup(group:db.Group,user:db.User,key:String){

		if (haxe.crypto.Sha1.encode(App.config.KEY+group.id+user.id) != key){
			// For legacy, key might still be using MD5
			if (haxe.crypto.Md5.encode(App.config.KEY+group.id+user.id) == key){
				key=haxe.crypto.Sha1.encode(App.config.KEY+group.id+user.id);
			} else {
				throw Error("/","Lien invalide");
			}
		}

		view.group = group;
		view.member = user;
		view.controlKey = key;
	}

	/**
		Quit a group without a userId.  Should work ONLY if the user is logged in. ( link in emails footer from Messaging Service )
	**/
	@tpl('account/quit.mtt')
	function doQuitGroupFromMessage(group:db.Group,key:String){

		if ( app.user == null && getParam('__redirect')==null ) {
			throw sugoi.ControllerAction.RedirectAction(Web.getURI()+"?__redirect="+Web.getURI());
		}

		if (haxe.crypto.Sha1.encode(App.config.KEY+group.id) != key){
			throw Error("/","Lien invalide");
		}

		view.groupId = group.id;
		if (app.user!=null) {
			view.userId = app.user.id;
			view.controlKey = haxe.crypto.Sha1.encode(App.config.KEY+group.id+app.user.id);
		}
	}

	@tpl('form.mtt')
	function doTos(){
		var tosVersion = sugoi.db.Variable.getInt("tosVersion");
		var form = new sugoi.form.Form("tos");
		form.addElement(new sugoi.form.elements.Checkbox("tos","J'accepte les nouvelles <a href='/cgu' target='_blank'>conditions générales d'utilisation</a>"));

		if(form.isValid() && form.getValueOf("tos")==true){
			app.user.lock();
			app.user.tosVersion = tosVersion;
			app.user.update();
			throw Redirect('/');
		}
		
		view.title = "Mise à jour des conditions générales d'utilisation de Cagette.net"+' ( v. $tosVersion )';
		view.form = form;
	}
	
}