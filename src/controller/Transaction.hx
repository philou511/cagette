package controller;
import db.Operation.OperationType;
import Common;
import service.OrderService;
using Lambda;
#if plugins
import mangopay.Mangopay;
import mangopay.Types;
#end
import sugoi.form.elements.NativeDatePicker.NativeDatePickerType;

/**
 * Transction controller
 * @author fbarbut
 */
class Transaction extends controller.Controller
{

	/**
	 * A manager inserts manually a payment
	 */
	@tpl('form.mtt')
	public function doInsertPayment( user : db.User, ?subscription : db.Subscription ) {
		
		if (!app.user.isContractManager()) throw Error("/", t._("Action forbidden"));	
		var t = sugoi.i18n.Locale.texts;

		var group = app.user.getGroup();
		var hasShopMode = group.hasShopMode();
		var returnUrl = '/member/payments/' + user.id;
		
		if ( !hasShopMode ) {

			if ( subscription != null ) {

				returnUrl = '/contractAdmin/subscriptions/payments/' + subscription.id;
			}
			else {

				returnUrl = '/amap/payments/' + user.id;
			}
			
			// '/contractAdmin/subscriptions/payments/' + operation.subscription.id
		}
		
		var op = new db.Operation();
		op.user = user;
		op.date = Date.now();
		
		var form = new sugoi.form.Form("payement");

		if ( !hasShopMode ) {

			if ( subscription != null ) {

				form.addElement( new sugoi.form.elements.Html( "subscription", '<div class="control-label" style="text-align:left;"> ${ subscription.catalog.name } - ${ subscription.catalog.vendor.name } </div>', 'Souscription' ) );
			}
			else {

				var activeSubscriptions = service.SubscriptionService.getActiveSubscriptions( user, group );
				var subscriptions = Lambda.map( activeSubscriptions, function( sub ) return { label : sub.catalog.name + ' - ' + sub.catalog.vendor.name, value : sub.id } ).array();
				form.addElement( new sugoi.form.elements.IntSelect( 'subscriptionId', 'Souscription', subscriptions, null, true ) );
			}


			// if ( args != null && args.s != null ) {

			// 	subscription = db.Subscription.manager.get( args.s );

			// 	if ( subscription != null ) {

			// 		form.addElement( new sugoi.form.elements.Html( "subscription", '<div class="control-label" style="text-align:left;"> ${ subscription.catalog.name } - ${ subscription.catalog.vendor.name } </div>', 'Souscription' ) );
			// 	}
			// }

			// TODO JB Ajouter erreur si subscription est à null
			// App.current.session.data.absencesReturnUrl = args.returnUrl;
			//RETURN /contractAdmin/subscriptions/payments/338
		}

		form.addElement(new sugoi.form.elements.StringInput("name", t._("Label||label or name for a payment"), null, true));
		form.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), null, true));
		form.addElement(new form.CagetteDatePicker("date", t._("Date"), Date.now(), NativeDatePickerType.date, true));
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, group);
		var out = [];
		for (paymentType in paymentTypes)
		{
			out.push({label: paymentType.name, value: paymentType.type});
		}
		form.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), out, null, true));
		
		//related operation
		if( hasShopMode ) {

			var unpaid = db.Operation.manager.search($user == user && $group == group && $type != Payment ,{limit:20,orderBy:-date});
			var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
			form.addElement(new sugoi.form.elements.IntSelect("unpaid", t._("As a payment for :"), data, null, false));
		}
		
		// new(name:String, label:String, ?value:T, ?required:Bool = false, ?display:Bool = false,  ?attributes:String = "")
		
		if (form.isValid()){
			form.toSpod(op);
			op.type = db.Operation.OperationType.Payment;			
			op.setPaymentData({type:form.getValueOf("Mtype")});
			op.group = group;
			op.user = user;
			
			if( hasShopMode ) {

				if (form.getValueOf("unpaid") != null){
					var t2 = db.Operation.manager.get(form.getValueOf("unpaid"));
					op.relation = t2;
					if (t2.amount + op.amount == 0) {
						op.pending = false;
						t2.lock();
						t2.pending = false;
						t2.update();
					}
				}
			}
			else {

				if( subscription == null ) {

					subscription = db.Subscription.manager.get( form.getValueOf( 'subscriptionId' ) );
				}

				op.subscription = subscription;
			}
			
			op.insert();
			service.PaymentService.updateUserBalance( user, group );

			throw Ok( returnUrl, t._("Payment recorded") );

		}
		
		view.title = t._("Record a payment for ::user::",{user:user.getCoupleName()}) ;
		view.form = form;
	}
	
	
	@tpl('form.mtt')
	public function doEdit( operation : db.Operation ) {

		var hasShopMode = operation.group.hasShopMode();
		var returnUrl = '/member/payments/' + operation.user.id;

		if ( !hasShopMode ) {

			App.current.session.data.returnUrl = '/contractAdmin/subscriptions/payments/' + operation.subscription.id;
			returnUrl = App.current.session.data.returnUrl;
			
			// '/contractAdmin/subscriptions/payments/' + operation.subscription.id
		}
		
		if ( !app.user.canAccessMembership() || operation.group.id != app.user.getGroup().id ) {

			throw Error( returnUrl, t._("Action forbidden") );
		}

		if( !hasShopMode && operation.subscription == null ) {

			throw Error( '/', 'Cette opération n\'est rattachée à aucune souscription' );
		}
		
		App.current.event( PreOperationEdit( operation ) );
		
		operation.lock();
		
		var form = new sugoi.form.Form("payement");
		form.addElement(new sugoi.form.elements.StringInput("name", t._("Label||label or name for a payment"), operation.name, true));
		form.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), operation.amount, true));
		form.addElement(new form.CagetteDatePicker("date", t._("Date"), operation.date, NativeDatePickerType.date, true));
		//form.addElement(new sugoi.form.elements.DatePicker("pending", t._("Confirmed"), !operation.pending, true));
		//related operation
		if ( hasShopMode ) {

			var unpaid = db.Operation.manager.search( $user == operation.user && $group == operation.group && $type != Payment ,{limit:20,orderBy:-date});
			var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
			if (operation.relation != null) data.push({label:operation.relation.name,value:operation.relation.id});
			form.addElement(new sugoi.form.elements.IntSelect("unpaid", t._("As a payment for :"), data, operation.relation!=null ? operation.relation.id : null, false));
		}
		
		if ( form.isValid() ) {

			form.toSpod( operation );
			operation.pending = false;
			
			if( hasShopMode ) {

				if ( form.getValueOf("unpaid") != null ) {

					var t2 = db.Operation.manager.get(form.getValueOf("unpaid"));
					operation.relation = t2;
					if (t2.amount + operation.amount == 0) {
						operation.pending = false;
						t2.lock();
						t2.pending = false;
						t2.update();
					}
				}
			}

			operation.update();
			service.PaymentService.updateUserBalance( operation.user, operation.group );

			throw Ok( returnUrl, t._("Operation updated"));
			
		}
		
		view.form = form;
	}
	
	/**
	 * Delete an operation
	 */
	public function doDelete( operation : db.Operation ) {

		var hasShopMode = operation.group.hasShopMode();

		var returnUrl = '/member/payments/' + operation.user.id;

		if ( !hasShopMode ) {

			App.current.session.data.returnUrl = '/contractAdmin/subscriptions/payments/' + operation.subscription.id;
			returnUrl = App.current.session.data.returnUrl;
		}

		if( !hasShopMode && operation.subscription == null ) {

			throw Error( '/', 'Cette opération n\'est rattachée à aucune souscription' );
		}

		if ( !app.user.canAccessMembership() || operation.group.id != app.user.getGroup().id ) throw Error("/member/payments/" + operation.user.id, t._("Action forbidden"));	
		
		App.current.event( PreOperationDelete( operation ) );

		//only an admin can delete an order op
		if( ( operation.type == db.Operation.OperationType.VOrder || operation.type == db.Operation.OperationType.SubscriptionTotal ) && !app.user.isAdmin() ) {

			throw Error( returnUrl, t._("Action forbidden"));
		}

		if ( checkToken() ) {

			operation.delete();
			service.PaymentService.updateUserBalance( operation.user, operation.group );
			
			throw Ok( returnUrl, t._("Operation deleted") );
			
		}
	}
	
	
	/**
	 * Payment entry point
	 */
	@tpl("transaction/pay.mtt")
	public function doPay(tmpBasket:db.TmpBasket) {

		view.category = 'home';
		
		if (tmpBasket == null) throw Error("Basket is null");
		tmpBasket.lock();
		if (tmpBasket.data.products.length == 0) throw Error("/", t._("Your cart is empty"));

		//case where the user just logged in
		if(tmpBasket.user==null){
			tmpBasket.user = app.user;
			tmpBasket.update();
		}
		
		var total = tmpBasket.getTotal();
		view.amount = total;		
		view.tmpBasket = tmpBasket;
		view.paymentTypes = service.PaymentService.getPaymentTypes(PCPayment, app.user.getGroup());
		view.allowMoneyPotWithNegativeBalance = app.user.getGroup().allowMoneyPotWithNegativeBalance;	
		view.futurebalance = db.UserGroup.get(app.user, app.user.getGroup()).balance - total;
	}

	@tpl("transaction/tmpBasket.mtt")
	public function doTmpBasket(tmpBasket:db.TmpBasket,?args:{cancel:Bool,confirm:Bool}){

		if(args!=null){
			if(args.cancel){
				tmpBasket.lock();
				tmpBasket.delete();
				throw Ok("/",t._("You basket has been canceled"));
			}else if(args.confirm){				
				throw Redirect("/shop/validate/"+tmpBasket.id);				
			}
		}

		
		#if plugins
		//MANGOPAY : search for "unlinked" confirmed payIns on Mangopay
		if(mangopay.MangopayPlugin.checkTmpBasket(tmpBasket)!=null){
			throw Ok("/home","Votre paiement a été pris en compte et votre commande a bien été enregistrée.");
		}
		#end

		view.tmpBasket = tmpBasket;		
	}
	
	/**
	 * Use the money pot
	 */
	@tpl("transaction/moneypot.mtt")
	public function doMoneypot(tmpBasket:db.TmpBasket){

		if (tmpBasket == null) throw Redirect("/contract");
		if (tmpBasket.data.products.length == 0) throw Error("/", t._("Your cart is empty"));
		var total = tmpBasket.getTotal();
		var futureBalance = db.UserGroup.get(app.user, app.user.getGroup()).balance - total;
		if (!app.user.getGroup().allowMoneyPotWithNegativeBalance && futureBalance < 0) {
			throw Error("/transaction/pay", t._("You do not have sufficient funds to pay this order with your money pot."));
		}
		
		try{
			//record order
			var orders = OrderService.confirmTmpBasket(tmpBasket);
			if(orders.length==0) throw Error('/home',"Votre panier est vide.");
			var ops = service.PaymentService.onOrderConfirm(orders);
			
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}

		view.amount = total;
		view.balance = db.UserGroup.get(app.user, app.user.getGroup()).balance;
	
	}

	/**
	 * Use on the spot payment
	 */
	@tpl("transaction/onthespot.mtt")
	public function doOnthespot(tmpBasket:db.TmpBasket)
	{
		if (tmpBasket == null) throw Redirect("/contract");
		if (tmpBasket.data.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		try{
			//record order
			var orders = OrderService.confirmTmpBasket(tmpBasket);
			if(orders.length==0) throw Error('/home',"Votre panier est vide.");
			var orderOps = service.PaymentService.onOrderConfirm(orders);
			var total = tmpBasket.getTotal();

			view.amount = total;
			//var futureBalance = db.UserGroup.get(app.user, app.user.getGroup()).balance - total;
			view.balance = db.UserGroup.get(app.user, app.user.getGroup()).balance;

			var date = tmpBasket.multiDistrib.getDate();		
			
			//all orders are for the same multidistrib
			var name = t._("Payment on the spot for the order of ::date::", {date:view.hDate(date)});
			service.PaymentService.makePaymentOperation(app.user,app.user.getGroup(), payment.OnTheSpotPayment.TYPE, total, name, orderOps[0] );	
			
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}
		
	
	}

	/**
	 * Pay by transfer
	 */
	@tpl("transaction/transfer.mtt")
	public function doTransfer(tmpBasket:db.TmpBasket){
		
		if (tmpBasket == null) throw Redirect("/contract");
		if (tmpBasket.data.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		var md = tmpBasket.multiDistrib;
		var date = md.getDate();	
		var total = tmpBasket.getTotal();
		var code = payment.Check.getCode(date, md.getPlace(), app.user);
		
		view.code = code;
		view.amount = total;
		
		try{			
			//record order
			var orders = OrderService.confirmTmpBasket(tmpBasket);
			if(orders.length==0) throw Error('/home',"Votre panier est vide.");
			var orderOps = service.PaymentService.onOrderConfirm(orders);
			
			var name = t._("Transfer for the order of ::date::", {date:view.hDate(date)}) + " ("+code+")";
			service.PaymentService.makePaymentOperation(app.user,app.user.getGroup(),payment.Transfer.TYPE, total, name, orderOps[0] );

			
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}

	}

}