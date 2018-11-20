package payment;

/**
 * ...
 * @author web-wizard
 */
class OnTheSpotPayment extends payment.PaymentType
{
	
	public static var TYPE = "onthespot";
	public var allowedPaymentTypes : Array<payment.PaymentType>;

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = '<i class="glyphicon glyphicon-euro" aria-hidden="true"></i>';
		this.name = t._("On the spot payment");
		this.link = "/transaction/onthespot";
		this.allowedPaymentTypes = [];
	}
	
}