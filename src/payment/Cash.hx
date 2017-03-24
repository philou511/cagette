package payment;

/**
 * ...
 * @author fbarbut
 */
class Cash extends payment.Payment
{
	
	

	public function new() 
	{
		this.type = "cash";
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.desc = "Paiement en espèces";
		this.link = "/transaction/cash";
	}
	
}