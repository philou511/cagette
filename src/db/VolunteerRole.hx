package db;
import sys.db.Object;
import sys.db.Types;
import Common;

class VolunteerRole extends Object
{
	public var id : SId;
	public var name : SString<64>;
	@:relation(groupId) public  var group : db.Amap;
	@:relation(contractId) 	public var contract : SNull<db.Contract>;
}