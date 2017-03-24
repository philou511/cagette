package payment;

/**
 * ...
 * @author fbarbut
 */
class Check extends payment.Payment
{

	public function new() 
	{
		this.type = "check";
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.desc = "Paiement par chèque";
		this.link = "/transaction/check";
	}
	
	public static function getCode(date:Date,place:db.Place,user:db.User){
		return date.toString().substr(0, 10) + "-" + place.id + "-" + user.id;
	}
	
}