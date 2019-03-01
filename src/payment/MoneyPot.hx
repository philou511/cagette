package payment;

/**
 * ...
 * @author web-wizard
 */
class MoneyPot extends payment.PaymentType
{
	
	public static var TYPE = "moneypot";

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="icon icon-moneypot"></i>';
		this.name = t._("Money pot");
		this.link = "/transaction/moneypot";
	}
	
}