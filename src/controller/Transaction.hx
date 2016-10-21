package controller;

/**
 * ...
 * @author fbarbut
 */
class Transaction extends controller.Controller
{

	@tpl('form.mtt')
	public function doInsertPayment(user:db.User){
		
		var t = new db.Transaction();
		t.user = user;
		t.date = Date.now();
		
		
		var f = sugoi.form.Form.fromSpod(t);
		f.removeElementByName("userId");
		f.removeElementByName("pending");
		f.removeElementByName("type");
		var data = [
		{label:"Espèces",value:"cash"},
		{label:"Chèque",value:"check"},
		{label:"Virement",value:"transfer"}		
		];
		f.addElement(new sugoi.form.elements.StringSelect("Mtype", "Moyen de paiement", data, null, true));
		
		if (f.isValid()){
			f.toSpod(t);
			t.type = db.Transaction.TransactionType.TTPayment(f.getValueOf("Mtype"));
			t.group = app.user.amap;
			t.insert();
			
			db.Transaction.updateUserBalance(user, app.user.amap);
			
			throw Ok("/member/payments/" + user.id, "Paiement enregistré");
			
		}
		
		view.title = "Saisir un paiement pour " + user.getCoupleName();
		view.form = f;
		
	}
	
	
}