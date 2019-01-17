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
		this.icon = '<i class="icon icon-cash"></i>';
		this.name = t._("Cash");
		this.link = "/transaction/cash";
	}
	
}