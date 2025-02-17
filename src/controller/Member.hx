package controller;
import db.User.UserFlags;
import Common;
import db.Catalog;
import db.MultiDistrib;
import haxe.Http;
import haxe.Utf8;
import haxe.macro.Expr.Catch;
import payment.Check;
import service.OrderService;
import service.SubscriptionService;
import sugoi.form.Form;
import sugoi.form.elements.Selectbox;
import sugoi.form.validators.EmailValidator;
import sugoi.tools.Utils;

class Member extends Controller
{

	public function new()
	{
		super();
		if (!app.user.isAdmin() && !app.user.canAccessMembership()) throw Redirect("/");
	}

	@logged
	@tpl('member/default.mtt')
	function doDefault(?args: { ?search:String, ?list:String } ) {
		var group = app.user.getGroup();
		if (group==null) {
			throw Redirect("/");
		}
		
		// Set view.token to pass it to Neolithic componant
		checkToken();
	}
	
	@tpl("member/view.mtt")
	function doView(member:db.User) {
		var group = app.user.getGroup();
		if (group==null) {
			throw Redirect("/");
		}
		view.member = member;
		var userGroup = db.UserGroup.get(member, group);
		if (userGroup == null) throw Error("/member", t._("This person does not belong to your group"));
		
		view.userGroup = userGroup; 
		view.canLoginAs = (db.UserGroup.manager.count($userId == member.id) == 1 && app.user.isAmapManager()) || app.user.isAdmin(); 
		
		var now = Date.now();
		var from = new Date(now.getFullYear(), now.getMonth(), now.getDate()-7, 0, 0, 0);
		var to = DateTools.delta(from, 1000.0 * 60 * 60 * 24 * 28 * 3);
		var timeframe = new tools.Timeframe(from,to);
		var distribs = db.MultiDistrib.getFromTimeRange(app.user.getGroup(),timeframe.from,timeframe.to);

		//variable orders
		view.distribs = distribs;
		view.getUserOrders = function(md:db.MultiDistrib){
			return OrderService.prepare(md.getUserOrders(member,db.Catalog.TYPE_VARORDER));
		}

		//const orders subscriptions
		view.subscriptionService = service.SubscriptionService;
		view.subscriptionsByCatalog = SubscriptionService.getActiveSubscriptionsByCatalog( member, app.user.getGroup() );

		//notifications
		var notifications = [];
		var trans = App.getTranslationArray();
		for ( v in UserFlags.createAll()){
			var vs = Std.string(v);
			notifications.push({
				id: v,
				name:trans.get(vs) == null ? vs : trans.get(vs),
				active:member.flags.has(v)
			});

		}
		view.notifications = notifications;

		checkToken(); //to insert a token in tpl
	
	}


	/**
	 * Admin : Log in as this user for debugging purpose
	 */	
	 @tpl('member/loginAs.mtt')
	 function doLoginas(member:db.User) {
	
		if (!app.user.isAdmin()){
			if (!app.user.isAmapManager()) return;
			if (member.isAdmin()) return;
			if ( db.UserGroup.manager.count($userId == member.id) > 1 ) return;			
		}

		view.userId = member.id;
		view.groupId = App.current.session.data.amapId;

		App.current.session.setUser(member);
		App.current.session.data.amapId = null;
	}
	
	/**
	 * Edit a Member
	 */
	@tpl('form.mtt')
	function doEdit(member:db.User) {
		/*
		if (member.isAdmin() && !app.user.isAdmin()) throw Error("/", t._("You cannot modify the account of an administrator"));
		
		var form = db.User.getForm(member);
		form.removeElement( form.getElement("pass") );
		
		var groupNum = db.UserGroup.manager.count($userId == member.id);
		
		//an administrator can modify a user's email only if he's not member elsewhere
		if (groupNum > 1){			
			form.removeElementByName("email");
			form.removeElementByName("email2");
			app.session.addMessage(t._("For security reasons, you cannot modify the e-mail of this person because this person is a member of more than 1 group."));
		}
		
		if (form.checkToken()) {
			
			if (app.user.getGroup().flags.has(db.Group.GroupFlags.PhoneRequired) && form.getValueOf("phone") == null ){
				throw Error("/member/edit/"+member.id, t._("Phone number is required in this group."));
			}
			
			form.toSpod(member); 

			//check that the given emails are not already used elsewhere
			var sim = db.User.getSameEmail(member.email,member.email2);
			for ( s in sim) {				
				if (s.id == member.id) sim.remove(s);
			}
			if (sim.length > 0) {
				
				//Let's merge the 2 users if it has no orders.
				var id = sim.first().id;
				if (db.UserOrder.manager.search( $userId == id || $userId2 == id , false).length == 0) {
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
			
			member.update();
			
			if (!App.config.DEBUG && groupNum == 1) {
				
				//warn the user that his email has been updated
				if (form.getValueOf("email") != member.email) {
					var m = new sugoi.mail.Mail();
					m.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
					m.addRecipient(member.email);
					m.addRecipient(member.email2);
					m.setSubject("Changement de courriel sur votre compte "+App.current.getTheme().name);
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:app.user.getName() + "vient de modifier votre courriel dans votre compte "+App.current.getTheme().name+". <br/> Votre courriel est maintenant : "+form.getValueOf("email")  } ) );					App.sendMail(m);
					
				}
				if (form.getValueOf("email2") != member.email2 && member.email2!=null) {
					var m = new sugoi.mail.Mail();
					m.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
					m.addRecipient(member.email2);
					m.setSubject("Changement de courriel sur votre compte "+App.current.getTheme().name);
					m.setHtmlBody( app.processTemplate("mail/message.mtt", { text:app.user.getName() + "vient de modifier votre courriel dans votre compte "+App.current.getTheme().name+". <br/> Votre courriel est maintenant : "+form.getValueOf("email2")  } ) );
					App.sendMail(m);
				}	
			}
			
			throw Ok('/member/view/'+member.id, t._("This member has beed updated"));
		}
		
		view.form = form;
		*/
	}
	
	/**
	 * Remove a user from this group
	 */
	function doDelete(user:db.User,?args:{confirm:Bool,token:String}) {
		
		if (checkToken()) {
			if (!app.user.canAccessMembership()) throw t._("You cannot do that.");
			if (user.id == app.user.id) throw Error("/member/view/" + user.id, t._("You cannot delete yourself."));
			if ( Lambda.count(user.getOrders(app.user.getGroup()),function(x) return x.quantity>0) > 0 && !args.confirm) {
				throw Error("/member/view/"+user.id, t._("Warning, this account has orders. <a class='btn btn-default btn-xs' href='/member/delete/::userid::?token=::argstoken::&confirm=1'>Remove anyway</a>", {userid:user.id, argstoken:args.token}));
			}
		
			var ua = db.UserGroup.get(user, app.user.getGroup(), true);
			if (ua != null) {
				ua.delete();
				throw Ok("/member", t._("::user:: has been removed from your group",{user:user.getName()}));
			}else {
				throw Error("/member", t._("This person does not belong to \"::amapname::\"", {amapname:app.user.getGroup().name}));
			}	
		}else {
			throw Redirect("/member/view/"+user.id);
		}
	}
	
	/*@tpl('form.mtt')
	function doMerge(user:db.User) {
		
		if (!app.user.canAccessMembership()) throw Error("/","Action interdite");
		
		view.title = t._("Merge an account with another one");
		view.text = t._("This action allows you to merge two accounts (when you have duplicates in the database for example).<br/>Orders of account 2 will be moved to account 1, and account 2 will be deleted. Warning, it is not possible to cancel this action.");
		
		var form = new Form("merge");
		
		var members = app.user.getGroup().getMembers();
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
			var contracts = db.UserOrder.manager.search($user==m2 || $user2==m2,true);
			for (c in contracts) {
				if (c.user.id == m2.id) c.user = m1;
				if (c.user2!=null && c.user2.id == m2.id) c.user2 = m1;
				c.update();
			}
			
			//group memberships
			var adh = db.UserGroup.manager.search($user == m2, true);
			for ( a in adh) {
				a.user = m1;
				a.update();
			}
			
			//change contacts
			var contacts = db.Catalog.manager.search($contact==m2,true);
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
		
	}*/
	
	/**
	 * user payments history
	 */
	@tpl('member/payments.mtt')
	function doPayments(m:db.User){

		// if(!app.user.getGroup().hasShopMode()){
		// 	throw Redirect("/amap/payments/"+m.id);
		// }
		
		service.PaymentService.updateUserBalance(m, app.user.getGroup());		
    	var browse:Int->Int->List<Dynamic>;
		
		//default display
		browse = function(index:Int, limit:Int) {
			return db.Operation.getOperationsWithIndex(m,app.user.getGroup(),index,limit,true);
		}
		
		var count = db.Operation.countOperations(m,app.user.getGroup());
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.rb = rb;
		view.member = m;
		view.balance = db.UserGroup.get(m, app.user.getGroup()).balance;
		
		checkToken();
	}
	
	@tpl('member/balance.mtt')
	function doBalance(){

		if(app.params.get("refresh")=="1"){
			var group = app.user.getGroup();
			for(m in group.getMembers()){
				service.PaymentService.updateUserBalance(m, group);	
			}
		}

		view.balanced = db.UserGroup.manager.search($group == app.user.getGroup() && $balance == 0.0, false);
		view.credit = db.UserGroup.manager.search($group == app.user.getGroup() && $balance > 0, false);
		view.debt = db.UserGroup.manager.search($group == app.user.getGroup() && $balance < 0, false);
	}

	/**
		invoice for user
	**/
	@tpl('member/invoice.mtt')
	function doInvoice(m:db.User,md:db.MultiDistrib){
		
		//orders grouped by vendors
		var orders = service.OrderService.prepare(md.getUserOrders(m));
		var ordersByVendors = new Map<Int,Array<UserOrder>>();
		for( o in orders) {
			var or = ordersByVendors.get(o.product.vendorId);
			if(or==null) or = [];
			or.push(o);
			ordersByVendors.set(o.product.vendorId,or);
		}

		//grouped by VAT
		var ordersByVat = new Map<Int,{ht:Float,ttc:Float}>();
		for( o in orders){
			var key = Math.round(o.product.vat*100);
			if(ordersByVat[key]==null) ordersByVat[key] = {ht:0.0,ttc:0.0};
			var total = o.quantity * o.productPrice;
			ordersByVat[key].ttc += total;
			ordersByVat[key].ht += (total/(1+o.product.vat/100));
		}
		view.ordersByVat = ordersByVat;

		var basket = md.getUserBasket(m);
		var paymentOps = basket.getPaymentsOperations();

		view.member = m;
		view.ordersByVendors = ordersByVendors;
		view.md = md;
		view.getVendor = function(id) return db.Vendor.manager.get(id,false);
		view.paymentOps = paymentOps;


	}


	
}