package controller;
import Common;
import haxe.Utf8;
import sugoi.form.Form;
import sugoi.form.elements.Selectbox;
import sugoi.form.validators.EmailValidator;
import sugoi.tools.Utils;


class Member extends Controller
{

	public function new()
	{
		super();
		if (!app.user.canAccessMembership()) throw Redirect("/");
	}
	
	@logged
	@tpl('member/default.mtt')
	function doDefault(?args: { ?search:String, ?select:String } ) {
		checkToken();
		
		var browse:Int->Int->List<Dynamic>;
		var uids = db.UserAmap.manager.search($amap == app.user.getAmap(), false);
		var uids = Lambda.map(uids, function(ua) return ua.user.id);
		if (args != null && args.search != null) {
			
			//SEARCH			
			browse = function(index:Int, limit:Int) {
				var search = "%"+StringTools.trim(args.search)+"%";
				return db.User.manager.search( 
					($lastName.like(search) ||
					$lastName2.like(search) || 
					$address1.like(search) ||
					$address2.like(search) ||
					$firstName.like(search) ||
					$firstName2.like(search)					
					) && $id in uids , { orderBy:-id }, false);
			}
			view.search = args.search;
			
		}else if(args!=null && args.select!=null){
			
			//SELECTION
			
			switch(args.select) {
				case "nocontract":
					if (app.params.exists("csv")) {
						sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(db.User.getUsers_NoContracts()), ["firstName", "lastName", "email"], t._("Without contracts"));
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NoContracts(index, limit); }	
					}
				case "contract":
					
					if (app.params.exists("csv")) {
						sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(db.User.getUsers_Contracts()), ["firstName", "lastName", "email"], t._("With orders"));
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_Contracts(index, limit); }	
					}
					
				case "nomembership" :
					if (app.params.exists("csv")) {
						sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(db.User.getUsers_NoMembership()), ["firstName", "lastName", "email"], t._("Memberships to be renewed"));
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NoMembership(index, limit); }
					}
				case "newusers" :
					if (app.params.exists("csv")) {
						sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(db.User.getUsers_NewUsers()), ["firstName", "lastName", "email"], t._("Never connected"));
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NewUsers(index, limit); }
					}
				default:
					throw t._("Unknown selection");
			}
			view.select = args.select;
			
		}else {
			if (app.params.exists("csv")) {
				var headers = ["firstName", "lastName", "email","phone", "firstName2", "lastName2","email2","phone2", "address1","address2","zipCode","city"];
				sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(db.User.manager.search( $id in uids, {orderBy:lastName}, false)), headers, t._("Members"));
				return;
			}else {
				//default display
				browse = function(index:Int, limit:Int) {
					return db.User.manager.search( $id in uids, { limit:[index,limit], orderBy:lastName }, false);
				}
			}
		}
		
		var count = uids.length;
		var rb = new sugoi.tools.ResultsBrowser(count, (args.select!=null||args.search!=null)?1000:10, browse);
		view.members = rb;
		
		if (args.select == null || args.select != "newusers") {
			//count new users
			view.newUsers = db.User.getUsers_NewUsers().length;	
		}
		
		view.waitingList = db.WaitingList.manager.count($group == app.user.amap);
		
	}
	
	/**
	 * Move to waiting list
	 */
	function doMovetowl(u:db.User){
		
		var ua = db.UserAmap.get(u, app.user.amap, true);
		ua.delete();
		
		var wl = new db.WaitingList();
		wl.user = u;
		wl.group = app.user.amap;
		wl.insert();
		
		throw Ok("/member", u.getName() +" "+ t._("is now on waiting list.") );
		
		
	}
	
	/**
	 * Display waiting list
	 */
	@tpl('member/waiting.mtt')
	function doWaiting(?args:{?add:db.User,?remove:db.User}){
		
		if (args != null){
			
			if (args.add != null){
				//this user becomes member and is removed from waiting list
				var w = db.WaitingList.manager.select($user == args.add && $group == app.user.amap , true);
				
				if (db.UserAmap.get(args.add, app.user.amap, false) != null){
					throw Error("/member/waiting", t._("This user is already a member of your group.") );
				}
				
				var ua = new db.UserAmap();
				ua.amap = app.user.amap;
				ua.user = w.user;
				ua.insert();
				
				w.delete();
				
				throw Ok("/member/waiting", t._("Membership request accepted") );
				
			}else if (args.remove != null){
				
				//simply removed from waiting list
				var w = db.WaitingList.manager.select($user == args.remove && $group == app.user.amap , true);
				w.delete();
				
				throw Ok("/member/waiting", t._("membership request deleted") );
				
			}
			
		}
		
		
		view.waitingList = db.WaitingList.manager.search($group == app.user.amap,{orderBy:-date});
	}
	
	/**
	 * Send an invitation to a new member
	 */
	function doInviteMember(u:db.User){
		
		if (checkToken() ) {
			try {
				u.sendInvitation();
			}catch (e:String){
				if (e.indexOf("curl") >-1) {
					App.current.logError(e, haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					throw Error("/member", t._("An error occurred while sending emails, please retry"));
				}
			}
			throw Ok('/member/view/'+u.id, t._("Invitation sent.") );
		}
		
	}
	
	/**
	 * Invite 'never logged' users
	 */
	function doInvite() {
		
		if (checkToken()) {
			
			var users = db.User.getUsers_NewUsers();
			try{
				for ( u in users) {
					u.sendInvitation();
					Sys.sleep(0.2);
				}
			}catch (e:String){
				if (e.indexOf("curl") >-1) {
					App.current.logError(e, haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					throw Error("/member", t._("An error occurred while sending emails, please retry"));
				}
			}
			
			throw Ok('/member', t._("Congratulations, you just sent <b>::userLength::</b> invitations", {userLength:users.length}));
		}
		
	}
	
	
	@tpl("member/view.mtt")
	function doView(member:db.User) {
		
		view.member = member;
		var userAmap = db.UserAmap.get(member, app.user.amap);
		if (userAmap == null) throw Error("/member", t._("This person does not belong to your group"));
		
		view.userAmap = userAmap; 
		view.canLoginAs = (db.UserAmap.manager.count($userId == member.id) == 1 && app.user.isAmapManager()) || app.user.isAdmin(); 
		
		//orders
		var row = { constOrders:new Array<UserOrder>(), varOrders:new Map<String,Array<UserOrder>>() };
			
		//commandes fixes
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == app.user.amap && $endDate > DateTools.delta(Date.now(),-1000.0*60*60*24*30), false);
		var orders = member.getOrdersFromContracts(contracts);
		row.constOrders = db.UserContract.prepare(orders);
		
		//commandes variables groupées par date de distrib
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == app.user.amap && $endDate > DateTools.delta(Date.now(),-1000.0*60*60*24*30), false);
		var distribs = new Map<String,List<db.UserContract>>();
		for (c in contracts) {
			var ds = c.getDistribs();
			for (d in ds) {
				var k = d.date.toString().substr(0, 10);
				var orders = member.getOrdersFromDistrib(d);
				if (orders.length > 0) {
					if (!distribs.exists(k)) {
						distribs.set(k, orders);
					}else {
						
						var v = distribs.get(k);
						for ( o in orders  ) v.add(o);
						distribs.set(k, v);
					}	
				}
			}
		}
		for ( k in distribs.keys()){
			var d = distribs.get(k);
			var d2 = db.UserContract.prepare(d);
			row.varOrders.set(k,d2);
		}
		
		
		view.userContracts = row;
		checkToken(); //to insert a token in tpl
		
	}	
	
	/**
	 * Admin : Log in as this user for debugging purpose
	 * @param	user
	 * @param	amap
	 */	
	function doLoginas(member:db.User, amap:db.Amap) {
	
		if (!app.user.isAdmin()){
			if (!app.user.isAmapManager()) return;
			if (member.isAdmin()) return;
			if ( db.UserAmap.manager.count($userId == member.id) > 1 ) return;
			
		}
		
		App.current.session.setUser(member);
		App.current.session.data.amapId = amap.id;
		throw Redirect("/member/view/" + member.id );
	}
	
	@tpl('member/lastMessages.mtt')
	function doLastMessages(member:db.User){
		
		var out = new Array<{date:Date,subject:String,success:String,failure:String}>();
		var threeMonth = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30.5 * 3);
		
		for ( m in sugoi.db.BufferedMail.manager.search($remoteId == app.user.amap.id && $cdate > threeMonth, {limit:10, orderBy:-cdate})){
			
			var status : sugoi.mail.IMailer.MailerResult = m.status;
			
			if ( status!=null && status.get(member.email)!=null ){
				
				var r = m.getMailerResultMessage(member.email);
				out.push( {date:m.cdate,subject:m.title,success:r.success,failure:r.failure} );	
			}
			
		}
		view.emails = out;
	}
	
	/**
	 * Edit a Member
	 */
	@tpl('form.mtt')
	function doEdit(member:db.User) {
		
		if (member.isAdmin() && !app.user.isAdmin()) throw Error("/", t._("You cannot modify the account of an administrator"));
		
		var form = sugoi.form.Form.fromSpod(member);
		
		//cleaning		
		form.removeElement( form.getElement("rights") );
		form.removeElement( form.getElement("lang") );		
		form.removeElement( form.getElement("ldate") );
		form.removeElement( form.getElement("apiKey") );
		
		
		var isReg = member.isFullyRegistred();
		var groupNum = db.UserAmap.manager.count($userId == member.id);
		
		//an administrator can modify a user's email only if he's not member elsewhere
		if (groupNum > 1){			
			form.removeElementByName("email");
			form.removeElementByName("email2");
			app.session.addMessage(t._("For security reasons, you cannot modify the e-mail of this person because this person is a member of more than 1 group."));
		}
		
		//an administrator can modify a user's pass only if he's a not registred user.
		if (!isReg){
			app.session.addMessage(t._("This person did not define yet a password. You are exceptionaly authorized to do it. Please don't forget to tell this person."));
			form.getElement("pass").required = false;
		}else{
			form.removeElement( form.getElement("pass") );
		}
		
		if (form.checkToken()) {
			
			if (app.user.amap.flags.has(db.Amap.AmapFlags.PhoneRequired) && form.getValueOf("phone") == null ){
				throw Error("/member/edit/"+member.id, t._("Phone number is required in this group."));
			}
			
			
			//update model
			form.toSpod(member); 
			
			//check that the given emails are not already used elsewhere
			var sim = db.User.getSameEmail(member.email,member.email2);
			for ( s in sim) {				
				if (s.id == member.id) sim.remove(s);
			}
			if (sim.length > 0) {
				
				//Let's merge the 2 users if it has no orders.
				var id = sim.first().id;
				if (db.UserContract.manager.search( $userId == id || $userId2 == id , false).length == 0) {
					//merge
					member.merge( sim.first() );
					app.session.addMessage(t._("This e-mail was used by another user account. As this user account was not used, it has been merged into the current user account."));
					
				} else {
					var str = t._("Warning, this e-mail or this name already exists for another account : ");
					str += Lambda.map(sim, function(u) return "<a href='/member/view/" + u.id + "'>" + u.getCoupleName() + "</a>").join(",");
					str += " "+t._("These accounts can't be merged because the second account has orders");
					throw Error("/member/edit/" + member.id, str);	
				}
			}	
			
			if (!isReg) member.setPass(form.getValueOf("pass"));
			
			member.update();
			
			if (!App.config.DEBUG && groupNum == 1) {
				
				//warn the user that his email has been updated
				if (form.getValueOf("email") != member.email) {
					var m = new sugoi.mail.Mail();
					m.setSender(App.config.get("default_email"), t._("Cagette.net"));
					m.addRecipient(member.email);
					m.setSubject(t._("Change your e-mail in your account Cagette.net"));
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:app.user.getName() + t._(" just modified your e-mail in your account Cagette.net.<br/>Your e-mail is now:")+form.getValueOf("email")  } ) );
					App.sendMail(m);
					
				}
				if (form.getValueOf("email2") != member.email2 && member.email2!=null) {
					var m = new sugoi.mail.Mail();
					m.setSender(App.config.get("default_email"),"Cagette.net");
					m.addRecipient(member.email2);
					m.setSubject(t._("Change the e-mail of your account Cagette.net"));
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:app.user.getName() +t._(" just modified your e-mail in your account Cagette.net.<br/>Your e-mail is now:")+form.getValueOf("email2")  } ) );
					App.sendMail(m);
				}	
			}
			
			throw Ok('/member/view/'+member.id, t._("This member has beed updated"));
		}
		
		view.form = form;
		
	}
	
	/**
	 * Remove a user from this group
	 */
	function doDelete(user:db.User,?args:{confirm:Bool,token:String}) {
		
		if (checkToken()) {
			if (!app.user.canAccessMembership()) throw t._("You cannot do that.");
			if (user.id == app.user.id) throw Error("/member/view/" + user.id, t._("You cannot delete yourself."));
			if ( Lambda.count(user.getOrders(app.user.amap),function(x) return x.quantity>0) > 0 && !args.confirm) {
				throw Error("/member/view/"+user.id, t._("Warning, this account has orders. <a class='btn btn-default btn-xs' href='/member/delete/::userid::?token=::argstoken::&confirm=1'>Remove anyway</a>", {userid:user.id, argstoken:args.token}));
			}
		
			var ua = db.UserAmap.get(user, app.user.amap, true);
			if (ua != null) {
				ua.delete();
				throw Ok("/member", t._("::user:: has been removed from your group",{user:user.getName()}));
			}else {
				throw Error("/member", t._("This person does not belong to \"::amapname::\"", {amapname:app.user.amap.name}));
			}	
		}else {
			throw Redirect("/member/view/"+user.id);
		}
	}
	
	@tpl('form.mtt')
	function doMerge(user:db.User) {
		
		if (!app.user.canAccessMembership()) throw Error("/","Action interdite");
		
		view.title = t._("Merge an account with another one");
		view.text = t._("This action allows you to merge two accounts (when you have duplicates in the database for example).<br/>Contracts of account 2 will be moved to account 1, and account 2 will be deleted. Warning, it is not possible to cancel this action.");
		
		var form = new Form("merge");
		
		var members = app.user.amap.getMembers();
		var members = Lambda.array(Lambda.map(members, function(x) return { key:Std.string(x.id), value:x.getName() } ));
		var mlist = new Selectbox("member1", t._("Account 1"), members, Std.string(user.id));
		form.addElement( mlist );
		var mlist = new Selectbox("member2", t._("Account 2"), members);
		form.addElement( mlist );
		
		if (form.checkToken()) {
		
			var m1 = Std.parseInt(form.getElement("member1").value);
			var m2 = Std.parseInt(form.getElement("member2").value);
			var m1 = db.User.manager.get(m1,true);
			var m2 = db.User.manager.get(m2,true);
			
			//if (m1.amapId != m2.amapId) throw "ils ne sont pas de la même amap !";
			
			//on prend tout à m2 pour donner à m1			
			//change usercontracts
			var contracts = db.UserContract.manager.search($user==m2 || $user2==m2,true);
			for (c in contracts) {
				if (c.user.id == m2.id) c.user = m1;
				if (c.user2!=null && c.user2.id == m2.id) c.user2 = m1;
				c.update();
			}
			
			//group memberships
			var adh = db.UserAmap.manager.search($user == m2, true);
			for ( a in adh) {
				a.user = m1;
				a.update();
			}
			
			//change contacts
			var contacts = db.Contract.manager.search($contact==m2,true);
			for (c in contacts) {
				c.contact = m1;
				c.update();
			}
			//if (m2.amap.contact == m2) {
				//m1.amap.lock();
				//m1.amap.contact = m1;
				//m1.amap.update();
			//}
			
			m2.delete();
			
			throw Ok("/member/view/" + m1.id, t._("Both accounts have been merged"));
			
			
		}
		
		view.form = form;
		
	}
	
	
	@tpl('member/import.mtt')
	function doImport(?args: { confirm:Bool } ) {
		
		var step = 1;
		var request = Utils.getMultipart(1024 * 1024 * 4); //4mb
		
		//on recupere le contenu de l'upload
		var data = request.get("file");
		if ( data != null) {
			
			var csv = new sugoi.tools.Csv();
			csv.setHeaders([t._("Firstname"), t._("Lastname"), t._("E-mail"), t._("Mobile phone"), t._("Partner's firstname"), t._("Partner's lastname"), t._("Partner's e-mail"), t._("Partner's Mobile phone"), t._("Address 1"), t._("Address 2"), t._("Post code"), t._("City")]);
			
			//utf8 encode if needed
			try{
				if (!haxe.Utf8.validate(data)){
					data = haxe.Utf8.encode(data);
				}
			}catch (e:Dynamic){ }
			var unregistred = csv.importDatas(data);
			
			/*var checkEmail = function(email){
				if ( !sugoi.form.validators.EmailValidator.check(email) ) {
					throw Error("/member", t._("The email <b>::email::</b> is invalid, please update your CSV file",{email:email}) );
				}
			}*/

			//cleaning
			for ( user in unregistred.copy() ) {
				
				//check nom+prenom
				if (user[0] == null || user[1] == null) {
					throw Error("/member/import", t._("You must fill the name and the firstname of the person. This line is incomplete: ") + user);
				}
				if (user[2] == null) {
					throw Error("/member/import", t._("Each person must have an e-mail to be able to log in. ::user0:: ::user1:: don't have one. ", {user0:user[0], user1:user[1]}) +user);
				}
				//uppercase du nom
				if (user[1] != null) user[1] = user[1].toUpperCase();
				if (user[5] != null) user[5] = user[5].toUpperCase();
				//lowercase email
				if (user[2] != null){
					user[2] = user[2].toLowerCase();
					//checkEmail(user[2]);
				} 
				if (user[6] != null){
					user[6] = user[6].toLowerCase();
					//checkEmail(user[6]);
				} 
			}
			
			//utf-8 check
			for ( row in unregistred.copy()) {
				
				for ( i in 0...row.length) {
					var t = row[i];
					if (t != "" && t != null) {
						try{
							if (!Utf8.validate(t)) {
								t = Utf8.encode(t);	
							}
						}catch (e:Dynamic) {}
						row[i] = t;
					}
				}
			}
			
			//put already registered people in another list
			var registred = [];
			for (r in unregistred.copy()) {
				//var firstName = r[0];
				//var lastName = r[1];
				var email = r[2];

				//var firstName2 = r[4];
				//var lastName2 = r[5];
				var email2 = r[6];
				
				var us = db.User.getSameEmail(email, email2);
				
				if (us.length > 0) {
					unregistred.remove(r);
					registred.push(r);
				}
			}
			
			
			app.session.data.csvUnregistered = unregistred;
			app.session.data.csvRegistered = registred;
			
			view.data = unregistred;
			view.data2 = registred;
			step = 2;
		}
		
		
		if (args != null && args.confirm) {
			
			//import unregistered members
			var i : Iterable<Dynamic> = cast app.session.data.csvUnregistered;
			for (u in i) {
				if (u[0] == null || u[0] == "null" || u[0] == "") continue;
								
				var user = new db.User();
				user.firstName = u[0];
				user.lastName = u[1];
				user.email = u[2];
				if (user.email != null && user.email != "null" &&!EmailValidator.check(user.email)) {
					throw t._("The E-mail ::useremail:: is invalid, please modify your file", {useremail:user.email});
				}
				user.phone = u[3];
				
				user.firstName2 = u[4];
				user.lastName2 = u[5];
				user.email2 = u[6];
				if (user.email2 != null && user.email2 != "null" && !EmailValidator.check(user.email2)) {
					App.log(u);
					throw t._("The E-mail of the partner of ::userFirstName:: ::userLastName:: '::userEmail::' is invalid, please check your file", {userFirstName:user.firstName, userLastName:user.lastName, userEmail:user.email2});
				}
				user.phone2 = u[7];				
				user.address1 = u[8];
				user.address2 = u[9];
				user.zipCode = u[10];
				user.city = u[11];				
				user.insert();
				
				var ua = new db.UserAmap();
				ua.user = user;
				ua.amap = app.user.amap;
				ua.insert();
			}
			
			//import registered members
			var i : Iterable<Array<String>> = cast app.session.data.csvRegistered;
			for (u in i) {
				var email = u[2];
				var email2 = u[6];
				
				var us = db.User.getSameEmail(email, email2);
				var userAmaps = db.UserAmap.manager.search($amap == app.user.amap && $userId in Lambda.map(us, function(u) return u.id), false);
				
				//member exists but is not member of this group.
				if (userAmaps.length == 0) {					
					var ua = new db.UserAmap();
					ua.user = us.first();
					ua.amap = app.user.amap;
					ua.insert();
				}
			}
			
			view.numImported = app.session.data.csvUnregistered.length + app.session.data.csvRegistered.length;
			app.session.data.csvUnregistered = null;
			app.session.data.csvRegistered = null;
			
			step = 3;
		}
		
		if (step == 1) {
			//reset import when back to import page
			app.session.data.csvUnregistered = null;
			app.session.data.csvRegistered = null;
		}
		
		view.step = step;
	}
	
	@tpl("user/insert.mtt")
	public function doInsert() {
		
		if (!app.user.canAccessMembership()) throw Error("/", t._("Forbidden action"));
		
		var m = new db.User();
		var form = sugoi.form.Form.fromSpod(m);
		form.removeElement(form.getElement("lang"));
		form.removeElement(form.getElement("rights"));
		form.removeElement(form.getElement("pass"));	
		form.removeElement(form.getElement("ldate") );
		form.removeElement( form.getElement("apiKey") );
		form.addElement(new sugoi.form.elements.Checkbox("warnAmapManager", t._("Send an E-mail to the person in charge of the group"), true));
		form.getElement("email").addValidator(new EmailValidator());
		form.getElement("email2").addValidator(new EmailValidator());
		
		if (form.isValid()) {
			
			//check doublon de User et de UserAmap
			var userSims = db.User.getSameEmail(form.getValueOf("email"),form.getValueOf("email2"));
			view.userSims = userSims;
			var userAmaps = db.UserAmap.manager.search($amap == app.user.amap && $userId in Lambda.map(userSims, function(u) return u.id), false);
			view.userAmaps = userAmaps;
			
			if (userAmaps.length > 0) {
				//user deja enregistré dans cette amap
				throw Error('/member/view/' + userAmaps.first().user.id, t._("This person is already member of this group"));
				
			}else if (userSims.length > 0) {
				//des users existent avec ce nom , 
				//if (userSims.length == 1) {
					// si yen a qu'un on l'inserte
					var ua = new db.UserAmap();
					ua.user = userSims.first();
					ua.amap = app.user.amap;
					ua.insert();	
					throw Ok('/member/', t._("This person already had an account on Cagette.net, and is now member of your group."));
				/*}else {
					//demander validation avant d'inserer le userAmap
					//TODO
					throw Error('/member', t._("Not possible to add this person because there are already some people in the database having the same firstname and name. Please contact the administrator.")+userSims);
				}*/
				return;
			}else {
				
				if (app.user.amap.flags.has(db.Amap.AmapFlags.PhoneRequired) && form.getValueOf("phone") == null ){
					throw Error("/member/insert", t._("Phone number is required in this group."));
				}
				
				//insert user
				var u = new db.User();
				form.toSpod(u); 
				u.lang = app.user.lang;
				u.insert();
				
				//insert userAmap
				var ua = new db.UserAmap();
				ua.user = u;
				ua.amap = app.user.getAmap();
				ua.insert();	
				
				if (form.getValueOf("warnAmapManager") == "1") {
					var url = "http://" + App.config.HOST + "/member/view/" + u.id;
					var text = t._("::admin:: just keyed-in contact details of a new member: <br/><strong>::newMember::</strong><br/> <a href='::url::'>See contact details</a>",{admin:app.user.getName(),newMember:u.getCoupleName(),url:url});
					App.quickMail(
						app.user.getAmap().contact.email,
						app.user.amap.name +" - "+ t._("New member") + " : " + u.getCoupleName(),
						app.processTemplate("mail/message.mtt", { text:text } ) 
					);
				}
				
				throw Ok('/member/', t._("This person is now member of the group"));
				
			}
		}
		
		view.form = form;
	}
	
	
	/**
	 * user payments history
	 */
	@tpl('member/payments.mtt')
	function doPayments(m:db.User){
		
		db.Operation.updateUserBalance(m, app.user.amap);		
       var browse:Int->Int->List<Dynamic>;
		
		//default display
		browse = function(index:Int, limit:Int) {
			return db.Operation.getOperationsWithIndex(m,app.user.amap,index,limit,true);
		}
		
		var count = db.Operation.countOperations(m,app.user.amap);
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.rb = rb;
		view.member = m;
		view.balance = db.UserAmap.get(m, app.user.amap).balance;
		
		checkToken();
	}
	
	@tpl('member/balance.mtt')
	function doBalance(){
		view.balanced = db.UserAmap.manager.search($amap == app.user.amap && $balance == 0.0, false);
		view.credit = db.UserAmap.manager.search($amap == app.user.amap && $balance > 0, false);
		view.debt = db.UserAmap.manager.search($amap == app.user.amap && $balance < 0, false);
	}
	
}