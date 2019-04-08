package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Temporary Basket
 */
@:index(basketRef)
class TmpBasket extends Object
{
    public var id : SId;
	public var basketRef : SNull<SString<256>>;
	public var cdate : SDateTime; //date when the order has been placed
	public var data : SData<TmpBasketData>;

    @:relation(userId)  public var user  : SNull<db.User>; //ordering is possible without being logged
    @:relation(groupId) public var group : db.Amap;
    //TODO : link baskets to a multidistrib ID.
    //@:relation(multiDistribId) public var multiDistrib : db.MultiDistrib;
	
	public function new(){
		super();
		cdate = Date.now();
	}
	
}