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
	public static function smartQt(orderQt:Float,productQt:Float,unit:Unit):String{
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

	public static function parseFloat(s:String):Float{
		if(s.indexOf(",")>0){
			return Std.parseFloat(StringTools.replace(s,",","."));
		}else{
			return Std.parseFloat(s);
		}
	}
	
	/**
	 *  Display a unit
	 */
	public static function unit(u:Unit,?quantity=1.0):String{
		/*t = sugoi.i18n.Locale.texts;
		if(u==null) return t._("piece||unit of a product)");
		return switch(u){
			case Kilogram: 	t._("Kg.||kilogramms");
			case Gram: 		t._("g.||gramms");
			case Piece: 	t._("piece||unit of a product)");
			case Litre: 	t._("L.||liter");
			case Centilitre: 	t._("cl.||centiliter");
		}*/

		return switch(u){
			case Kilogram: 	 "Kg.";
			case Gram: 		 "g.";			
			case Litre: 	 "L.";
			case Centilitre: "cl.";
			case null,Piece: if(quantity==1.0) "pièce" else "pièces";
		}
		
	}

	/**
	 * Price per Kg/Liter...
	 * @param	qt
	 * @param	unit
	 */
	public static function pricePerUnit(price:Float, qt:Float, u:Unit, ?currency="€"):String{
		if (u==null || qt == null || qt == 0 || price==null || price==0) return "";
		var pricePerUnit = price / qt;
				
		//turn small prices in Kg
		if (pricePerUnit < 1 ){
			switch(u){
				case Gram: 
					pricePerUnit *= 1000;
					u = Kilogram;
				case Centilitre:
					pricePerUnit *= 100;
					u = Litre;
				default :
			}
		}			
		return formatNum(pricePerUnit) + " " + currency + "/" + unit(u,qt);
	}

	public static var DAYS = ["Dimanche","Lundi", "Mardi", "Mercredi","Jeudi", "Vendredi", "Samedi"];
	public static var MONTHS = ["Janvier","Février","Mars","Avril", "Mai","Juin", "Juillet", "Aout", "Septembre", "Octobre", "Novembre","Décembre"];
	public static var HOURS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
	public static var MINUTES = [0,5,10,15,20,25,30,35,40,45,50,55];
	
	/**
	 * human readable date + time
	 */
	public static function hDate(date:Date):String {
		if (date == null) return "No date set";
		var out = DAYS[date.getDay()] + " " + date.getDate() + " " + MONTHS[date.getMonth()];
		out += " " + date.getFullYear();
		if ( date.getHours() != 0 || date.getMinutes() != 0){
			out += " à " + StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		}
		return out;
	}
}