package payment;

/**
 * ...
 * @author fbarbut
 */
class MoneyPot extends payment.Payment
{
	
	public static var TYPE = "moneypot";

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="glyphicon glyphicon-piggy-bank" aria-hidden="true"></i>';
		this.name = t._("Money pot");
		//this.desc = t._("Pay by cash at product distribution");
		this.link = "/transaction/moneypot";
	}
	
}