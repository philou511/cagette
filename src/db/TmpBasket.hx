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
    
	
	public var ddate : SDate; 							//multidistrib date
	@:relation(placeId) public var place : db.Place;	//multidistrib place

    //TODO : remove placeId and ddate + link baskets to a multidistrib ID.
    //@:relation(multiDistribId) public var multiDistrib : db.MultiDistrib;
	
	public function new(){
		super();
		cdate = Date.now();
	}

	public function getMultiDistrib():MultiDistrib{
		return MultiDistrib.get(ddate,place,db.Contract.TYPE_VARORDER);
	}

	/**
		Get total amount to pay for this basket
	**/
	public function getTotal():Float{
		var total = 0.0;
		for( o in this.data.products){
			var p = db.Product.manager.get(o.productId,false);
			total += o.quantity * p.getPrice();
		}
		return total;
	}
	
}