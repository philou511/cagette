
package react.order.redux.reducers;

import react.Partial;
import redux.IReducer;
import react.order.redux.actions.OrderBoxAction;
import Common;

typedef StateProduct = {
    
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

    selectedProduct : StateProduct,   
    orders : Array<UserOrder>,
	products : Array<ProductInfo>,
    error : String
};

class OrderBoxReducer implements IReducer<OrderBoxAction, OrderBoxState> {

	public function new() {}

	public var initState: OrderBoxState = {

        selectedProduct : null,
        orders : [],
        products : [],
        error : null 
    };

	public function reduce( state: OrderBoxState, action: OrderBoxAction ): OrderBoxState
    {
		var partial: Partial<OrderBoxState> = switch (action) {

            case FetchContractProductsSuccess( products ):
                { products: products };

            case FetchContractProductsFailure( error ):
                { error: error };

            case SelectProduct( product ):                
                var selected : StateProduct = cast {
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
                { selectedProduct: selected };      
            
			         

		}
                
		return ( state == partial ? state : js.Object.assign({}, state, partial) );
	}
}