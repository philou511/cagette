package controller;
import db.Transaction.TransactionType;
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
		
		var t = new db.Transaction();
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
		var unpaid = db.Transaction.manager.search($user == user && $group == app.user.amap && $type != TTPayment && $pending == true);
		var data = unpaid.map(function(x) return {label:x.name, value:x.id}).array();
		f.addElement(new sugoi.form.elements.IntSelect("unpaid", "En paiement de :", data, null, false));
		
		if (f.isValid()){
			f.toSpod(t);
			t.type = db.Transaction.TransactionType.TTPayment;
			var data : db.Transaction.TPaymentInfos = {type:f.getValueOf("Mtype")};
			t.data = data;
			t.group = app.user.amap;
			t.user = user;
			
			if (f.getValueOf("unpaid") != null){
				var t2 = db.Transaction.manager.get(f.getValueOf("unpaid"));
				t.relation = t2;
				if (t2.amount + t.amount == 0) {
					t.pending = false;
					t2.lock();
					t2.pending = false;
					t2.update();
					
				}
			}
			
			t.insert();
			
			db.Transaction.updateUserBalance(user, app.user.amap);
			
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
		
		var distribKey = db.Distribution.makeKey(date, place);		
		view.debt = db.Transaction.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
		view.ua = db.UserAmap.get(app.user, app.user.amap);
		view.paymentTypes = db.Transaction.getPaymentTypes(app.user.amap);
		view.basket = db.Basket.get(app.user, place, date);
		view.place = place;
		view.date = date;
	}
	
	/**
	 * pay by check
	 */
	@tpl("transaction/check.mtt")
	public function doCheck(place:db.Place, date:Date){
		
		var distribKey = db.Distribution.makeKey(date, place);		
		var t = db.Transaction.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
		view.debt = t;
		view.code = payment.Check.getCode(date, place, app.user);
		view.name = app.user.amap.name;
		
		if (checkToken()){
			db.Transaction.makeOrderPayment("check", t.amount, "Chèque pour commande du " + view.hDate(date), t );			
			throw Ok("/contract", "Votre paiement par chèque a bien été enregistré. Il sera validé par un coordinateur lors de la distribution.");
		}
		
	}
	
	/**
	 * pay by transfer
	 */
	@tpl("transaction/transfer.mtt")
	public function doTransfer(place:db.Place, date:Date){
		
		var distribKey = db.Distribution.makeKey(date, place);		
		var t = db.Transaction.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
		view.debt = t;
		view.code = payment.Check.getCode(date, place, app.user);
		view.name = app.user.amap.name;
		
		if (checkToken()){
			db.Transaction.makeOrderPayment("transfer", t.amount, "Virement pour commande du " + view.hDate(date), t);			
			throw Ok("/contract", "Votre paiement par virement a bien été enregistré. Il sera validé par un coordinateur.");
		}
		
	}
	
	/**
	 * pay by cassh
	 */
	@tpl("transaction/cash.mtt")
	public function doCash(place:db.Place, date:Date){
		
		var distribKey = db.Distribution.makeKey(date, place);		
		var t = db.Transaction.findVOrderTransactionFor(distribKey, app.user, app.user.amap);
		view.debt = t;
		view.code = payment.Check.getCode(date, place, app.user);
		view.name = app.user.amap.name;
		
		if (checkToken()){
			db.Transaction.makeOrderPayment("cash", t.amount, "Paiement en liquide pour commande du " + view.hDate(date), t );			
			throw Ok("/contract", "Votre souhait de payer en liquide lors de la distribution a bien été prise en compte.");
		}
		
	}
	
	
}