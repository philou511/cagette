
package react.cagette.state;

import redux.IReducer;
import react.cagette.action.CartAction;
import Common.ProductInfo;

typedef CartState = {
	var products:Array<{product:ProductInfo, quantity:Int}>;
	var totalPrice:Float;
}

class CartRdcr implements IReducer<CartAction, CartState> {
	public function new() {}

	public var initState:CartState = {
        products:[], 
        totalPrice:0,
    };

	public function reduce(state:CartState, action:CartAction):CartState {
		var partial = switch (action) {
			case UpdateQuantity(product, quantity):
                var cp = state.products.copy();
                for( p in cp ) {
                    if( p.product == product ) {
                        p.quantity = quantity;
                        break;
                    }
                }
                {products:cp};

            case AddProduct(product): //TODO
                var cp = state.products.copy();
                cp.push({product:product, quantity:0});
                {products:cp};

            case RemoveProduct(product): //TODO
                var cp = state.products.copy();
                for( p in cp ) {
                    if( p.product == product ) {
                        cp.remove(p);
                        break;
                    }
                }
                {products:cp};

		}
        //TODO call an update price routine here if maintained
		return (state == partial ? state : js.Object.assign({}, state, partial));
	}
}
