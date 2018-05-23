package controller.api;
import haxe.Json;
import Common;

/**
 * Product API
 * @author fbarbut
 */
class Product extends Controller
{

	public function doGet(args:{?contractId:db.Contract}) {
	
		if(args==null || args.contractId==null) throw "invalid params";

		var out = Lambda.map(args.contractId.getProducts(false),function(x) return x.infos() );

		Sys.print(haxe.Json.stringify({ success:true, products:Lambda.array(out) }));
	}
	

	
}