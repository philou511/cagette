
package react.order.redux.reducers;

import redux.IReducer;
import react.order.redux.actions.OrderBoxAction;
import Common.ContractInfo;
import Common.ProductInfo;
import Common.UserInfo;
import Common.UserOrder;


typedef OrderBoxState = {

    var orders : Array<UserOrder>;
    var users : Array<UserInfo>;    
    var contracts : Array<ContractInfo>;
    var selectedContractId : Int;
	var products : Array<ProductInfo>;	
    var redirectTo : String;
    var error : String;
};


class OrderBoxReducer implements IReducer<OrderBoxAction, OrderBoxState> {

	public function new() {}

	public var initState: OrderBoxState = {

        orders : [],       
        users : null,
        contracts : [],
        selectedContractId : null,
        products : [],
        redirectTo : null,
        error : null
    };


	public function reduce( state : OrderBoxState, action : OrderBoxAction ) : OrderBoxState {
        
		var partial : Partial<OrderBoxState> = switch (action) {

            case FetchOrdersSuccess( orders ):
                { orders : orders, redirectTo : null, error : null };

            case FetchUsersSuccess( users ):
                { users : users, redirectTo : null, error : null };

            case UpdateOrderQuantity( orderId, quantity ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        if( quantity >= 0 ) {

                            order.quantity = quantity;
                        }                          
                        break;
                    }
                }
                { orders : copiedOrders };

            case ReverseOrderRotation( orderId, reverseRotation ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        order.invertSharedOrder = reverseRotation;
                        break;
                    }
                }
                { orders : copiedOrders };

            case UpdateOrderUserId2( orderId, userId2 ):
                var copiedOrders = state.orders.copy();
                for( order in copiedOrders ) {

                    if( order.id == orderId ) {

                        order.userId2 = userId2;
                        break;
                    }
                }
                { orders : copiedOrders };

            case FetchContractsSuccess( contracts ):
                { contracts : contracts, redirectTo : null, error : null };
            
            case SelectContract( contractId ):
                { selectedContractId : contractId, redirectTo : "products" };
            
            case FetchProductsSuccess( products ):
                { products : products, redirectTo : null, error : null };

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

                    var selectedProduct = Lambda.find( state.products, function( product ) return product.id == productId );
                    var contract = Lambda.find( state.contracts, function( contract ) return contract.id == selectedProduct.contractId );
                    var order : UserOrder = cast {
                    			id: null,
                                contractId: selectedProduct.contractId,
                                contractName: contract != null ? contract.name : null,
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
                { orders : copiedOrders, redirectTo : "orders"  };

            case FetchFailure( error ):
                { error : error, redirectTo : null };

            case ResetRedirection:
                 { redirectTo : null };

        }
        
		return ( state == partial ? state : js.Object.assign({}, state, partial) );
	}
}