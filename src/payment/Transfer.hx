package payment;

/**
 * ...
 * @author fbarbut
 */
class Transfer extends payment.Payment
{

	public function new() 
	{
		this.type = "transfer";
		this.name = "Virement";
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.desc = "Paiement par virement bancaire";
		this.link = "/transaction/transfer";
	}
	
}