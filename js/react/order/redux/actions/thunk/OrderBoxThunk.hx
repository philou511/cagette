
package react.order.redux.actions.thunk;

import react.order.redux.actions.OrderBoxAction;
import utils.HttpUtil;
import Common.ProductInfo;
import Common.UserOrder;
import react.order.redux.reducers.OrderBoxReducer.OrderBoxState;

class OrderBoxThunk {


    public static function fetchMultiDistribUserOrders( userId : Int, multiDistribId : Int, ?contractId: Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch: redux.Redux.Dispatch, getState: Void->OrderBoxState ) {

            ////////////////////////
            // api/order/get/23396/779?contract=6395
            // 23396 = userId
            // 779 = multidistribId
            // 6395 = contractId (optionnel) si tu veux filter pour un seul contrat et pas pour toute la multidistrib
            ////////////////////////

            //Fetches all the orders for this user and this multiDistrib and for a given Contract if it's specified
            return HttpUtil.fetch("/api/order/get/" + userId + "/" + multiDistribId, GET, { contract : contractId }, PLAIN_TEXT)
            .then( function( data : String ) {
                
                var data : { orders : Array<UserOrder> } = tink.Json.parse(data);
                dispatch( OrderBoxAction.FetchMultiDistribUserOrdersSuccess( data.orders ) );
                return data.orders;      

                // setState({orders:data.orders, error:null});

                // if( props.contractType == 0 ) loadUsers();

            });
            // .catchError(function(data) {

            //     var data = Std.string(data);			
            //     if(data.substr(0,1)=="{"){
            //         //json error from server
            //         var data : ErrorInfos = haxe.Json.parse(data);
            //         setState( cast {error:data.error.message} );
            //     }else{
            //         //js error
            //         setState( cast {error:data} );
            //     }
            // });
        });

    }

    public static function saveMultiDistribUserOrders( userId : Int, multiDistribId : Int, callbackUrl : String ) {
    
        return redux.thunk.Thunk.Action( function( dispatch: redux.Redux.Dispatch, getState: Void->react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) {

            var data = new Array<{ id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int }>();
            var state : OrderBoxState = Reflect.field(getState(), "orderBox");           

            for ( order in state.orders) {

                data.push( { id : order.id,
                            productId : order.product.id,
                            qt : order.quantity,
                            paid : order.paid,
                            invertSharedOrder : order.invertSharedOrder,
                            userId2 : order.userId2 } );
            } 

           return HttpUtil.fetch("/api/order/update/" + userId + "/" + multiDistribId, POST, { orders : data }, JSON)
            .then( function( data : Dynamic ) {

                js.Browser.location.href = callbackUrl;

            });
            // .catchError( function(data) {

            //     var data = Std.string(data);
            //     if(data.substr(0,1)=="{"){
            //         //json error from server
            //         var data : ErrorInfos = haxe.Json.parse(data);
            //         setState( cast {error:data.error.message} );
            //     }else{
            //         //js error
            //         setState( cast {error:data} );
            //     }
            // });
           
        });

    } 

    public static function fetchContractProducts( contractId : Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch : redux.Redux.Dispatch, getState : Void->OrderBoxState ) {
               
            //Loads all the products for the selected contract
            return HttpUtil.fetch("/api/product/get/", GET, { contractId: contractId }, PLAIN_TEXT)
            .then( function( data : String ) {

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