package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * a product order 
 */
class UserContract extends Object
{
	public var id : SId;
	
	@formPopulate("populate") @:relation(userId)
	public var user : User;
	
	//shared order
	@formPopulate("populate") @:relation(userId2)
	public var user2 : SNull<User>;
	
	public var quantity : SFloat;
	
	@formPopulate("populateProducts") @:relation(productId)
	public var product : Product;
	
	//store price (1 unit price) and fees (percentage not amount ) rate when the order is done
	public var productPrice : SFloat;
	public var feesRate : SFloat; //fees in percentage
	
	public var paid : SBool;
	
	//if not null : varying orders
	@:relation(distributionId)
	public var distribution:SNull<db.Distribution>;

	
	@:relation(basketId)
	public var basket:SNull<db.Basket>;
	
	public var date : SDateTime;	
	public var flags : SFlags<OrderFlags>;
	
	public function new() 
	{
		super();
		quantity = 1;
		paid = false;
		date = Date.now();
		flags = cast 0;
		feesRate = 0;
	}
	
	public function populate() {
		return App.current.user.getAmap().getMembersFormElementData();
	}
	
	
	/**
	 * For shared alternated orders in AMAP contracts
	 * @param	distrib
	 * @return	false -> user , true -> user2
	 */
	public function getWhosTurn(distrib:Distribution) {
		if (distrib == null) throw "distribution is null";
		if (user2 == null) throw "this contract is not shared";
		
		//compter le nbre de distrib pour ce contrat
		var c = Distribution.manager.count( $contract == product.contract && $date >= product.contract.startDate && $date <= distrib.date);		
		var r = c % 2 == 0;
		if (flags.has(InvertSharedOrder)){
			return !r;
		}else{
			return r;
		}
	}
	
	override public function toString() {
		if(product==null) return quantity +"x produit inconnu";
		return user.getName()+" : "+tools.FloatTool.clean(quantity) + " x " + product.getName();
	}
	
	public function hasInvertSharedOrder():Bool{
		return flags.has(InvertSharedOrder);
	}
	
	/**
	 * On peut modifier si ça na pas deja été payé + commande encore ouvertes
	 */
	public function canModify():Bool {
	
		var can = false;
		if (this.product.contract.type == db.Contract.TYPE_VARORDER) {
			
			if (this.distribution.orderStartDate == null) {
				can = true;
			}else {
				var n = Date.now().getTime();
				can = n > this.distribution.orderStartDate.getTime() && n < this.distribution.orderEndDate.getTime();
			}
		}else {
			can = this.product.contract.isUserOrderAvailable();
		}
		
		return can && !this.paid;
	}
	
	/**
	 * get users orders for a distribution
	 */
	public static function getOrders(contract:db.Contract, ?distribution:db.Distribution, ?csv = false):Array<UserOrder>{
		var view = App.current.view;
		var orders = new Array<db.UserContract>();
		if (contract.type == db.Contract.TYPE_VARORDER ) {
			orders = contract.getOrders(distribution);	
		}else {
			orders = contract.getOrders();
		}
		
		var orders = service.OrderService.prepare(orders);
		
		//CSV export
		if (csv) {
			var t = sugoi.i18n.Locale.texts;			
			var data = new Array<Dynamic>();
			
			for (o in orders) {
				data.push( { 
					"name":o.userName,
					"productName":o.productName,
					"price":view.formatNum(o.productPrice),
					"quantity":view.formatNum(o.quantity),
					"fees":view.formatNum(o.fees),
					"total":view.formatNum(o.total),
					"paid":o.paid
				});				
			}
			
			var exportName = "";
			if (distribution != null){
				exportName = contract.amap.name + " - " + t._("Delivery ::contractName:: ", {contractName:contract.name}) + distribution.date.toString().substr(0, 10);					
			}else{
				exportName = contract.amap.name + " - " + contract.name;
			}
			
			sugoi.tools.Csv.printCsvDataFromObjects(data, ["name",  "productName", "price", "quantity", "fees", "total", "paid"], exportName+" - " + t._("Per member"));			
			return null;
		}else{
			return orders;
		}
		
	}
	
	/**
	 * Get the orders (varying orders) of a user for a multidistrib ( distribs with same day + same place )
	 * 
	 * @param	distribKey "$date|$placeId"
	 */
	public static function getUserOrdersByMultiDistrib(distribKey:String, user:db.User,group:db.Amap):Array<db.UserContract>{	
		//var contracts = db.Contract.getActiveContracts(group);
		var contracts = db.Contract.manager.search($amap == group, false); //should be able to edit a contract which is closed
		for ( c in Lambda.array(contracts)){
			if (c.type == db.Contract.TYPE_CONSTORDERS){
				contracts.remove(c); //only varying orders
			}
		}
		
		var cids = Lambda.map(contracts, function(x) return x.id);
		var start = Date.fromString(distribKey.split("|")[0] + " 00:00:00");
		var end = Date.fromString(distribKey.split("|")[0] + " 23:59:00");
		var ds = db.Distribution.manager.search($date > start && $date < end && ($contractId in cids), false);
		var out = [];
		for (d in ds) {
			out = out.concat(Lambda.array(user.getOrdersFromDistrib(d)));
		}
		
		return out;
	}
	
	/*public static function getTotalPrice(tmpOrder:OrderInSession){
		var t = 0.0;
		for ( o in tmpOrder.products){				
			var p = db.Product.manager.get(o.productId, false);
			t += o.quantity * p.getPrice();				
		}
		return t;
	}*/

	function check(){
		if(quantity==null) quantity == 1;
	}

	override function update(){
		check();
		super.update();
	}

	override function insert(){
		check();
		super.insert();
	}
}
