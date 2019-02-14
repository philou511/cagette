package payment;

/**
 * June (G1)
 * @author fbarbut
 */
class June extends payment.PaymentType
{
	
	public static var TYPE = "june";

	public function new() 
	{
		var t = sugoi.i18n.Locale.texts;
		this.type = TYPE;
		this.icon = 'Ğ1';
		this.name = t._("Ğ1 (June)");
		this.link = "/transaction/june";
	}

    public static function getPaymentUrl(publicKey:String,amount:Float,comment:String,receiverName:String,redirect_url:String){
        redirect_url = StringTools.urlEncode(redirect_url);
        return 'https://g1.duniter.fr/api/#/v1/payment/$publicKey?amount=$amount&comment=$comment&name=$receiverName&redirect_url=$redirect_url';
		

    }
	
}