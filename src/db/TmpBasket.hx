package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Temporary Basket
 */
@:index(ref)
class TmpBasket extends Object
{
    public var id : SId;
	public var ref : SNull<SString<256>>;
	public var cdate : SDateTime; //date when the order has been placed
	public var data : SText; //SData<TmpBasketData>;
    @:relation(userId)  public var user  : SNull<db.User>; //ordering is possible without being logged
    @:relation(multiDistribId) public var multiDistrib : db.MultiDistrib;
	
	public function new(){
		super();
		cdate = Date.now();
		setData({products:[]});
	}
	
	/**
		Get total amount to pay for this basket
	**/
	public function getTotal():Float{
		var total = 0.0;
		var data = this.getData();
		for( o in data.products){
			var p = db.Product.manager.get(o.productId,false);
			if(p==null) continue;
			total += o.quantity * p.getPrice();
		}
		return total;
	}

	public function getOrders(){
		var out = new Array<{product:db.Product,quantity:Float}>();
		var data = this.getData();
		for( o in data.products){
			var p = db.Product.manager.get(o.productId,false);
			if(p==null) continue;
			out.push({product:p , quantity : o.quantity});
		}
		return out;
	}

	
	public function getData():TmpBasketData{
		//try {
			return haxe.Json.parse(data);
		/*} catch(e:Any) {
			// data is probably of type SData<TmpBasketData>
			return haxe.Unserializer.run(data);
		}*/
	}

	public function setData(tmpBasketData: TmpBasketData){
		data = haxe.Json.stringify(tmpBasketData);
	}
}