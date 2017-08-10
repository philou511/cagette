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
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="fa fa-credit-card" aria-hidden="true"></i>';
		this.name = t._("Cash");
		//this.desc = t._("Pay by cash at product distribution");
		this.link = "/transaction/cash";
	}
	
}