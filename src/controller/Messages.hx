package controller;
import db.Message;
import db.UserContract;
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
	function doDefault() {
			
		var form = new Form("msg");		
		
		var senderName = "";
		var senderMail = "";
		
		if (App.current.session.data.whichUser == 1 && app.user.email2 != null) {
			senderMail = app.user.email2;
			senderName = app.user.firstName2 + " " + app.user.lastName2;
			
		}else {				
			senderMail = app.user.email;
			senderName = app.user.firstName + " " + app.user.lastName;
		}
		
		var lists = getLists();
		form.addElement( new StringInput("senderName", t._("Sender name"),senderName,true));
		form.addElement( new StringInput("senderMail", t._("Sender E-Mail"),senderMail,true));
		form.addElement( new StringSelect("list", t._("Recipients"),lists,"1", true,null,"style='width:500px;'"));
		form.addElement( new StringInput("subject", t._("Subject:"),"",false,null,"style='width:500px;'") );
		form.addElement( new TextArea("text", t._("Message:"), "", false, null, "style='width:500px;height:350px;'") );
		
		if (form.checkToken()) {
			
			var listId = form.getElement("list").value;
			var dest = getSelection(listId);
			var mails = [];
			for ( d in dest) {
				if (d.email != null) mails.push(d.email);
				if (d.email2 != null) mails.push(d.email2);
			}
			
			//send mail confirmation link
			var e = new sugoi.mail.Mail();		
			e.setSubject(form.getValueOf("subject"));
			for ( x in mails) e.addRecipient(x);
			
			e.setSender(App.config.get("default_email"),form.getValueOf("senderName"));		
			e.setReplyTo(form.getValueOf("senderMail"),form.getValueOf("senderName"));
			//sender : default email ( explicitly tells that the server send an email on behalf of the user )
			//e.setHeader("Sender", App.config.get("default_email"));
			var text :String = form.getValueOf("text");
			var html = app.processTemplate("mail/message.mtt", { text:text,group:app.user.amap,list:getListName(listId) });		
			e.setHtmlBody(html);
		
			App.sendMail(e,app.user.getAmap(),listId,app.user);		
			
			//store message
			var lm = new db.Message();
			lm.amap =  app.user.amap;
			lm.recipients = Lambda.array(Lambda.map(e.getRecipients(), function(x) return x.email));
			lm.title = e.getSubject();
			lm.date = Date.now();
			lm.body = e.getHtmlBody();
			if (listId != null) lm.recipientListId = listId;
			lm.sender = app.user;
			lm.insert();

			
			throw Ok("/messages", t._("The message has been sent"));
		}
		
		view.form = form;
		
		if (app.user.isAmapManager()) {
			view.sentMessages = Message.manager.search($amap == app.user.amap && $recipientListId!=null, {orderBy:-date,limit:20}, false);
		}else {
			view.sentMessages = Message.manager.search($sender == app.user && $recipientListId!=null && $amap == app.user.amap , {orderBy:-date,limit:20}, false);	
		}
		
	}
	
	@tpl("messages/message.mtt")
	public function doMessage(msg:Message) {
		
		if (!app.user.isAmapManager() && msg.sender.id != app.user.id) throw Error("/", t._("Non authorized access"));
		
		view.list = getListName(msg.recipientListId);
		view.msg = msg;
		
		//make status easier to display
		var s = new Array<{email:String,success:String,failure:String}>();
		/*if (msg.status != null){
			for ( k in msg.status.keys()) {			
				var r = msg.getMailerResultMessage(k);				
				s.push({email:k,success:r.success,failure:r.failure});
			}
		}*/
	
		view.status = s;
		
	}
	
	function getLists() :FormData<String>{
		var out = [
			{value:'1', label: t._("Everyone")},
			{value:'2', label: t._("The board: persons in charge + contracts + memberships")},
		];
		
		out.push( { value:'3', label: t._("TEST: me + spouse") } );
		out.push( { value:'4', label: t._("Members without contract/order") } );
		if(app.user.amap.hasMembership()) out.push( { value:'5', label:t._("Memberships to be renewed")} );
		
		
		var contracts = db.Contract.getActiveContracts(app.user.amap,true);
		for ( c in contracts) {
			var label =  t._("Subscribers") + " " + c.toString();
			out.push({value:'c'+c.id,label:label});
		}
		return out ;
		
	}
	
	/**
	 * get list name from id
	 * @param	listId
	 */
	function getListName(listId:String) {
		var l = getLists();
		
		for (ll in l) {
			if (ll.value == listId) return ll.label;
		}
		
		return null;
		
	}
	
	function getSelection(listId:String) {
		if (listId.substr(0, 1) == "c") {
			//contrats
			var contract = Std.parseInt(listId.substr(1));
			
			var pids = db.Product.manager.search($contractId == contract, false);
			var pids = Lambda.map(pids, function(x) return x.id);
			var up = db.UserContract.manager.search($productId in pids, false);
			
			
			var users = [];
			for ( order in up) {
				if (!Lambda.has(users, order.user)) {
					users.push(order.user);					
				}
				if (order.user2 != null && !Lambda.has(users, order.user2)) {
					users.push(order.user2);
				}	
			}
			return users;
			
		}else {
			var out = [];
			switch(listId) {
			case "1": 		
				//tout le monde
				out =  Lambda.array(app.user.amap.getMembers());
					
			case "2":				
				var users = [];
				users.push(app.user.amap.contact);
				for ( c in db.Contract.manager.search($amap == app.user.amap)) {
					if (!Lambda.has(users, c.contact)) {
						users.push(c.contact);
					}
				}
				
				//ajouter les autres personnes ayant les droits Admin ou Gestion Adhérents ou Gestion Contrats
 				for (ua in Lambda.array(db.UserAmap.manager.search($rights != null && $amap == app.user.amap, false))) {
 					if (ua.hasRight(GroupAdmin) || ua.hasRight(Membership) || ua.hasRight(ContractAdmin())) {
 						if (!Lambda.has(users, ua.user)) users.push(ua.user);
 					}
 				}
				
				out = users;
			
			case "3":
				//moi
				return [app.user];
			case "4":
				return Lambda.array(db.User.getUsers_NoContracts());
			case "5":
				return Lambda.array(db.User.getUsers_NoMembership());
			}
			
			return out;
			
		}
	}
	
	

	
	
}