package tools;
import Common.UserOrder;

/**
 * Utility to work on sys.db.Object lists
 * @author fbarbut
 */
class ObjectListTool
{

	/**
	 * Get a list of IDs from an object list
	 */
	public static function getIds( objs:Iterable<sys.db.Object> ){
		var out = [];
		for ( o in objs ) out.push(untyped o.id);
		return out;
	}
	
	/**
	 * deduplicate objects on IDs
	 */
	public static function deduplicate<T>(users:Iterable<T>):Array<T>{
		var out = new Map<Int,T>();
		
		for ( u in users) out.set( untyped u.id, u );
		
		return Lambda.array(out);
	}
	
	/**
	 * Deduplicate user orders. (merge orders on same product from a same user)
	 * @param	orders
	 * @return
	 */
	public static function deduplicateOrders(orders:Array<UserOrder>):Array<UserOrder>{
		
		var out = new Map<String,UserOrder>();
		
		for ( o in orders){
			
			var key = o.userId + "-" + o.userId2 + "-" + o.productId;
			var x = out.get(key);
			if ( x == null){				
				x = o;				
			}else{
				//null safety
				if (x.fees == null) x.fees = 0;
				if (o.fees == null) o.fees = 0;
				
				//merge
				x.quantity += o.quantity;
				x.fees += o.fees;
				x.subTotal += o.subTotal;
				x.total += o.total;
				
			}
			
			out.set(key, x);
		}
		
		return Lambda.array(out);
		
	}
	
}