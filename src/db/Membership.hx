package db;
import sys.db.Object;
import sys.db.Types;

@:id(userId,amapId,year)
class Membership extends Object
{
	@:relation(amapId) public var amap : db.Group;
	@:relation(userId) public var user : db.User;
	@:relation(distributionId) public var distribution : SNull<MultiDistrib>;
	@:relation(operationId) public var operation : SNull<Operation>; //membership payment debt operation
	
	public var year : Int; //année de cotisation (année la plus ancienne si a cheval sur deux années : 2014-2015  -> 2014)
	public var date : SNull<SDate>;
	
	public static function get(user:User, amap:db.Group,year:Int, ?lock = false) {
		return manager.select($user == user && $amap == amap && $year == year, lock);
	}	
	
	
	
}