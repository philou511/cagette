
package react.order.redux.reducers;

import react.Partial;
import redux.IReducer;
import react.order.redux.actions.OrderBoxAction;
import Common;

typedef LeanProduct = {
    
	id : Int,
	name : String,
	ref : Null<String>,
	image : Null<String>,	
	price : Float,
	hasFloatQt : Bool,
	qt : Null<Float>,
	unitType : Null<Unit>,

	variablePrice : Bool,
	wholesale : Bool,
	active : Bool,

	contractId : Int
}

typedef OrderBoxState = {
    selectedProduct : LeanProduct,   
    orders : Array<UserOrder>,
	products : Array<ProductInfo>
};

class OrderBoxReducer implements IReducer<OrderBoxAction, OrderBoxState> {

	public function new() {}

	public var initState: OrderBoxState = {
        selectedProduct : null,
        orders : [],
        products : [] 
    };

	public function reduce( state: OrderBoxState, action: OrderBoxAction ): OrderBoxState
    {
		var partial: Partial<OrderBoxState> = switch (action) {

            case SelectProduct( product ):                
                var selected : LeanProduct = cast {
                    id : product.id,
                    name : product.name,
                    ref : product.ref,
                    image : product.image,	
                    price : product.price,
                    hasFloatQt : product.hasFloatQt,
                    qt : product.qt,
                    unitType : product.unitType,
                    variablePrice : product.variablePrice,
                    wholesale : product.wholesale,
                    active : product.active,
                    contractId : product.contractId
                };
                trace("Action SelectProduct exécutée !");
                trace(selected);              
                { selectedProduct: selected };
               
            
			case UpdateQuantity( product, quantity ):
                var orders = state.orders.copy();
                for( prod in orders ) {
                    if( prod.product == product ) {
                        if( quantity > 0 )
                            prod.quantity = quantity;
                        else
                            orders.remove(prod);
                        break;
                    }
                }
                { orders: orders };

            case AddOrder( product ): 
                var orders = state.orders.copy();
                // orders.push( { product: product, quantity: 1 } );
                { orders: orders };

		}
        
        trace(state);
        trace(partial);
		return ( state == partial ? state : js.Object.assign({}, state, partial) );
	}
}

//------------------  To Do  ---------------
//Validate
//FetchMultidistribOrders( userId: Int, multiDistributionId: Int );
//FetchContractProducts( contractId: Int );