package db;
import sys.db.Object;
import sys.db.Types;

enum Right{
	AmapAdmin;					//can manage whole group
	ContractAdmin(?cid:Int);	//can manage one or all contracts
	Membership;					//can manage group members
	Messages;					//can send messages
}

/**
 * A user which is member of a group
 */
@:id(userId,amapId)
class UserAmap extends Object
{
	@:relation(amapId) public var amap : Amap;
	@:relation(userId) public var user : db.User;
	public var rights : SNull<SData<Array<Right>>>;
	public var balance : SFloat; //account balance in group currency
	static var CACHE = new Map<String,db.UserAmap>();
	
	
	public function new(){
		super();
		balance = 0;
	}
	
	public static function get(user:User, amap:Amap, ?lock = false) {
		if (user == null || amap == null) return null;
		//SPOD doesnt cache elements with double primary key, so lets do it manually
		var c = CACHE.get(user.id + "-" + amap.id);
		if (c == null) {
			c = manager.select($user == user && $amap == amap, true/*lock*/);		
			CACHE.set(user.id + "-" + amap.id,c);
		}
		return c;	
	}
	
	public static function getOrCreate(user:db.User, group:db.Amap){
		var ua = get(user, group);
		if ( ua == null){
			ua = new UserAmap();
			ua.user = user;
			ua.amap = group;
			ua.insert();
		}
		return ua;
	}
	
	/**
	 * give right and update DB
	 */
	public function giveRight(r:Right) {
	
		if (hasRight(r)) return;
		if (rights == null) rights = [];
		lock();
		rights.push(r);
		update();
	}
		
	/**
	 * remove right and update DB
	 */
	public function removeRight(r:Right) {	
		if (rights == null) return;
		var newrights = [];
		for (right in rights.copy()) {
			if ( !Type.enumEq(right, r) ) {
				newrights.push(right);
			}
		}
		rights = newrights;
		update();
	}
	
	public function hasRight(r:Right):Bool {
		if (this.user.isAdmin()) return true;
		if (rights == null) return false;
		for ( right in rights) {
			if ( Type.enumEq(r,right) ) return true;
		}
		return false;
	}
	
	public function getRightName(r:Right):String {
		var t = sugoi.i18n.Locale.texts;
		return switch(r) {
		case Right.AmapAdmin 	: t._("Administrator");
		case Right.Messages 	: t._("Messaging");
		case Right.Membership 	: t._("Members management");
		case Right.ContractAdmin(cid) : 
			if (cid == null) {
				t._("Management of all contracts");
			}else {
				var cname = db.Contract.manager.get(cid).name;
				t._("Contract management") + " : " + cname;
			}
		}
	}
	
	public function hasValidMembership():Bool {
		
		if (amap.membershipRenewalDate == null) return false;
		var cotis = db.Membership.get(this.user, this.amap, this.amap.getMembershipYear());
		return cotis != null;
	}
	
	override public function insert(){
		
		App.current.event(NewMember(this.user,this.amap));
		super.insert();
	}
	
	public function getPaymentOperations(){
		return db.Operation.getPaymentOperations(user, amap);
	}
	
	public function getLastOperations(limit){
		return db.Operation.getLastOperations(user, amap, limit);
	}
	
}