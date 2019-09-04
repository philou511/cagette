using Std;
import Common;
import haxe.Utf8;
import tools.ArrayTool;

class View extends sugoi.BaseView {
	
	var t : sugoi.i18n.GetText;
	
	
	public function new() {
		super();
		this.Std = Std;
		this.Date = Date;
		this.Web = sugoi.Web;
		this.Lambda = Lambda;
		this.VERSION = App.VERSION.toString();
		this.ArrayTool = ArrayTool;
		this.t = sugoi.i18n.Locale.texts;
	}
	
	public function count(i) {
		return Lambda.count(i);
	}
	
	public function abs(n){
		return Math.abs(n);
	}

	public function breadcrumb():Array<Link>{
		return App.current.breadcrumb;
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
	
	function getCurrentGroup(){
		return App.current.getCurrentGroup();
	}
	
	
	function getUser(uid:Int):db.User {
		return db.User.manager.get(uid, false);
	}
	
	function getProduct (pid:Int){ 
		return db.Product.manager.get(pid, false);		
	}

	function getPlace(placeId:Int){
		return db.Place.manager.get(placeId,false);
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
	
	/**
	 * Format prices
	 */
	public function formatNum(n:Float):String {
		if (n == null) return "";
		
		//round with 2 digits after comma
		var out  = Std.string(roundTo(n, 2));		
		
		//add a zero, 1,8-->1,80
		if (out.indexOf(".")!=-1 && out.split(".")[1].length == 1) out = out +"0";
		
		//french : replace point by comma
		return out.split(".").join(",");
	}
	
	/**
	 * Price per Kg/Liter...
	 * @param	qt
	 * @param	unit
	 */
	public function pricePerUnit(price:Float,qt:Float, unit:Unit){
		if (unit==null || qt == null || qt == 0 || price==null || price==0) return "";
		var _price = price / qt;
		var _unit = unit;
		
		//turn small prices in Kg
		if (_price < 1 ){
			switch(unit){
				case Gram: 
					_price *= 1000;
					_unit = Kilogram;
				case Centilitre:
					_price *= 100;
					_unit = Litre;
				default :
			}
		}			
		return formatNum(_price) + "&nbsp;" + currency() + "/" + this.unit(_unit);
	}
	
	/**
	 * clean numbers in views
	 * to avoid bugs like : 13.79 - 13.79 = 1.77635683940025e-15
	 */
	public function numClean(f:Float):Float{
		return Math.round(f * 100) / 100;
	}
	
	/**
	 * max length for strings, usefull for tables
	 */
	public function short(text:String, length:Int){
		if(text==null) return "";
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
	
	/**
	 * Prints a measuring unit 
	 */
	public function unit(u:Unit,?plural=false){
		t = sugoi.i18n.Locale.texts;
		return switch(u){
			case Kilogram: 		t._("Kg.||kilogramms");
			case Gram: 			t._("g.||gramms");
			case null,Piece: 	if(plural) t._("pieces||unit of a product)") else t._("piece||unit of a product)");
			case Litre: 		t._("L.||liter");
			case Centilitre: 	t._("cl.||centiliter");
			case Millilitre: 	t._("ml.||milliliter");
		}
	}
	
	public function currency(){
		if (App.current.user == null || App.current.user.amap == null){
			return "€";
		}else{
			return App.current.user.amap.getCurrency();	
		}
		
	}
	
	public static var DAYS = null;
	public static var MONTHS = null;
	public static var HOURS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
	public static var MINUTES = [0,5,10,15,20,25,30,35,40,45,50,55];
	
	
	public function initDate(){
		t = sugoi.i18n.Locale.texts;
		DAYS = [t._("Sunday"), t._("Monday"), t._("Tuesday"), t._("Wednesday"), t._("Thursday"), t._("Friday"), t._("Saturday")];
		MONTHS = [t._("January"), t._("February"), t._("March"), t._("April"), t._("May"), t._("June"), t._("July"), t._("August"), t._("September"), t._("October"), t._("November"), t._("December")];
		this.DAYS = DAYS;
		this.MONTHS = MONTHS;
		this.HOURS = HOURS;
		this.MINUTES = MINUTES;
	}
	
	/**
	 * human readable date + time
	 */
	public function hDate(date:Date):String {
		if (date == null) return t._("no date set");
		if (DAYS == null) initDate();
		
		var out = DAYS[date.getDay()] + " " + date.getDate() + " " + MONTHS[date.getMonth()];
		out += " " + date.getFullYear();
		if ( date.getHours() != 0 || date.getMinutes() != 0){
			
			out += " " + sugoi.i18n.Locale.texts._("at||time : at 12:30") + " " + StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		}
		return out;
	}

	/**
	 *  Human readable hour
	 */
	public function hHour(date:Date){
		return StringTools.lpad(date.getHours().string(), "0", 2) + ":" + StringTools.lpad(date.getMinutes().string(), "0", 2);
	}

	public function oHour(hour:Int,min:Int){
		return StringTools.lpad(hour.string(), "0", 2) + ":" + StringTools.lpad(min.string(), "0", 2);
	}
	
	/**
	 *  human readable date
	 */
	public function dDate(date:Date):String {
		if (date == null) return t._("no date set");
		if (DAYS == null) initDate();
		return DAYS[date.getDay()] + " " + date.getDate() + " " + MONTHS[date.getMonth()] + " " + date.getFullYear();
	}
	
	public function fromTimestamp(ts:String){
		return Date.fromTime(Std.parseInt(ts)*1000.0);
	}

	public function getDate(date:Date) {
		if (date == null) return null;
		if (DAYS == null) initDate();
		
		return {
			dow: DAYS[date.getDay()],
			d : date.getDate(),
			m: MONTHS[date.getMonth()],
			y: date.getFullYear(),			
			h: StringTools.lpad(Std.string(date.getHours()),"0",2),
			i: StringTools.lpad(Std.string(date.getMinutes()),"0",2)
		};
	}
	
	public function getProductImage(e):String {
		return Std.string(e).substr(2).toLowerCase()+".png";
	}

	public function prepare(orders:Iterable<db.UserContract>){
		return service.OrderService.prepare(orders);
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
					var here = sugoi.Web.getURI();
					if (!plugin.Tutorial.match(uri,here)) {
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
		
	
	public function isAmap(){
		return App.current.user.amap.groupType == db.Amap.GroupType.Amap;
	}

	
	public function getBasket(userId, placeId, date){
		var user = getUser(userId);
		var place = db.Place.manager.get(placeId, false);
		return db.Basket.getOrCreate(user, place, date);
	}
	
	public function getPlatform(){
		return #if neko "Neko" #else "PHP" #end ;
	}
	
	/** 
	 * Smart quantity (tm) : displays human readable quantity
	 * 0.33 x Lemon 12kg => 2kg Lemon
	 */ 
	public function smartQt(orderQt:Float, productQt:Float, unit:Unit):String{
		if (orderQt == null) orderQt = 1;
		if (productQt == null) productQt = 1;
		if (unit == null) unit = Unit.Piece;
		if (unit == Unit.Piece && productQt == 1 ){
			return this.formatNum(orderQt);
		}else{
			return this.formatNum(orderQt * productQt) + "&nbsp;" + this.unit(unit,orderQt*productQt>1);	
		}
		
	}

}
