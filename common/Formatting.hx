package;
import Common;

/**
 * Formatting tools used on both client and server side.
 * 
 * @author fbarbut
 */
class Formatting
{

	/** smart quantity filter : display easier-to-read quantity when it's floats
	 * 
	 * 0.33 x Lemon 12kg => 2kg Lemon
	 */ 
	public static function smartQt(orderQt:Float,productQt:Float,unit:UnitType):String{
		return formatNum(orderQt * productQt) + "&nbsp;" + Formatting.unit(unit);
	}
	
	public static function formatNum(n:Float):String {
		if (n == null) return "";
		
		//arrondi a 2 apres virgule
		var out  = Std.string(roundTo(n, 2));		
		
		//ajout un zéro, 1,8-->1,80
		if (out.indexOf(".")!=-1 && out.split(".")[1].length == 1) out = out +"0";
		
		//virgule et pas point
		return out.split(".").join(",");
	}
	
	
	/**
	 * Round a number to r digits after coma.
	 */
	public static function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}
	
	public static function unit(u:UnitType){
		/*t = sugoi.i18n.Locale.texts;
		if(u==null) return t._("piece||unit of a product)");
		return switch(u){
			case Kilogram: 	t._("Kg.||kilogramms");
			case Gram: 		t._("g.||gramms");
			case Piece: 	t._("piece||unit of a product)");
			case Litre: 	t._("L.||liter");
			case Centilitre: 	t._("cl.||centiliter");
		}*/
		if(u==null) return "pièce(s)";
		return switch(u){
			case Kilogram: 	"Kg.";
			case Gram: 		"g.";
			case Piece: 	"pièce(s)";
			case Litre: 	"L.";
			case Centilitre:"cl.";
		}
		
	}
}