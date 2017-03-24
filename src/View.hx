using Std;
import Common;
import haxe.Utf8;
import tools.ArrayTool;

class View extends sugoi.BaseView {
	public function new() {
		super();
		this.Std = Std;
		this.Date = Date;
		this.Web = sugoi.Web;
		this.Lambda = Lambda;
		this.VERSION = App.VERSION.toString();
		this.ArrayTool = ArrayTool;
	}
	
	public function count(i) {
		return Lambda.count(i);
	}
	
	public function abs(n){
		return Math.abs(n);
	}

	/**
	 * init view in main loop, just before rendering
	 */
	override function init() {
		super.init();		
		
		//tuto widget display
		var u = App.current.user;
		if (u!=null && u.tutoState!=null) {
			//trace("view init "+u.tutoState.name+" , "+u.tutoState.step);
			this.displayTuto(u.tutoState.name, u.tutoState.step);	
		}
		
		
		
	}
	
	
	function getUser(uid:Int):db.User {
		return db.User.manager.get(uid, false);
	}
	
	/**
	 * Round a number to r digits after coma.
	 * 
	 * @param	n
	 * @param	r
	 */
	public function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}
	
	
	public function color(id:Int) {
		if (id == null) throw "color cant be null";
		//try{
			return intToHex(db.CategoryGroup.COLORS[id]);
		//}catch (e:Dynamic) return "#000000";
	}
	
	/**
	 * convert a RVB color from Int to Hexa
	 * @param	c
	 * @param	leadingZeros=6
	 */
	public function intToHex(c:Int, ?leadingZeros=6):String {
		var h = StringTools.hex(c);
		while (h.length<leadingZeros)
			h="0"+h;
		return "#"+h;
	}
	
	public function formatNum(n:Float):String {
		if (n == null) return "";
		
		//arrondi a 2 apres virgule
		var out  = Std.string(roundTo(n, 2));		
		
		//ajout un zéro, 1,8-->1,80
		if (out.indexOf(".")!=-1 && out.split(".")[1].length == 1) out = out +"0";
		
		//virgule et pas point
		return out.split(".").join(",");
	}
	
	/**
	 * max length for strings, usefull for tables
	 */
	public function short(text:String, length:Int){
		if (Utf8.length(text) > length){
			
			return Utf8.sub(text,0, length)+"…";
		}else{
			return text;
		}
	}
	
	public function isToday(d:Date) {
		var n = Date.now();
		return d.getDate() == n.getDate() && d.getMonth() == n.getMonth() && d.getFullYear() == n.getFullYear();
	}
	
	public function unit(u:UnitType){
		return switch(u){
			case Kilogram: "Kg.";
			case Gram: "g.";
			case Piece: "pièce(s)";
			case Litre: "L.";
		}
	}
	
	public function currency(){
		if (App.current.user == null || App.current.user.amap == null){
			return "€";
		}else{
			return App.current.user.amap.getCurrency();	
		}
		
	}
	
	public var DAYS = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"];
	public var MONTHS = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Aout", "Septembre", "Octobre", "Novembre", "Décembre"];
	public var HOURS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
	public var MINUTES = [0,5,10,15,20,25,30,35,40,45,50,55];
	
	/**
	 * human readable date 
	 * @param	date
	 */
	public function hDate(date:Date):String {
		if (date == null) return "aucune date";
		var out = DAYS[date.getDay()] + " " + date.getDate() + " " + MONTHS[date.getMonth()];
		/*if ( date.getFullYear() != Date.now().getFullYear())*/ out += " " + date.getFullYear();
		if ( date.getHours() != 0 || date.getMinutes() != 0) out += " à " + StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		return out;
	}
	
	public function dDate(date:Date):String {
		if (date == null) return "aucune date";
		return DAYS[date.getDay()] + " " + date.getDate() + " " + MONTHS[date.getMonth()];
	}
	
	public function getDate(date:Date) {
		if (date == null) throw "date is null";
		
		
		return {
			dow: DAYS[date.getDay()],
			d : date.getDate(),
			m: MONTHS[date.getMonth()],
			y: date.getFullYear(),			
			h: StringTools.lpad(Std.string(date.getHours()),"0",2),
			i: StringTools.lpad(Std.string(date.getMinutes()),"0",2)
		};
	}
	
	public function hHour(h:Int,m:Int){
		return StringTools.lpad(h.string(), "0", 2) + ":" + StringTools.lpad(m.string(), "0", 2);
	}
	
	public function getProductImage(e):String {
		
		return Std.string(e).substr(2).toLowerCase()+".png";
	}
	
	
	public function displayTuto(tuto:String, step:Int) {
		if (tuto == null) return;
		var t = plugin.Tutorial.all().get(tuto);
		
		//check if we are on the correct page (last step page)
		//otherwise the popovers could be displayed on wrong elements
		var previous = t.steps[step - 1];
		if (previous != null) {
			switch(previous.action) {
				case TAPage(uri):
					var here = neko.Web.getURI();
					if (!plugin.Tutorial.match(uri,here)) {
						//trace(here+" is not " + uri);
						return;
					}
				default:
			}
			
		}
	
		this.tuto = { name:tuto, step:step };
		
	}
	
	/**
	 * renvoie 0 si c'est user.firstName qui est connecté,
	 * renvoie 1 si c'est user.firstName2 qui est connecté
	 * @return
	 */
	public function whichUser():Int {
		if (App.current.session.data == null) return 0;
		return App.current.session.data.whichUser == null?0:App.current.session.data.whichUser;
		
	}
		
	/**
	 * wording : amap/groupe
	 */
	public function wAmap() {
		return App.current.user.amap.flags.has(db.Amap.AmapFlags.IsAmap)?"AMAP":"groupe";
	}
	
	public function wVendors() {
		return App.current.user.amap.flags.has(db.Amap.AmapFlags.IsAmap)?"Paysans":"Fournisseurs";
	}
	
	public function wVendor() {
		return App.current.user.amap.flags.has(db.Amap.AmapFlags.IsAmap)?"Paysan":"Fournisseur";
	}
	
	public function getBasket(userId, placeId, date){
		var user = getUser(userId);
		var place = db.Place.manager.get(placeId, false);
		return db.Basket.get(user, place, date);
	}
	
	public function getPlatform(){
		 return #if neko "Neko" #else "PHP" #end ;
	}
	
	/**
	 * Translation function
	 */
	public function _(text:String):String{
		if (App.t != null){
			return App.t._(text);	
		}else{
			return text;
		}
		
	}
	
}
