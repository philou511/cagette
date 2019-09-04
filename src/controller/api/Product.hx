package controller.api;
import Common;

/**
 * Product API
 * @author fbarbut
 */
class Product extends Controller
{
	/**
		List all products of a conctract
	**/
	public function doGet(args:{?contractId:db.Contract}) {
	
		if(args==null || args.contractId==null) throw "invalid params";

		var out = {products:new Array<ProductInfo>()};
		for( p in args.contractId.getProducts(false)) out.products.push(p.infos(false,false)); 
		Sys.print(tink.Json.stringify(out));
	}

	/**
		Get full categories tree
	**/
	public function doCategories(){
		var out = new Array<CategoryInfo>();

		//1st Level
		for( cat in db.TxpCategory.all()){

			var catInfos = cat.infos();

			//2nd level
			catInfos.subcategories = [];
			for( subcat in cat.getSubCategories()){

				var subCatInfos = subcat.infos();
				subCatInfos.subcategories = [];
				for( prod in subcat.getProducts()){
					subCatInfos.subcategories.push({
						name:prod.name,
						id:prod.id,
					});
				}

				

				catInfos.subcategories.push(subCatInfos);
			}

			out.push(catInfos);

		}

		Sys.print(tink.Json.stringify(out));

	}
	
}