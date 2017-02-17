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
		this.name = "Chèque";
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.desc = "Paiement par chèque";
		this.link = "/transaction/pay/check";
	}
	
}