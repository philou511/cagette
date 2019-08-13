package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.product.ProductSelect;
import react.router.Redirect;
import react.router.Link;
import react.order.redux.reducers.OrderBoxReducer.LeanProduct;


typedef InsertOrdersProps = {
	
	var selectedProduct : LeanProduct;
	var contractId : Int;
	var userId : Int;
	var distributionId : Int;
	
}


typedef InsertOrdersState = {

	var products: Array<ProductInfo>;
	var error: String;	
}

	


/**
 * A box to add an order to a member
 * @author fbarbut
 */
@:connect
class InsertOrder extends react.ReactComponentOfPropsAndState<InsertOrdersProps, InsertOrdersState>
{

	public function new(props) 
	{
		super(props);	
		state = { products:[], error: null };
	}
	
	override function componentDidMount()
	{
		//load product list
		HttpUtil.fetch("/api/product/get/", GET, {contractId:props.contractId},PLAIN_TEXT)
		.then(function(data:String) {

			/*var data : {products:Array<ProductInfo>} = haxe.Json.parse(data);
			for( p in data.products) {
				p.unitType = Type.createEnumIndex(UnitType,untyped  p.unitType);
			}*/

			var data : {products:Array<ProductInfo>} = tink.Json.parse(data);
			setState({products: data.products, error: null});

		}).catchError(function(data) {
			var data = Std.string(data);
			trace("Error",data);
			if(data.substr(0,1)=="{"){
				//json error from server
				var data : ErrorInfos = haxe.Json.parse(data);
				setState(cast {error:data.error.message} );
			}else{
				//js error
				setState(cast {error:data} );
			}
		});
	}
	
	override public function render(){
		//redirect to orderBox if a product is selected
		//Julie
		// var redirect =  if(props.selectedProduct != null) jsx('<$Redirect to="/" />') else null;
		trace("on y passe !");
		return jsx('			
			<div>
				${ props.selectedProduct != null ? jsx('<$Redirect to="/" />') : null }
				<h3>Choisissez le produit à ajouter</h3>
				<$Link className="btn btn-default" to="/"><i className="icon icon-chevron-left"></i> Retour</$Link>
				<$Error error=${state.error} />
				<hr />
				<$ProductSelect products=${state.products} />			
			</div>			
		');
	}

			// order.products.map(function(p:ProductWithQuantity) {
			// 	return {
			// 		productId: p.product.id,
			// 		quantity: p.quantity*1.0
			// 	};
			// })

	//Julie
	// function onSelectProduct(p:ProductInfo){
	// 	var uo : UserOrder = cast {
	// 		id:null,
	// 		product:p,
	// 		quantity:1,
	// 		productId:p.id,
	// 		productPrice:p.price,
	// 		paid:false,
	// 		invert:false,
	// 		user2:null
	// 	};
	// 	props.onInsert(uo);
	// 	setState(cast {selected:p.id});
		
		//do not insert order now, just warn the OrderBox		
/*
		//insert order
		var data = [{id:null,productId:p.id,qt:1,paid:false,invert:false,user2:null} ];
		var req = {
			orders:haxe.Json.stringify(data),
			distributionId : props.distributionId,
			contractId : props.contractId
		};
		var r = HttpUtil.fetch("/api/order/update/"+props.userId, POST, req, JSON);
		r.then(function(d:Dynamic) {
			
			if (Reflect.hasField(d, "error")) {
				setState(cast {error:d.error.message});
			}else{
				//WOOT
				//trace("OK");
				//go to OrderBox with a redirect
				setState(cast {selected:p.id});
			}
		}).catchError(function(d) {
			trace("PROMISE ERROR", d);
			setState(cast {error:d.error.message});
		});
*/		
	// }
	
	
	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<InsertOrdersProps> {
	
		trace("mapStateToProps est exécuté !");
		trace(state);
		for (key in Reflect.fields(state)) {
			trace(key);
			trace(Reflect.field(state, key));
			trace(Reflect.field(state, key).selectedProduct);
		}		
		//trace(state.selectedProduct);
		return { selectedProduct: Reflect.field(state, "orderBox").selectedProduct };
	}		
}