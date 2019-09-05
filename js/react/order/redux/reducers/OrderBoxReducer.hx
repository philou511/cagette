
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
        error : null
    };


	public function reduce( state : OrderBoxState, action : OrderBoxAction ) : OrderBoxState {
        
		var partial : Partial<OrderBoxState> = switch (action) {

            case FetchOrdersSuccess( orders ):
                { orders : orders, error : null };

            case FetchUsersSuccess( users ):
                { users : users, error : null };

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
                { contracts : contracts, error : null };
            
            case SelectContract( contractId ):
                { selectedContractId : contractId };
            
            case FetchProductsSuccess( products ):
                { products : products, error : null };

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
                    			id: 0 - Std.random(1000000),
                                contractId: selectedProduct.contractId,
                                contractName: contract != null ? contract.name : null,
                    			product: selectedProduct,
                    			quantity: 1,                     			
                    			paid: false
                    			};
                    
                    copiedOrders.push(order);

                }
                { orders : copiedOrders };

            case FetchFailure( error ):
                { error : error };

        }       
        
		return ( state == partial ? state : js.Object.assign({}, state, partial) );
	}
}