package payment;

/**
 * ...
 * @author fbarbut
 */
class Cash extends payment.PaymentType
{
	
	public static var TYPE = "cash";

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.name = t._("Cash");
		this.link = "/transaction/cash";
	}
	
}