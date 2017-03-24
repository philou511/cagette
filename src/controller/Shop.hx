package controller;
import Common;
import tools.ArrayTool;
class Shop extends sugoi.BaseController
{
	
	var distribs : List<db.Distribution>;
	var contracts : List<db.Contract>;

	@tpl('shop/default.mtt')
	public function doDefault(place:db.Place,date:Date) {
		
		view.products = getProducts(place,date);
		view.place = place;
		view.date = date;
		
		view.infos = ArrayTool.groupByDate(Lambda.array(distribs),"orderEndDate");
	}
	
	/**
	 * prints the full product list and current cart in JSON
	 */
	public function doInit(place:db.Place,date:Date) {
		
		//init order serverside if needed		
		var order :Order = app.session.data.order; 
		if ( order == null) {
			app.session.data.order = order = { products:new Array<{productId:Int,quantity:Float}>() };
		}
		
		var products = [];
		var categs = new Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>();		
		
		if (place.amap.flags.has(db.Amap.AmapFlags.ShopCategoriesFromTaxonomy)){
			
			//TAXO CATEGORIES
			products = getProducts(place, date, true);
		}else{
			
			//CUSTOM CATEGORIES
			products = getProducts(place, date, false);
		}
		
		categs = place.amap.getCategoryGroups();

		Sys.print( haxe.Serializer.run( {products:products,categories:categs,order:order} ) );
	}
	
	
	
	/**
	 * Get the available products list
	 */
	private function getProducts(place,date,?categsFromTaxo=false):Array<ProductInfo> {

		contracts = db.Contract.getActiveContracts(app.user.amap);
	
		for (c in Lambda.array(contracts)) {
			//only varying orders
			if (c.type != db.Contract.TYPE_VARORDER) {
				contracts.remove(c);
			}
			
			if (!c.isVisibleInShop()) {
				contracts.remove(c);
			}
			
		}
		var now = Date.now();
		var cids = Lambda.map(contracts, function(c) return c.id);
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

		distribs = db.Distribution.manager.search(($contractId in cids) && $orderStartDate <= now && $orderEndDate >= now && $date > d1 && $end < d2 && $place ==place, false);
		var cids = Lambda.map(distribs, function(d) return d.contract.id);

		var products = db.Product.manager.search(($contractId in cids) && $active==true, { orderBy:name }, false);
		
		return Lambda.array(Lambda.map(products, function(p) return p.infos(categsFromTaxo)));
	}
	
	/**
	 * Overlay window loaded by Ajax for product Infos
	 */
	@tpl('shop/productInfo.mtt')
	public function doProductInfo(p:db.Product) {
		view.p = p.infos();
		view.product = p;
		view.vendor = p.contract.vendor;
	}
	
	/**
	 * receive cart
	 */
	public function doSubmit() {
		
		var order : Order = haxe.Json.parse(app.params.get("data"));
		app.session.data.order = order;
		
	}
	
	/**
	 * add a product to the cart
	 */
	public function doAdd(productId:Int, quantity:Int) {
	
		var order :Order =  app.session.data.order;
		if ( order == null) order = { products:new Array<{productId:Int,quantity:Float}>() };
		
		order.products.push( { productId:productId, quantity:quantity } );
		
		Sys.print( haxe.Json.stringify( {success:true} ) );
		
	}
	
	/**
	 * remove a product from cart 
	 */
	public function doRemove(pid:Int) {
	
		var order :Order =  app.session.data.order;
		if ( order == null) return;
		
		for ( p in order.products.copy()) {
			if (p.productId == pid) {
				order.products.remove(p);
			}
			
		}
		
		Sys.print( haxe.Json.stringify( { success:true } ) );		
	}
	
	
	/**
	 * valider la commande et selectionner les distributions
	 */
	public function doValidate(place:db.Place,date:Date){

		var order : OrderInSession = app.session.data.order;
		if (order == null || order.products == null || order.products.length == 0) {
			throw Error("/shop", "Vous devez réaliser votre commande avant de valider.");
		}
		
		if (place == null) throw "place cannot be null";
		if (date == null) throw "date cannot be null";
		

		var products = getProducts(place, date);

		var errors = [];
		var orders = [];
		
		for (o in order.products) {

			var p = db.Product.manager.get(o.productId, false);
			//check if the product is available
			if (Lambda.find(products, function(x) return x.id == o.productId) == null) {
				errors.push("Le produit \"" + p.name+"\" n'est pas disponible pour cette distribution");
				continue;
			}

			//find distrib
			var d = Lambda.find(distribs, function(d) return d.contract.id == p.contract.id);
			if ( d == null ){
				errors.push("Le produit \"" + p.name+"\" n'est pas disponible pour cette distribution");
				continue;
			}

			//make order
			orders.push( db.UserContract.make(app.user,o.quantity, p, d.id) );

		}
		
		//payment transaction
		app.event(MakeOrder(orders));

		if (errors.length > 0) {
			app.session.addMessage(errors.join("<br/>"), true);
			//app.logError("params : "+App.current.params.toString()+"\n \n"+errors.join("\n"));

		}

		app.session.data.order = null;
		if (app.user.amap.hasPayments()){
			
			throw Ok("/transaction/pay/"+place.id+"/"+date, "Votre commande a bien été enregistrée. Vous pouvez maintenant procéder au paiement de votre commande.");
		}else{
			throw Ok("/contract", "Votre commande a bien été enregistrée");	
		}

	}

	
}