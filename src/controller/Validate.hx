package controller;
import db.Operation.OperationType;
using Lambda;

/**
 * Distribution validation
 * @author fbarbut
 */
class Validate extends controller.Controller
{
	public var date : Date;
	public var user : db.User;
	public var place : db.Place;
	
	@tpl('validate/user.mtt')
	public function doDefault(){
		view.member = user;
		
		if (!app.user.amap.hasShopMode()){
			//get last operations and check balance
			view.operations = db.Operation.getLastOperations(this.user,place.amap,10);
			view.balance = db.UserAmap.get(this.user, place.amap).balance;
		}
		
		var b = db.Basket.get(user, place, date);			
		view.orders = db.UserContract.prepare(b.getOrders());
		view.place = place;
		view.date = date;
		view.basket = b;
		
		checkToken();
	}
	
	public function doDeleteOp(op:db.Operation){
		if (checkToken()){
			
			op.lock();
			op.delete();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Operation deleted"));
		}
	}
	
	public function doValidateOp(op:db.Operation){
		if (checkToken()){
			
			op.lock();
			op.pending = false;
			op.update();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Operation validated"));
		}
	}
	
	@tpl('form.mtt')
	public function doAddRefund(){
		
		if (!app.user.isContractManager()) throw t._("Forbidden access");
		
		var o = new db.Operation();
		o.user = user;
		o.date = Date.now();
		
		var b = db.Basket.get(user, place, date);
		var op = b.getOrderOperation();
		
		var f = new sugoi.form.Form(t._("payment"));
		f.addElement(new sugoi.form.elements.StringInput("name", t._("Label"), t._("Refund"), true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		
		var data = [];
		for ( p in db.Operation.getPaymentTypes(app.user.amap)) data.push({label:App.t._(p.type),value:p.type});
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Means of payment"), data, null, true));
		
		if (f.isValid()){
			f.toSpod(o);
			o.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			o.data = data;
			o.group = app.user.amap;
			o.user = user;
			o.relation = op;
			o.amount = 0-Math.abs(o.amount);
			o.insert();
			
			App.current.event(NewOperation(o));
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Refund saved"));
		}
		
		view.title = t._("Key-in a refund for ::user::",{user:user.getCoupleName()});
		view.form = f;		
	}
	
	@tpl('form.mtt')
	public function doAddPayment(){
			
		if (!app.user.isContractManager()) throw Error("/",t._("Forbidden access"));
		
		var o = new db.Operation();
		o.user = user;
		o.date = Date.now();
		
		var f = new sugoi.form.Form("payment");
		f.addElement(new sugoi.form.elements.StringInput("name", t._("Label"), t._("Additional payment"), true));
		f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", t._("Date"), Date.now(), true));
		var data = [
			{label:t._("Cash"),value:"cash"},
			{label:t._("Check"),value:"check"},
			{label:t._("Transfer"),value:"transfer"}		
		];
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment mean"), data, null, true));
		
		var b = db.Basket.get(user, place, date);
		var op = b.getOrderOperation();
		
		if (f.isValid()){
			f.toSpod(o);
			o.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			o.data = data;
			o.group = app.user.amap;
			o.user = user;
			o.relation = op;
			
			o.insert();
			
			db.Operation.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Payment saved"));
		}
		
		view.title = t._("Key-in a payment for ::user::",{user:user.getCoupleName()});
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
			
			
			throw Ok("/distribution/validate/"+date+"/"+place.id, t._("Order validated"));
			
		}
		
	}
	
}