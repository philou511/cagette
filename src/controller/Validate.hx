package controller;
import db.Operation.OperationType;
using Lambda;

/**
 * ...
 * @author fbarbut
 */
class Validate extends controller.Controller
{

	
	public var date : Date;
	public var user : db.User;
	public var place : db.Place;
	
	@tpl('validate/user.mtt')
	public function doDefault(){
		
		var b = db.Basket.get(user, place, date);
		
		view.member = user;
		view.place = place;
		view.date = date;
		view.basket = b;
		view.orders = db.UserContract.prepare(b.getOrders());
		
		checkToken();
	}
	
	public function doDeleteOp(op:db.Operation){
		if (checkToken()){
			
			op.lock();
			op.delete();
			
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id,"Opération effacée");
		}
	}
	
	public function doValidateOp(op:db.Operation){
		if (checkToken()){
			
			op.lock();
			op.pending = false;
			op.update();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id,"Opération validée");
		}
	}
	
	@tpl('form.mtt')
	public function doAddRefund(){
		
		if (!app.user.isContractManager()) throw "accès interdit";
		
		var t = new db.Operation();
		t.user = user;
		t.date = Date.now();
		
		var b = db.Basket.get(user, place, date);
		var op = b.getOrderOperation();
		
		var f = new sugoi.form.Form("payement");
		f.addElement(new sugoi.form.elements.StringInput("name", "Libellé", "Remboursement", true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", "Montant", null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		
		var data = [];
		for ( p in db.Operation.getPaymentTypes(app.user.amap)) data.push({label:App.t._(p.type),value:p.type});
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", "Moyen de paiement", data, null, true));
		
		if (f.isValid()){
			f.toSpod(t);
			t.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			t.data = data;
			t.group = app.user.amap;
			t.user = user;
			t.relation = op;
			t.amount = 0-Math.abs(t.amount);
			t.insert();
			
			App.current.event(NewOperation(t));
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, "Remboursement enregistré");
			
		}
		
		view.title = "Saisir un remboursement pour " + user.getCoupleName();
		view.form = f;		
	
	}
	
	@tpl('form.mtt')
	public function doAddPayment(){
			
		if (!app.user.isContractManager()) throw "accès interdit";
		
		var t = new db.Operation();
		t.user = user;
		t.date = Date.now();
		
		var f = new sugoi.form.Form("payement");
		f.addElement(new sugoi.form.elements.StringInput("name", "Libellé", "Paiement complémentaire", true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", "Montant", null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		var data = [
			{label:"Espèces",value:"cash"},
			{label:"Chèque",value:"check"},
			{label:"Virement",value:"transfer"}		
		];
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", "Moyen de paiement", data, null, true));
		
		
		var b = db.Basket.get(user, place, date);
		var op = b.getOrderOperation();
		
		if (f.isValid()){
			f.toSpod(t);
			t.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			t.data = data;
			t.group = app.user.amap;
			t.user = user;
			t.relation = op;
			
			t.insert();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, "Paiement enregistré");
			
		}
		
		view.title = "Saisir un paiement pour " + user.getCoupleName();
		view.form = f;	
	}
	
	public function doValidate(){
		
		if (checkToken()){
			
			var b = db.Basket.get(user, place, date);
			for ( o in b.getOrders() ){
				
				o.lock();
				o.paid = true;
				o.update();
				
			}
			
			var op = b.getOrderOperation(false);
			if (op != null){
				op.lock();
				op.pending = false;
				op.update();
				
				for ( op in b.getPayments()){
					if ( op.pending){
						op.lock();
						op.pending = false;
						op.update();
					}
				}	
			}
			
			
			throw Ok("/distribution/validate/"+date+"/"+place.id, "Commande validée");
			
		}
		
	}
	
}