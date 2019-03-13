package controller.api;
import haxe.Json;
import tink.core.Error;
import Common;
import db.Amap;
import tools.ArrayTool;
using tools.ObjectListTool;
using Lambda;

class Shop extends Controller
{
	/**
		List available categories
		@doc https://app.swaggerhub.com/apis/Cagette.net/Cagette.net/0.9.2#/shop/get_shop_categories
	 */
	public function doCategories(args:{date:String, place:db.Place}){
		
		var out = new Array<CategoryInfo>();
		var group = args.place.amap;
		
		if (group.flags.has(ShopCategoriesFromTaxonomy)){
			
			//TAXO CATEGORIES
			var taxoCategs = db.TxpCategory.manager.search(true,{orderBy:displayOrder});
			for (txp  in taxoCategs){
				
				var c : CategoryInfo = {id:txp.id, name:txp.name,image:'/img/taxo/${txp.image}.png',subcategories:[]};
				for (sc in txp.getSubCategories()){
					c.subcategories.push({id:sc.id,name:sc.name});
				}
				out.push(c);
			}
			
		}else{
			
			//CUSTOM CATEGORIES
			var catGroups = db.CategoryGroup.get(group);
			for (cat  in catGroups){
				
				var c : CategoryInfo = {id:cat.id, name:cat.name, subcategories:[]};
				for ( sc in cat.getCategories() ){
					c.subcategories.push({id:sc.id,name:sc.name});
				}
				out.push(c);
			}
		}
		
		Sys.print(Json.stringify({success:true,categories:out}));	
	}

	/**
		Get All available products
	**/
	public function doAllProducts(args:{date:String, place:db.Place}){
		
		if ( args == null ) throw "You should provide a date and a place";
		//var categsFromTaxo = args.place.amap.flags.has(ShopCategoriesFromTaxonomy);	
		var categsFromTaxo = true;
			
		var products = getProducts(args.place, Date.fromString(args.date), categsFromTaxo );
		
		//to productInfos
		var productsInfos : Array<ProductInfo> = products.map( function(p) return p.infos(categsFromTaxo,true) ).array();
		Sys.print(Json.stringify( {products:productsInfos} ));									
	}
	
	/**
	 * @doc https://app.swaggerhub.com/apis/Cagette.net/Cagette.net/0.9.2#/shop/get_shop_products
	 */
	public function doProducts(args:{date:String, place:db.Place, ?category:Int, ?subcategory:Int}){
		
		if ( args == null || (args.category == null && args.subcategory == null)) throw "You should provide a category Id or a subcategory Id";
		//need some optimization : populating all thses objects eats memory, and we need only the ids !		
		var products = getProducts(args.place, Date.fromString(args.date), args.place.amap.flags.has(ShopCategoriesFromTaxonomy));
		var pids  = products.getIds();
		var categsFromTaxo = args.place.amap.flags.has(ShopCategoriesFromTaxonomy);		
		var catName = "undefined category";
		
		if( categsFromTaxo ){
			
			/**
			 * Use Taxonomy : 
			 * 	- Category is TxpCatgory
			 * 	- Subcategory us TxpSubCategory
			 * 	- Products are linked to TxpProduct which belongs to a TxpCatgory and a TxpSubCategory
			 */
			var sql = "";
			
			if (args.subcategory != null){
				
				sql = 'SELECT p.* FROM Product p, TxpProduct tp, TxpSubCategory sc 
				WHERE p.txpProductId = tp.id 
				AND tp.subCategoryId = sc.id 
				AND sc.id = ${args.subcategory}
				AND p.id IN ( ${pids.join(",")} )';
				
				var cat = db.TxpSubCategory.manager.get(args.subcategory, false);
				if (cat == null) throw 'unknown subcategory #' + args.subcategory;
				catName = cat.name;
				
			}else if (args.category != null){
				
				sql = 'SELECT p.* FROM Product p, TxpProduct tp, TxpCategory c 
				WHERE p.txpProductId = tp.id 
				AND tp.categoryId = c.id 
				AND c.id = ${args.category}
				AND p.id IN ( ${pids.join(",")} )';
				
				var cat = db.TxpCategory.manager.get(args.subcategory, false);
				if (cat == null) throw 'unknown category #' + args.category;
				catName = cat.name;
			}
			
			products = db.Product.manager.unsafeObjects(sql,false).array();
			
		}else{
			
			/**
			 * Use custom categories : 
			 * 	- Category is CategoryGroup
			 * 	- Subcategory is Category
			 *  - Products are tagged with ProductCategory
			 */		
			var sql = "";
			
			if (args.subcategory != null){
				
				sql = 'SELECT p.* FROM Product p, ProductCategory pc, Category c 
				WHERE pc.productId = p.id 
				AND pc.categoryId = c.id 
				AND c.id = ${args.subcategory}
				AND p.id IN ( ${pids.join(",")} )';
				
				var cat = db.Category.manager.get(args.subcategory, false);
				if (cat == null) throw 'unknown subcategory #' + args.subcategory;
				catName = cat.name;
				
			}else if (args.category != null){
				
				sql = 'SELECT p.* FROM Product p, ProductCategory pc, Category c, CategoryGroup cg 
				WHERE pc.productId = p.id 
				AND pc.categoryId = c.id 
				AND c.categoryGroupId = cg.id
				AND cg.id = ${args.category}
				AND p.id IN ( ${pids.join(",")} )';
				
				var cat = db.CategoryGroup.manager.get(args.category, false);
				if (cat == null) throw 'unknown category #' + args.category;
				catName = cat.name;
			}
			
			products = db.Product.manager.unsafeObjects(sql,false).array();
		}
		
		//to productInfos
		var products : Array<ProductInfo> = products.map( function(p) return p.infos(categsFromTaxo,true) ).array();
		
		if (args.category != null){
			Sys.print(Json.stringify( {success:true, products:products, category:catName} ));					
		}else{
			Sys.print(Json.stringify( {success:true, products:products, subcategory:catName} ));				
		}		
	}
	
	/**
		Infos to init the shop : place + order end dates + vendor infos + payment infos
	**/
	public function doInit(args:{place:db.Place, date:String}){
		
		var out = { 
			place : args.place.getInfos(),
			orderEndDates : new Array<{date:String,contracts:Array<String>}>(),
			vendors : new Array<VendorInfos>(),
			paymentInfos : service.PaymentService.getPaymentInfosString(args.place.amap)
		};
		
		//order end dates
		var contracts = db.Contract.getActiveContracts(args.place.amap);
	
		for (c in Lambda.array(contracts)) {			
			if (c.type != db.Contract.TYPE_VARORDER) contracts.remove(c);//only varying orders
			if (!c.isVisibleInShop()) contracts.remove(c);
		}
		
		var date = Date.fromString(args.date);
		var now = Date.now();
		var cids = Lambda.map(contracts, function(c) return c.id);
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

		var distribs = db.Distribution.manager.search(($contractId in cids) && $orderStartDate <= now && $orderEndDate >= now && $date > d1 && $end < d2 && $place == args.place, false);
		var distribByDate = ArrayTool.groupByDate(Lambda.array(distribs), "orderEndDate");
		out.orderEndDates  = [];
		for ( k in distribByDate.keys() ) {
			out.orderEndDates.push( {date:k , contracts: distribByDate.get(k).map( function(x) return x.contract.name)} );	
		}

		//vendors
		var vendors = [];
		for( d in distribs){
			vendors.push(d.contract.vendor.infos());
		}
		out.vendors = vendors.deduplicate();
		
		
		Sys.print(Json.stringify( out ));	
	}
	
	private function getProductInfos(place:db.Place, date, ?categsFromTaxo = false):Array<ProductInfo>{
		var products = getProducts(place, date, categsFromTaxo);
		return Lambda.array(Lambda.map(products, function(p) return p.infos(categsFromTaxo)));		
	}
	
	/**
	 * Get the available products list
	 */
	private function getProducts(place:db.Place,date,?categsFromTaxo=false):Array<db.Product> {

		var contracts = db.Contract.getActiveContracts(place.amap);
	
		for (c in Lambda.array(contracts)) {			
			if (c.type != db.Contract.TYPE_VARORDER) contracts.remove(c);//only varying orders
			if (!c.isVisibleInShop()) contracts.remove(c);
		}
		
		var now = Date.now();
		var cids = Lambda.map(contracts, function(c) return c.id);
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

		var distribs = db.Distribution.manager.search(($contractId in cids) && $orderStartDate <= now && $orderEndDate >= now && $date > d1 && $end < d2 && $place == place, false);
		
		var cids = Lambda.map(distribs, function(d) return d.contract.id);
		return Lambda.array(db.Product.manager.search(($contractId in cids) && $active==true, { orderBy:name }, false));
		
	}

	/**
	 * record order
	 */
	public function doSubmit() {
		var post:{cart:OrderInSession} = haxe.Json.parse(sugoi.Web.getPostData());

		
		if(post==null) throw 'Payload is empty';
		if(post.cart==null) throw 'Cart is empty';
		
		var order : OrderInSession = post.cart;
		app.session.data.order = order;

		Sys.print(haxe.Json.stringify({success:true}));
		
	}
	
	
	
}