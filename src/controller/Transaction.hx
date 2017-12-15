package controller;
import db.Operation.OperationType;
import Common;
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
		var data = [];
		for ( t in db.Operation.getPaymentTypes(app.user.amap) ) data.push({label:t.name,value:t.type});
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), data, null, true));
		
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
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
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
	
	public function doDelete(op:db.Operation){	
		if (!app.user.canAccessMembership() || op.group.id != app.user.amap.id ) throw Error("/member/payments/" + op.user.id, t._("Action forbidden"));		
		
		if (checkToken()){
			op.delete();
			throw Ok("/member/payments/" + op.user.id, t._("Operation deleted"));
		}
	}
	
	
	/**
	 * payement entry page
	 * @param	distribKey
	 */
	@tpl("transaction/pay.mtt")
	public function doPay(){

		var order : OrderInSession = app.session.data.order;
		if (order == null) throw Redirect("/");
		if (order.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		view.amount = order.total;		
		view.paymentTypes = db.Operation.getPaymentTypes(app.user.amap);		
	}
	
	/**
	 * pay by check
	 */
	@tpl("transaction/check.mtt")
	public function doCheck(){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;	
		if (tmpOrder == null) throw Redirect("/contract");
		if (tmpOrder.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		//get a code
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);		
		var code = payment.Check.getCode(d.date, d.place, app.user);
		
		view.code = code;
		view.amount = tmpOrder.total;
		
		//if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){				
				//all orders are for the same multidistrib
				var name = t._("Check for the order of ::date::", {date:view.hDate(d.date)}) + " ("+code+")";
				db.Operation.makePaymentOperation(app.user,app.user.amap, payment.Check.TYPE, tmpOrder.total, name, ops[0] );		
			}else{				
				//orders are for multiple distribs : create one payment
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Check.TYPE, tmpOrder.total, t._("Check") + " ("+code+")" );			
			}
			

			//throw Ok("/contract", t._("Your payment by check has been saved. It will be validated by a coordinator at the delivery."));
		//}
	
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
		
		//if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
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
			

			//throw Ok("/contract", t._("Your payment by transfer has been saved. It will be validated by a coordinator."));
		//}

	}
	
	/**
	 * pay by cassh
	 */
	@tpl("transaction/cash.mtt")
	public function doCash(){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;		
		if (tmpOrder == null) throw Redirect("/contract");
		if (tmpOrder.products.length == 0) throw Error("/", t._("Your cart is empty"));
		
		view.amount = tmpOrder.total;
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);	
		
		//if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){
				//same multidistrib
				var name = t._("Cash for the order of ::date::", {date:view.hDate(d.date)});				
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Cash.TYPE, tmpOrder.total, name , ops[0] );										
			}else{				
				//various distribs
				db.Operation.makePaymentOperation(app.user, app.user.amap, payment.Cash.TYPE, tmpOrder.total, t._("Cash payment"));
			}
			

			//throw Ok("/contract", t._("Your order is validated, you commited to pay in cash at the delivery."));
		//}
	
	}
}