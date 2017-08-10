package payment;

/**
 * ...
 * @author fbarbut
 */
class Payment
{
	
	/**
	 * Get all available payment types, including one from plugins
	 */
	public static function getPaymentTypes(){
		var types = [
			new payment.Cash(),
			new payment.Check(),
			new payment.Transfer(),		
		];
		
		var e = App.current.event(GetPaymentTypes({types:types}));
		return switch(e){
			case GetPaymentTypes(d): d.types;
			default : null;
		}
		
	}

	public var type:String;
	public var icon:String;
	public var name:String; //translated name
	public var link:String;
	
}