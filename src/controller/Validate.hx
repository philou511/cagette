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
		view.orders = service.OrderService.prepare(b.getOrders());
		view.place = place;
		view.date = date;
		view.basket = b;
		view.onTheSpotAllowedPaymentTypes = service.PaymentService.getOnTheSpotAllowedPaymentTypes(app.user.amap);
		
		checkToken();
	}
	
	public function doDeleteOp(op:db.Operation){
		if (checkToken()){
			
			op.lock();
			op.delete();
			
			service.PaymentService.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Operation deleted"));
		}
	}
	
	public function doValidateOp(operation: db.Operation) 
	{
		if (checkToken()) 
		{
			operation.lock();
			operation.pending = false;
			if (app.params.exists("type"))
			{
				operation.data.type = app.params.get("type"); 				
			}			
			operation.update();
			
			service.PaymentService.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Operation validated"));
		}
	}
	
	@tpl('form.mtt')
	public function doAddRefund() {

		var basketId = Std.parseInt(app.params.get("basketid"));
		//var hasOnlyMangopayPayments = false;
		var basket = null;
		if(basketId != null) 
		{
			basket = db.Basket.manager.get(basketId, false);
			//hasOnlyMangopayPayments = pro.MangopayPlugin.hasOnlyMangopayPayments(basket);
		}

		//Refund amount
		var refundAmount = basket.getTotalPaid() - basket.getOrdersTotal();
		//There is nothing to refund
		if(refundAmount <= 0) {
			throw Error("/validate/" + date + "/" + place.id + "/" + user.id, t._("There is nothing to refund"));
		}
		
		if (!app.user.isContractManager()) throw t._("Forbidden access");
		
		var operation = new db.Operation();
		operation.user = user;
		operation.date = Date.now();
		
		var b = db.Basket.get(user, place, date);
		var orderOperation = b.getOrderOperation(false);
		if(orderOperation == null) throw "unable to find related order operation";
		
		var f = new sugoi.form.Form(t._("payment"), "/validate/" + date + "/" + place.id + "/" + user.id + "/addRefund?basketid=" + basketId);
		f.addElement(new sugoi.form.elements.StringInput("name", t._("Label"), t._("Refund"), true));
		/*if (hasOnlyMangopayPayments) {
			f.addElement(new sugoi.form.elements.Html("amount", Std.string(refundAmount) + " €", t._("Amount")));
		} else {
			f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), refundAmount, true));
		}
		if (hasOnlyMangopayPayments) {
			f.addElement(new sugoi.form.elements.Html("date", view.hDate(Date.now()), t._("Date")));
		} else {
			f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		}
		var paymentTypes = service.PaymentService.getPaymentTypesForManualEntry(app.user.amap);
		if (hasOnlyMangopayPayments) {
			f.addElement(new sugoi.form.elements.Html("Mtype", pro.payment.MangopayPayment.TYPE, t._("Payment type")));
		} else {
			f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), paymentTypes, null, true));
		}*/
		f.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), null, true));
		f.addElement(new sugoi.form.elements.DatePicker("date", "Date", Date.now(), true));
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, app.user.amap);
		var out = [];
		for (paymentType in paymentTypes)
		{
			out.push({label: paymentType.name, value: paymentType.type});
		}
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), out, null, true));

		
		if (f.isValid()) {
			
			f.toSpod(operation);
			operation.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			operation.data = data;
			operation.group = app.user.amap;
			operation.user = user;
			operation.relation = orderOperation;

			/*if(hasOnlyMangopayPayments)
			{
				operation.date = Date.now();
				operation.data = { type : pro.payment.MangopayPayment.TYPE };
				var mangopayUser = pro.db.MangopayUser.get(user);
				if( mangopayUser == null ) {
					throw Error("/validate/" + date + "/" + place.id + "/" + user.id, t._("This user should have a Mangopay user"));
				}

				//We sort the payments operations by payment amounts so that we can refund first on the biggest amount
				var sortedPaymentsOperations = Lambda.array(basket.getPaymentsOperations());
				sortedPaymentsOperations.sort(function(a, b): Int {
					if (a.amount < b.amount) return 1;
					else if (a.amount > b.amount) return -1;
					return 0;
				});

				//Let's do the refund on different payments if needed
				var refundRemainingAmount = refundAmount;
				var amountRefunded = 0.0;
				for ( payment in sortedPaymentsOperations ) {
					
					if ( refundRemainingAmount == 0.0 ) {
						break;
					}				
					
					if ( refundRemainingAmount <= payment.amount ) {
						//Partial Refund
						amountRefunded = refundRemainingAmount;
					}
					else {
						//Full Refund						
						amountRefunded = payment.amount;						
					}
					refundRemainingAmount -= amountRefunded;	

					//Let's do the refund for this payment
					var refund : mangopay.Mangopay.Refund = {				
						DebitedFunds: {				
							Currency: "EUR",
							Amount: Math.round(amountRefunded * 100) - mangopay.Mangopay.getTotalFees(amountRefunded)		
						},
						Fees: {				
							Currency: "EUR",
							Amount: - mangopay.Mangopay.getTotalFees(amountRefunded)
						},
						AuthorId: mangopayUser.mangopayUserId,
						InitialTransactionId: payment.data.remoteOpId				
					};				
					var payInRefund : mangopay.Mangopay.Refund = mangopay.Mangopay.createPayInRefund(refund);

					//Let's record this refund in the db
					operation.amount = -amountRefunded;
					operation.insert();
					App.current.event(NewOperation(operation));
					service.PaymentService.updateUserBalance(user, app.user.amap);					

				}
			}
			else {*/
				operation.amount = 0 - Math.abs(operation.amount);
				operation.insert();
				App.current.event(NewOperation(operation));
				service.PaymentService.updateUserBalance(user, app.user.amap);
			//}		
			
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
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, app.user.amap);
		var out = [];
		for (paymentType in paymentTypes)
		{
			out.push({label: paymentType.name, value: paymentType.type});
		}
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), out, null, true));
		
		var b = db.Basket.get(user, place, date);
		var op = b.getOrderOperation(false);
		if(op==null) throw "unable to find related order operation";
		
		if (f.isValid()){
			f.toSpod(o);
			o.type = db.Operation.OperationType.Payment;
			var data : db.Operation.PaymentInfos = {type:f.getValueOf("Mtype")};
			o.data = data;
			o.group = app.user.amap;
			o.user = user;
			o.relation = op;			
			o.insert();
			
			service.PaymentService.updateUserBalance(user, app.user.amap);
			
			throw Ok("/validate/"+date+"/"+place.id+"/"+user.id, t._("Payment saved"));
		}
		
		view.title = t._("Key-in a payment for ::user::",{user:user.getCoupleName()});
		view.form = f;	
	}
	
	public function doValidate(){
		
		if (checkToken()) 
		{
			var basket = db.Basket.get(user, place, date);

			try
			{
				service.PaymentService.validateBasket(basket);
			}
			catch(e:tink.core.Error)
			{
				throw Error("/distribution/validate/" + date + "/" + place.id, e.message);
			}
		
			throw Ok("/distribution/validate/" + date + "/" + place.id, t._("Order validated"));
			
		}
		
	}
	
}