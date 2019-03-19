package controller;
import db.Operation.OperationType;
import Common;
import service.OrderService;
using Lambda;

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
	public function doInsertPayment(user:db.User){
		
		if (!app.user.isContractManager()) throw Error("/", t._("Action forbidden"));	
		var t = sugoi.i18n.Locale.texts;
		
		var op = new db.Operation();
		op.user = user;
		op.date = Date.now();
		
		var f = new sugoi.form.Form("payement");
		f.addElement(new sugoi.form.elements.StringInput("name", t._("Label||label or name for a payment"), null, true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", t._("Date"), Date.now(), true));
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, app.user.amap);
		var out = [];
		for (paymentType in paymentTypes)
		{
			out.push({label: paymentType.name, value: paymentType.type});
		}
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), out, null, true));
		
		//related operation
		var unpaid = db.Operation.manager.search($user == user && $group == app.user.amap && $type != Payment ,{limit:20,orderBy:-date});
		var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
		f.addElement(new sugoi.form.elements.IntSelect("unpaid", t._("As a payment for :"), data, null, false));
		
		if (f.isValid()){
			f.toSpod(op);
			op.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			op.data = data;
			op.group = app.user.amap;
			op.user = user;
			
			if (f.getValueOf("unpaid") != null){
				var t2 = db.Operation.manager.get(f.getValueOf("unpaid"));
				op.relation = t2;
				if (t2.amount + op.amount == 0) {
					op.pending = false;
					t2.lock();
					t2.pending = false;
					t2.update();
				}
			}
			
			op.insert();
			
			service.PaymentService.updateUserBalance(user, app.user.amap);
			
			throw Ok("/member/payments/" + user.id, t._("Payment recorded") );
			
		}
		
		view.title = t._("Record a payment for ::user::",{user:user.getCoupleName()}) ;
		view.form = f;		
	}
	
	
	@tpl('form.mtt')
	public function doEdit(op:db.Operation){
		
		if (!app.user.canAccessMembership() || op.group.id != app.user.amap.id ) {
			throw Error("/member/payments/" + op.user.id, t._("Action forbidden"));		
		}
		
		if (op.getPaymentType() == "lemonway-ec") throw Error("/member/payments/"+op.user.id, t._("Editing a credit card payment is not allowed"));
		
		op.lock();
		
		var f = new sugoi.form.Form("payement");
		f.addElement(new sugoi.form.elements.StringInput("name", t._("Label||label or name for a payment"), op.name, true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), op.amount, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", t._("Date"), op.date, true));
		//f.addElement(new sugoi.form.elements.DatePicker("pending", t._("Confirmed"), !op.pending, true));
		//related operation
		var unpaid = db.Operation.manager.search( $user == op.user && $group == op.group && $type != Payment ,{limit:20,orderBy:-date});
		var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
		if (op.relation != null) data.push({label:op.relation.name,value:op.relation.id});
		f.addElement(new sugoi.form.elements.IntSelect("unpaid", t._("As a payment for :"), data, op.relation!=null ? op.relation.id : null, false));
		
		
		if (f.isValid()){
			f.toSpod(op);
			op.pending = false;
			
			if (f.getValueOf("unpaid") != null){
				var t2 = db.Operation.manager.get(f.getValueOf("unpaid"));
				op.relation = t2;
				if (t2.amount + op.amount == 0) {
					op.pending = false;
					t2.lock();
					t2.pending = false;
					t2.update();
				}
			}
			
			op.update();
			throw Ok("/member/payments/" + op.user.id, t._("Operation updated"));
		}
		
		view.form = f;
	}	
	
	/**
	 * Delete an operation
	 */
	public function doDelete(op:db.Operation){	
		if (!app.user.canAccessMembership() || op.group.id != app.user.amap.id ) throw Error("/member/payments/" + op.user.id, t._("Action forbidden"));	
		//cannot delete a bank card payment op	
		if (op.getPaymentType() == "lemonway-ec"){
			throw Error("/member/payments/" + op.user.id, t._("Deleting a credit card payment is not allowed"));
		} 
		//only an admin can delete an order op
		if((op.type == db.Operation.OperationType.VOrder || op.type == db.Operation.OperationType.COrder) && !app.user.isAdmin()){
			throw Error("/member/payments/" + op.user.id, t._("Action forbidden"));
		} 
		if (checkToken()){
			op.delete();
			throw Ok("/member/payments/" + op.user.id, t._("Operation deleted"));
		}
	}
	
	
	/**
	 * payment entry page
	 * @param	distribKey
	 */
	@tpl("transaction/pay.mtt")
	public function doPay() {

		view.category = 'home';

		var order : OrderInSession = app.session.data.order;
		if (order == null) throw Redirect("/");
		if (order.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		view.amount = order.total;		
		view.paymentTypes = service.PaymentService.getPaymentTypes(PCPayment, app.user.amap);
		view.allowMoneyPotWithNegativeBalance = app.user.amap.allowMoneyPotWithNegativeBalance;	
		view.futurebalance = db.UserAmap.get(app.user, app.user.amap).balance - order.total;
	}
	
	/**
	 * Use the money pot
	 */
	@tpl("transaction/moneypot.mtt")
	public function doMoneypot(){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;		
		if (tmpOrder == null) throw Redirect("/contract");
		if (tmpOrder.products.length == 0) throw Error("/", t._("Your cart is empty"));
		var futureBalance = db.UserAmap.get(app.user, app.user.amap).balance - tmpOrder.total;
		if (!app.user.amap.allowMoneyPotWithNegativeBalance && futureBalance < 0) {
			throw Error("/transaction/pay", t._("You do not have sufficient funds to pay this order with your money pot."));
		}
		
		try{
			//record order
			var orders = OrderService.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}

		view.amount = tmpOrder.total;
		view.balance = db.UserAmap.get(app.user, app.user.amap).balance;
	
	}

	/**
	 * Use on the spot payment
	 */
	@tpl("transaction/onthespot.mtt")
	public function doOnthespot()
	{
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;		
		if (tmpOrder == null) throw Redirect("/contract");
		if (tmpOrder.products.length == 0) throw Error("/", t._("Your cart is empty"));
		var futureBalance = db.UserAmap.get(app.user, app.user.amap).balance - tmpOrder.total;
		
		try{
			//record order
			var orders = OrderService.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);

			view.amount = tmpOrder.total;
			view.balance = db.UserAmap.get(app.user, app.user.amap).balance;

			var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);		
			
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){				
				//all orders are for the same multidistrib
				var name = t._("Payment on the spot for the order of ::date::", {date:view.hDate(d.date)});
				db.Operation.makePaymentOperation(app.user,app.user.amap, payment.OnTheSpotPayment.TYPE, tmpOrder.total, name, ops[0] );		
			}else{				
				//orders are for multiple distribs : create one payment
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.OnTheSpotPayment.TYPE, tmpOrder.total, t._("Payment on the spot"));			
			}
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}
		
	
	}

	/**
	 * pay by transfer
	 */
	@tpl("transaction/transfer.mtt")
	public function doTransfer(){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;	
		if (tmpOrder == null) throw Redirect("/contract");
		if (tmpOrder.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		//get a code
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);		
		var code = payment.Check.getCode(d.date, d.place, app.user);
		
		view.code = code;
		view.amount = tmpOrder.total;
		
		try{			
			//record order
			var orders = OrderService.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){
				//one multidistrib
				var name = t._("Transfer for the order of ::date::", {date:view.hDate(d.date)}) + " ("+code+")";
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Transfer.TYPE, tmpOrder.total, name, ops[0] );
			}else{
				//many distribs
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Transfer.TYPE, tmpOrder.total, t._("Bank transfer")+" ("+code+")" );			
			}
		}catch(e:tink.core.Error){
			throw Error("/transaction/pay/",e.message);
		}

	}

}