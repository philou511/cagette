package tools;

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
	
}