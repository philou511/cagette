
package react.order.redux.reducers;

import react.Partial;
import redux.IReducer;
import react.order.redux.actions.OrderBoxAction;
import Common;

// typedef StateProduct = {
    
// 	id : Int,
// 	name : String,
// 	ref : Null<String>,
// 	image : Null<String>,	
// 	price : Float,
// 	hasFloatQt : Bool,
// 	qt : Null<Float>,
// 	unitType : Null<Unit>,

// 	variablePrice : Bool,
// 	wholesale : Bool,
// 	active : Bool,

// 	contractId : Int
// }

typedef OrderBoxState = {

    var selectedProductId : Int;
    var orders : Array<UserOrder>;
    var ordersByContractId : Map<Int, Array<UserOrder>>;
	var products : Array<ProductInfo>;
    var users : Null<Array<UserInfo>>;
    var error : String;
};

class OrderBoxReducer implements IReducer<OrderBoxAction, OrderBoxState> {

	public function new() {}

	public var initState: OrderBoxState = {

        selectedProductId : null,
        orders : [],
        ordersByContractId : null,
        users : null,
        products : [],
        error : null 
    };

	public function reduce( state: OrderBoxState, action: OrderBoxAction ): OrderBoxState
    {
		var partial: Partial<OrderBoxState> = switch (action) {

            case FetchMultiDistribOrdersSuccess( orders ):
                { orders: orders };

            case UpdateOrderQuantity( orderId, quantity ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        if( quantity > 0 ) {

                            order.quantity = quantity;
                        }                          
                        // else {

                        //     copiedOrders.remove(order);
                        // }
                        
                        break;
                    }
                }
                { orders: copiedOrders };

            case ReverseOrderRotation( orderId, reverseRotation ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        order.invertSharedOrder = reverseRotation;
                        break;
                    }
                }
                { orders: copiedOrders };

            case UpdateOrderUserId2( orderId, userId2 ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        order.userId2 = userId2;
                        break;
                    }
                }
                { orders: copiedOrders };

            case FetchContractProductsSuccess( products ):
                { products: products };

            case FetchContractProductsFailure( error ):
                { error: error };

            case SelectProduct( productId ):
                var copiedOrders = state.orders.copy();
                var orderFound : Bool = false;
                for( order in copiedOrders ) {

                    if( order.product.id == productId ) {

                        order.quantity += 1;
                        orderFound = true;
                        break;
                    }
                }
                
                if ( !orderFound ) {

                    var selectedProduct = Lambda.find( state.products, function(product) return product.id == productId );
                    var order : UserOrder = cast {
                    			id: null,
                    			product: selectedProduct,
                    			quantity: 1,
                    			productId: productId,
                    			productPrice: selectedProduct.price,
                    			paid: false,
                    			invert: false,
                    			user2: null
                    			};
                    
                    copiedOrders.push(order);

                }
                { orders : copiedOrders, selectedProductId: productId };  

                case ResetSelectedProduct:
                     { selectedProductId: null };             
        
        }
                
        // trace(state);
        trace(partial);
		return ( state == partial ? state : js.Object.assign({}, state, partial) );
	}
}