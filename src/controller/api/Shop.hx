package controller.api;
import haxe.Json;
import tink.core.Error;
import Common;

class Shop extends Controller
{
	/**
	 * @doc https://app.swaggerhub.com/apis/Cagette.net/Cagette.net/0.9.2#/shop/get_shop_categories
	 */
	public function doCategories(args:{date:String, place:db.Place}){
		
		var out = new Array<CategoryInfo>();
		var group = args.place.amap;
		
		if (group.flags.has(db.Amap.AmapFlags.ShopCategoriesFromTaxonomy)){
			
			//TAXO CATEGORIES
			var taxoCategs = db.TxpCategory.manager.all(false);
			for (txp  in taxoCategs){
				
				var c : CategoryInfo = {id:txp.id, name:txp.name, subcategories:[]};
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
	 * @doc https://app.swaggerhub.com/apis/Cagette.net/Cagette.net/0.9.2#/shop/get_shop_products
	 */
	public function doProducts(args:{date:String, place:db.Place, ?category:Int, ?subcategory:Int}){
		
		var products = getProducts(args.place, Date.fromString(args.date), args.place.amap.flags.has(db.Amap.AmapFlags.ShopCategoriesFromTaxonomy));
		
		Sys.print(Json.stringify({success:true,products:products}));	
		
	}
	
	
	/**
	 * Get the available products list
	 */
	private function getProducts(place:db.Place,date,?categsFromTaxo=false):Array<ProductInfo> {

		var contracts = db.Contract.getActiveContracts(place.amap);
	
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

		var distribs = db.Distribution.manager.search(($contractId in cids) && $orderStartDate <= now && $orderEndDate >= now && $date > d1 && $end < d2 && $place == place, false);
		
		var cids = Lambda.map(distribs, function(d) return d.contract.id);
		var products = db.Product.manager.search(($contractId in cids) && $active==true, { orderBy:name }, false);
		return Lambda.array(Lambda.map(products, function(p) return p.infos(categsFromTaxo)));
	}
	
}