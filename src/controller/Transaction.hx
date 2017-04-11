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
	public function doPay(place:db.Place,date:Date){

		var order : OrderInSession = app.session.data.order;
		view.amount = order.total;
		
		view.paymentTypes = db.Operation.getPaymentTypes(app.user.amap);		
		view.place = place;
		view.date = date;
	}
	
	/**
	 * pay by check
	 */
	@tpl("transaction/check.mtt")
	public function doCheck(place:db.Place, date:Date){
		
		//order in session
		var order : OrderInSession = app.session.data.order;		
		var code = payment.Check.getCode(date, place, app.user);
		view.code = code;
		
		//previous orders
		//var b = db.Basket.get(app.user, place, date);
		//var prevOrders = db.UserContract.prepare(b.getOrders());
		//var prevTotal = db.UserContract.getTotalPrice(prevOrders);
		view.amount = order.total;
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(order);
			var total = db.UserContract.getTotalPrice(db.UserContract.prepare(orders));
		
			//record payment
			var distribKey = db.Distribution.makeKey(date, place);		
			var t = db.Operation.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
			db.Operation.makePaymentOperation(app.user,app.user.amap,"check", total, "Chèque pour commande du " + view.hDate(date)+" ("+code+")", t );			
			throw Ok("/contract", "Votre paiement par chèque a bien été enregistré. Il sera validé par un coordinateur lors de la distribution.");
		}
		
	}
	
	/**
	 * pay by transfer
	 */
	@tpl("transaction/transfer.mtt")
	public function doTransfer(place:db.Place, date:Date){
		
		//order in session
		var order : OrderInSession = app.session.data.order;		
		var code = payment.Check.getCode(date, place, app.user);
		view.code = code;
		view.amount = order.total;
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(order);
			var total = db.UserContract.getTotalPrice(db.UserContract.prepare(orders));
		
			//record payment
			var distribKey = db.Distribution.makeKey(date, place);		
			var t = db.Operation.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
			db.Operation.makePaymentOperation(app.user,app.user.amap,"transfer", total, "Virement pour commande du " + view.hDate(date)+" ("+code+")", t );			
			throw Ok("/contract", "Votre paiement par virement a bien été enregistré. Il sera validé par un coordinateur.");
		}
	}
	
	/**
	 * pay by cassh
	 */
	@tpl("transaction/cash.mtt")
	public function doCash(place:db.Place, date:Date){
		
		//order in session
		var order : OrderInSession = app.session.data.order;		
		view.amount = order.total;
		
		if (checkToken()){
			
			//record order
			var orders = db.UserContract.confirmSessionOrder(order);
			var total = db.UserContract.getTotalPrice(db.UserContract.prepare(orders));
		
			//record payment
			var distribKey = db.Distribution.makeKey(date, place);		
			var t = db.Operation.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
			db.Operation.makePaymentOperation(app.user,app.user.amap,"cash", total, "Liquide pour commande du " + view.hDate(date), t );			
			throw Ok("/contract", "Votre commande est validée, vous vous êtes engagé à payer en liquide au retrait des produits.");
		}
		
	}
	
	/**
	 * view a transaction detail in a pop-in window 
	 * @param	t
	 */
	@tpl("transaction/view.mtt")
	public function doView(t:db.Operation){
		view.t = t ;
		
		var lw = pro.payment.LWCPayment.getConnector(app.user.amap);
		
		if (t.data.remoteOpId == null) throw "No remoteOpId in this operation";
		
		//update status if needed
		var td = lw.getMoneyInTransDetails(t.data.remoteOpId);
		if (td.HPAY[0].STATUS == "3" && t.pending){
			t.lock();
			t.pending = false;
			t.update();
		}
		
		view.infos = td;
		
	}
	
	
}