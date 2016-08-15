package db;
import sys.db.Object;
import sys.db.Types;

enum Right{
	AmapAdmin;		//accès à l'admin d'amap
	ContractAdmin(?cid:Int);	//accès à la gestion de contrat
	Membership;		//accès a la gestion de adhérents
	Messages;		//accès à la messagerie
}

@:id(userId,amapId)
class OrderPayments extends Object
{
	@:relation(distribId) public var distribution : db.Distribution;
	
	@:relation(userId) public var user : db.User;
	
	//public var lastMemberShip : SNull<SDate>;
	public var rights : SNull<SData<Array<Right>>>;
	

	
	public static function get(user:User, amap:Amap, ?lock = false) {
		//SPOD doesnt cache elements with double primary key, so lets do it manually
		var c = CACHE.get(user.id + "-" + amap.id);
		if (c == null) {
			c = manager.select($user == user && $amap == amap, true/*lock*/);		
			CACHE.set(user.id + "-" + amap.id,c);
		}
		return c;	
	}	
	
	
	
}