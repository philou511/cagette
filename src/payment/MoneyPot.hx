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
		this.icon = '<i class="glyphicon glyphicon-piggy-bank" aria-hidden="true"></i>';
		this.name = t._("Money pot");
		this.link = "/transaction/moneypot";
	}
	
}