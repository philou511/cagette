package payment;

/**
 * ...
 * @author fbarbut
 */
class Cash extends payment.Payment
{
	
	public static var TYPE = "cash";

	public function new() 
	{
		this.type = TYPE;
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.desc = "Paiement en espèces";
		this.link = "/transaction/cash";
	}
	
}