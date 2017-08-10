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
		
		if (!app.user.isContractManager()) throw "accès interdit";
		
		var t = new db.Operation();
		t.user = user;
		t.date = Date.now();
		
		var f = new sugoi.form.Form("payement");
		f.addElement(new sugoi.form.elements.StringInput("name", "Libellé", null, true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", "Montant", null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		var data = [
			{label:"Espèces",value:"cash"},
			{label:"Chèque",value:"check"},
			{label:"Virement",value:"transfer"}		
		];
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", "Moyen de paiement", data, null, true));
		
		//unpaid orders
		var unpaid = db.Operation.manager.search($user == user && $group == app.user.amap && $type != Payment && $pending == true);
		var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
		f.addElement(new sugoi.form.elements.IntSelect("unpaid", "En paiement de :", data, null, false));
		
		if (f.isValid()){
			f.toSpod(t);
			t.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			t.data = data;
			t.group = app.user.amap;
			t.user = user;
			
			if (f.getValueOf("unpaid") != null){
				var t2 = db.Operation.manager.get(f.getValueOf("unpaid"));
				t.relation = t2;
				if (t2.amount + t.amount == 0) {
					t.pending = false;
					t2.lock();
					t2.pending = false;
					t2.update();
					
				}
			}
			
			t.insert();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/member/payments/" + user.id, "Paiement enregistré");
			
		}
		
		view.title = "Saisir un paiement pour " + user.getCoupleName();
		view.form = f;		
	}
	
	/**
	 * payement entry page
	 * @param	distribKey
	 */
	@tpl("transaction/pay.mtt")
	public function doPay(){

		var order : OrderInSession = app.session.data.order;
		if (order == null) throw Redirect("/");
		
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
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);		
		var code = payment.Check.getCode(d.date, d.place, app.user);
		
		view.code = code;
		view.amount = tmpOrder.total;
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){				
				//all orders are for the same multidistrib
				db.Operation.makePaymentOperation(app.user,app.user.amap, payment.Check.TYPE, tmpOrder.total, "Chèque pour commande du " + view.hDate(d.date)+" ("+code+")", ops[0] );							
			}else{				
				//orders are for multiple distribs : create one payment
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Check.TYPE, tmpOrder.total, "Chèque ("+code+")" );			
			}
			
			throw Ok("/contract", "Votre paiement par chèque a bien été enregistré. Il sera validé par un coordinateur lors de la distribution.");
		}
		
	}
	
	/**
	 * pay by transfer
	 */
	@tpl("transaction/transfer.mtt")
	public function doTransfer(place:db.Place, date:Date){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;		
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);	
		var code = payment.Check.getCode(date, place, app.user);
		view.code = code;
		view.amount = tmpOrder.total;
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){
				//one multidistrib
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Transfer.TYPE, tmpOrder.total, "Virement pour commande du " + view.hDate(d.date)+" ("+code+")", ops[0] );
			}else{
				//many distribs
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Transfer.TYPE, tmpOrder.total, "Paiement par virement ("+code+")");			
			}
			
			throw Ok("/contract", "Votre paiement par virement a bien été enregistré. Il sera validé par un coordinateur.");		
		}
	}
	
	/**
	 * pay by cassh
	 */
	@tpl("transaction/cash.mtt")
	public function doCash(){
		
		//order in session
		var tmpOrder : OrderInSession = app.session.data.order;		
		view.amount = tmpOrder.total;
		var d = db.Distribution.manager.get(tmpOrder.products[0].distributionId, false);	
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(tmpOrder);
			var ops = db.Operation.onOrderConfirm(orders);
			var ordersGrouped = tools.ObjectListTool.groupOrdersByKey(orders);
			
			if (Lambda.array(ordersGrouped).length == 1){
				//same multidistrib
				db.Operation.makePaymentOperation(app.user,app.user.amap,payment.Cash.TYPE, tmpOrder.total, "Liquide pour commande du " + view.hDate(d.date), ops[0] );										
			}else{				
				//various distribs
				db.Operation.makePaymentOperation(app.user, app.user.amap, payment.Cash.TYPE, tmpOrder.total, "Paiement en liquide" );			
			}
			
			throw Ok("/contract", "Votre commande est validée, vous vous êtes engagé à payer en liquide au retrait des produits.");
		}
		
	}
	
	/**
	 * view a transaction detail in a pop-in window 
	 * @param	t
	 */
	@tpl("transaction/view.mtt")
	public function doView(op:db.Operation){
		view.op = op ;
		
		#if cagette-pro
		var lw = pro.payment.LWCPayment.getConnector(app.user.amap);
		
		if (op.data.remoteOpId == null) throw "No remoteOpId in this operation";
		
		//update status if needed
		var td = lw.getMoneyInTransDetails(op.data.remoteOpId);
		if (td.HPAY[0].STATUS == "3" && op.pending){
			op.lock();
			op.pending = false;
			op.update();
		}
		
		view.infos = td;
		#end
		
	}
	
	
}