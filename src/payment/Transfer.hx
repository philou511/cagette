package payment;

/**
 * ...
 * @author fbarbut
 */
class Transfer extends payment.PaymentType
{
	
	public static var TYPE = "transfer";

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.name = t._("Bank transfer");
		this.link = "/transaction/transfer";
	}
	
}