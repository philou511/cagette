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
	public var feesRate : SInt; //fees in percentage
	
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
		return quantity + "x" + product.name;
	}
	
	public function hasInvertSharedOrder():Bool{
		return flags.has(InvertSharedOrder);
	}
	
	/**
	 * Prepare un dataset simple pret pour affichage ou export csv.
	 */
	public static function prepare(orders:Iterable<db.UserContract>):Array<UserOrder> {
		var out = new Array<UserOrder>();
		var orders = Lambda.array(orders);
		var view = App.current.view;
		var t = sugoi.i18n.Locale.texts;
		for (o in orders) {
		
			var x : UserOrder = cast { };
			x.id = o.id;
			x.userId = o.user.id;
			x.userName = o.user.getCoupleName();
			x.userEmail = o.user.email;
			
			//shared order
			if (o.user2 != null){
				x.userId2 = o.user2.id;
				x.userName2 = o.user2.getCoupleName();
				x.userEmail2 = o.user2.email;
			}
			
			//deprecated
			x.productId = o.product.id;
			x.productRef = o.product.ref;
			x.productQt = o.product.qt;
			x.productUnit = o.product.unitType;
			x.productPrice = o.productPrice;
			x.productImage = o.product.getImage();
			x.productHasFloatQt = o.product.hasFloatQt;
			x.productHasVariablePrice = o.product.variablePrice;
			//new way
			x.product = o.product.infos();
			x.product.price = o.productPrice;//do not use current price, but price of the order

			
			x.quantity = o.quantity;
			
			//smartQt
			if (x.quantity == 0.0){
				x.smartQt = t._("Canceled");
			}else if(x.productHasFloatQt || x.productHasVariablePrice){
				x.smartQt = view.smartQt(x.quantity, x.productQt, x.productUnit);
			}else{
				x.smartQt = Std.string(x.quantity);
			}
			if (x.productHasFloatQt || x.productHasVariablePrice || x.productQt==null || x.productUnit==null){
				x.productName = o.product.name;	
			}else{
				x.productName = o.product.name + " " + view.formatNum(x.productQt) +" "+ view.unit(x.productUnit,x.productQt>1);	
			}
			
			x.subTotal = o.quantity * o.productPrice;

			var c = o.product.contract;
			
			if ( o.feesRate!=0 ) {
				
				x.fees = x.subTotal * (o.feesRate/100);
				x.percentageName = c.percentageName;
				x.percentageValue = o.feesRate;
				x.total = x.subTotal + x.fees;
				
			}else {
				x.total = x.subTotal;
			}
			
			//flags
			x.paid = o.paid;
			x.invertSharedOrder = o.flags.has(InvertSharedOrder);
			x.contractId = c.id;
			x.contractName = c.name;
			x.canModify = o.canModify(); 
			
			out.push(x);
		}
		
		return sort(out);
	}
	
	public static function sort(orders:Array<UserOrder>){
		
		//order by lastname (+lastname2 if exists), then contract
		orders.sort(function(a, b) {
			
			if (a.userName + a.userId + a.userName2 + a.userId2 + a.contractId > b.userName + b.userId + b.userName2 + b.userId2 + b.contractId ) {
				
				return 1;
			}
			if (a.userName + a.userId + a.userName2 + a.userId2 + a.contractId < b.userName + b.userId + b.userName2 + b.userId2 + b.contractId ) {
				 
				return -1;
			}
			return 0;
		});
		
		return orders;
	}
	
	/**
	 * On peut modifier si ça na pas deja été payé + commande encore ouvertes
	 */
	function canModify():Bool {
	
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
	 * Store a product Order
	 * 
	 * @param	quantity
	 * @param	productId
	 */
	public static function make(user:db.User, quantity:Float, product:db.Product, ?distribId:Int, ?paid:Bool, ?user2:db.User, ?invert:Bool):db.UserContract {
		
		var t = sugoi.i18n.Locale.texts;

		if(product.contract.type==db.Contract.TYPE_VARORDER && distribId==null) throw "You have to provide a distribId";
		
		//multiweight : make one row per product
		if (product.multiWeight && quantity > 1.0){
			if (product.multiWeight && quantity != Math.abs(quantity)) throw t._("multi-weighing products should be ordered only with integer quantities");
			
			var o = null;
			for ( i in 0...Math.round(quantity)){
				o = make(user, 1, product, distribId, paid, user2, invert);
			}			
			return o;
		}
		
		var t = sugoi.i18n.Locale.texts;
		
		//checks
		if (quantity <= 0) return null;
		
		//check for previous orders on the same distrib
		var prevOrders = new List<db.UserContract>();
		if (distribId == null) {
			prevOrders = db.UserContract.manager.search($product==product && $user==user, true);
		}else {
			prevOrders = db.UserContract.manager.search($product==product && $user==user && $distributionId==distribId, true);
		}
		
		//Create order object
		var o = new db.UserContract();
		o.product = product;
		o.quantity = quantity;
		o.productPrice = product.price;
		if (product.contract.hasPercentageOnOrders()) {
			o.feesRate = product.contract.percentageValue;
		}
		o.user = user;
		if (user2 != null) {
			o.user2 = user2;
			if (invert != null) o.flags.set(InvertSharedOrder);
		}
		if (paid != null) o.paid = paid;
		if (distribId != null) o.distribution = db.Distribution.manager.get(distribId);
		
		//cumulate quantities if there is a similar previous order
		if (prevOrders.length > 0 && !product.multiWeight) {
			for (prevOrder in prevOrders) {
				//if (!prevOrder.paid) {
					o.quantity += prevOrder.quantity;
					prevOrder.delete();
				//}
			}
		}
		
		//create a basket object
		if (distribId != null){
			var dist = o.distribution;
			var basket = db.Basket.getOrCreate(user, dist.place, dist.date);			
			o.basket = basket;			
		}
		
		o.insert();
		
		//Stocks
		if (o.product.stock != null) {
			var c = o.product.contract;
			if (c.hasStockManagement()) {
				//trace("stock for "+quantity+" x "+product.name);
				if (o.product.stock == 0) {
					if (App.current.session != null) {
						App.current.session.addMessage(t._("There is no more '::productName::' in stock, we removed it from your order", {productName:o.product.name}), true);
					}
					o.quantity -= quantity;
					if ( o.quantity <= 0 ) {
						o.delete();
						return null;	
					}
				}else if (o.product.stock - quantity < 0) {
					var canceled = quantity - o.product.stock;
					o.quantity -= canceled;
					o.update();
					
					if (App.current.session != null) {
						var msg = t._("We reduced your order of '::productName::' to quantity ::oQuantity:: because there is no available products anymore", {productName:o.product.name, oQuantity:o.quantity});
						App.current.session.addMessage(msg, true);
					}
					o.product.lock();
					o.product.stock = 0;
					o.product.update();
					App.current.event(StockMove({product:o.product, move:0 - (quantity - canceled) }));
					
				}else {
					o.product.lock();
					o.product.stock -= quantity;
					o.product.update();	
					App.current.event(StockMove({product:o.product, move:0 - quantity}));
				}
			}	
		}
		return o;
	}
	
	
	/**
	 * Edit an existing order (quantity)
	 */
	public static function edit(order:db.UserContract, newquantity:Float, ?paid:Bool , ?user2:db.User,?invert:Bool) {
		
		var t = sugoi.i18n.Locale.texts;
		
		order.lock();
		
		if (newquantity == null) newquantity = 0;
		
		//paid
		if (paid != null) {
			order.paid = paid;
		}else {
			if (order.quantity < newquantity) order.paid = false;	
		}
		
		//shared order
		if (user2 != null){
			order.user2 = user2;	
			if (invert == true) order.flags.set(InvertSharedOrder);
			if (invert == false) order.flags.unset(InvertSharedOrder);
		}else{
			order.user2 = null;
			order.flags.unset(InvertSharedOrder);
		}

		//stocks
		var e : Event = null;
		if (order.product.stock != null) {
			var c = order.product.contract;
			
			if (c.hasStockManagement()) {
				
				if (newquantity < order.quantity) {

					//on commande moins que prévu : incrément de stock						
					order.product.lock();
					order.product.stock +=  (order.quantity-newquantity);
					e = StockMove({product:order.product, move:0 - (order.quantity-newquantity) });
					
				}else {
				
					//on commande plus que prévu : décrément de stock
					var addedquantity = newquantity - order.quantity;
					
					if (order.product.stock - addedquantity < 0) {
						
						//stock is not enough, reduce order
						newquantity = order.quantity + order.product.stock;
						if( App.current.session!=null) App.current.session.addMessage(t._("We reduced your order of '::productName::' to quantity ::oQuantity:: because there is no available products anymore", {productName:order.product.name, oQuantity:newquantity}), true);
						
						e = StockMove({product:order.product, move: 0 - order.product.stock });
						
						order.product.lock();
						order.product.stock = 0;
						
					}else{
						
						//stock is big enough
						order.product.lock();
						order.product.stock -= addedquantity;
						
						e = StockMove({ product:order.product, move: 0 - addedquantity });
					}					
				}				
				order.product.update();					
			}	
		}
		
		//update order
		if (newquantity == 0) {
			order.quantity = 0;			
			order.paid = true;
			order.update();
		}else {
			order.quantity = newquantity;
			order.update();				
		}	

		App.current.event(e);	

		return order;
	}
	
	/**
	 * Get orders grouped by products. 
	 */
	public static function getOrdersByProduct( options:{?distribution:db.Distribution,?startDate:Date,?endDate:Date}, ?csv = false):Array<OrderByProduct>{
		var view = App.current.view;
		var t = sugoi.i18n.Locale.texts;
		var where = "";
		var exportName = "";
		
		//options
		if (options.distribution != null){
			
			//by distrib
			var d = options.distribution;
			exportName = t._("Delivery ::contractName:: of the ", {contractName:d.contract.name}) + d.date.toString().substr(0, 10);
			where += ' and p.contractId = ${d.contract.id}';
			if (d.contract.type == db.Contract.TYPE_VARORDER ) {
				where += ' and up.distributionId = ${d.id}';
			}
			
		}else if(options.startDate!=null && options.endDate!=null){
			
			//by dates
			//exportName = "Distribution "+d.contract.name+" du " + d.date.toString().substr(0, 10);
			
		}
	
		var sql = '
			select 
			SUM(quantity) as quantity,
			p.id as pid,
			p.name as pname,
			p.price as price,
			p.vat as vat,
			p.ref as ref,
			SUM(quantity*up.productPrice) as total
			from UserContract up, Product p 
			where up.productId = p.id 
			$where
			group by p.id
			order by pname asc; ';
			
		var res = sys.db.Manager.cnx.request(sql).results();	
		var orders = [];

		//populate with full product names
		for ( r in res){
			var p = db.Product.manager.get(r.pid, false);
			var o : OrderByProduct = {
				quantity:1.0 * r.quantity,
				smartQt:"",
				pid:p.id,
				pname:p.name,
				ref:r.ref,
				priceHT:null,
				priceTTC:r.price,
				vat:p.vat,
				total:1.0 * r.quantity * r.price,
				weightOrVolume:"",
			};

			//smartQt
			if( p.hasFloatQt || p.variablePrice ){
				o.smartQt = view.smartQt(o.quantity, p.qt, p.unitType);
			}else{
				o.smartQt = Std.string(o.quantity);
			}
			o.weightOrVolume = view.smartQt(o.quantity, p.qt, p.unitType);
			
			if ( /*p.hasFloatQt || p.variablePrice ||*/ p.qt==null || p.unitType==null){
				o.pname = p.name;	
			}else{
				o.pname = p.name + " " + view.formatNum(p.qt) +" " + view.unit(p.unitType, o.quantity > 1);					
			}

			//special case : if product is multiweight, we should count the records number ( and not SUM quantities )
			if (p.multiWeight){
				sql = 'select 
				COUNT(up.id) as quantity 
				from UserContract up, Product p 
				where up.productId = p.id and up.quantity > 0 and p.id=${p.id}
				$where';
				var count = sys.db.Manager.cnx.request(sql).getIntResult(0);					
				o.smartQt = ""+count;
			}			
			
			orders.push(o);
			
		}
		
		
		if (csv) {
			var data = new Array<Dynamic>();
			
			for (o in orders) {
				data.push({
					"quantity":view.formatNum(o.quantity),
					"pname":o.pname,
					"ref":o.ref,
					"priceTTC":view.formatNum(o.priceTTC),
					"total":view.formatNum(o.total)					
				});				
			}

			sugoi.tools.Csv.printCsvDataFromObjects(data, ["quantity", "pname","ref", "priceTTC", "total"],"Export-"+exportName+"-par produits");
			return null;
		}else{
			return orders;		
		}
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
		
		var orders = db.UserContract.prepare(orders);
		
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
	
	/**
	 * Confirms an order : create real orders from tmp orders in session
	 * @param	order
	 */
	public static function confirmSessionOrder(tmpOrder:OrderInSession){
		var orders = [];
		var user = db.User.manager.get(tmpOrder.userId);
		for (o in tmpOrder.products){
			o.product = db.Product.manager.get(o.productId);
			orders.push( db.UserContract.make(user, o.quantity, o.product, o.distributionId) );
		}
		
		App.current.event(MakeOrder(orders));
		App.current.session.data.order = null;	
		
		return orders;
	}
	
	public static function getTotalPrice(tmpOrder:OrderInSession){
		var t = 0.0;
		for ( o in tmpOrder.products){				
			var p = db.Product.manager.get(o.productId, false);
			t += o.quantity * p.getPrice();				
		}
		return t;
	}

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
