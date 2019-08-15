
package react.order.redux.actions.thunk;

import react.order.redux.actions.OrderBoxAction;
import utils.HttpUtil;
import Common.ProductInfo;

class OrderBoxThunk {

    public static function fetchContractProducts( contractId: Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch: redux.Redux.Dispatch, getState: Void->react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) {
               
            //Loads all the products for the selected contract
            return HttpUtil.fetch("/api/product/get/", GET, { contractId: contractId }, PLAIN_TEXT)
            .then( function(data: String ) {

                var data : { products : Array<ProductInfo> } = tink.Json.parse(data);               
                dispatch( OrderBoxAction.FetchContractProductsSuccess( data.products ) );
                return data.products;                        

            }).catchError( function(data) {

                var data = Std.string(data);
                if( data.substr(0,1) == "{" ) { //json error from server
                    
                    var data : ErrorInfos = haxe.Json.parse(data);                
                    dispatch( OrderBoxAction.FetchContractProductsFailure( data.error.message ) );
                }
                else { //js error
                    
                    dispatch( OrderBoxAction.FetchContractProductsFailure( data ) );
                }

            });

        });
    }
	
}