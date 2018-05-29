package controller.api;
import Common;

/**
 * Product API
 * @author fbarbut
 */
class Product extends Controller
{

	public function doGet(args:{?contractId:db.Contract}) {
	
		if(args==null || args.contractId==null) throw "invalid params";

		var out = {products:new Array<ProductInfo>()};
		for( p in args.contractId.getProducts(false)) out.products.push(p.infos(false,false)); 
		Sys.print(tink.Json.stringify(out));
	}
	
}