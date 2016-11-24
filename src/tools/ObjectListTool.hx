package tools;

/**
 * ...
 * @author fbarbut
 */
class ObjectListTool
{

	public static function getIds( objs:Iterable<sys.db.Object> ){
		var out = [];
		for ( o in objs ) out.push(untyped o.id);
		return out;
		
	}
	
}