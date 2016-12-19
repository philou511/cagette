package db;
import sys.db.Object;
import sys.db.Types;

/**
 * log of sent emails
 */
class Message extends Object
{

	public var id : SId;
	@:relation(amapId) public var amap : Amap;
	
	
	@:relation(senderId) public var sender : SNull<User>;
	
	public var recipientListId : SNull<SString<12>>;
	public var recipients : SNull<SData<Array<String>>>;
	
	public var title : SString<128>;
	public var body : SText;	
	public var date : SDateTime;
	
	public var status : SNull<SText>;
	
	
}