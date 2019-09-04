
package react.order.redux.actions.thunk;

import utils.HttpUtil;
import Common.ContractInfo;
import Common.ProductInfo;
import Common.UserInfo;
import Common.UserOrder;
import react.order.redux.reducers.OrderBoxReducer.OrderBoxState;


class OrderBoxThunk {


    public static function fetchOrders( userId : Int, multiDistribId : Int, ?contractId: Int, ?contractType: Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch : redux.Redux.Dispatch, getState : Void -> OrderBoxState ) {

            //Fetches all the orders for this user and this multiDistrib and for a given Contract if it's specified otherwise for any contract of this multiDistrib
            return HttpUtil.fetch( "/api/order/get/" + userId + "/" + multiDistribId, GET, { contract : contractId }, PLAIN_TEXT )
            .then( function( data : String ) {
                
                var data : { orders : Array<UserOrder> } = tink.Json.parse(data);
                dispatch( OrderBoxAction.FetchOrdersSuccess( data.orders ) );

                //Load users for amap type contracts
                if ( contractType == 0 ) { 

                    fetchUsers( dispatch );
                }
            })
            .catchError(function(data) {
               
                handleError( data, dispatch );
            });
        });

    }

    static function fetchUsers( dispatch : redux.Redux.Dispatch ) {

        //Fetches all the orders for this user and this multiDistrib and for a given Contract if it's specified otherwise for any contract of this multiDistrib
        return HttpUtil.fetch( "/api/user/getFromGroup/", GET, {}, PLAIN_TEXT )
        .then( function( data : String ) {

            var data : { users : Array<UserInfo> } = tink.Json.parse(data);
            dispatch( OrderBoxAction.FetchUsersSuccess( data.users ) );
        })
        .catchError(function(data) {

            handleError( data, dispatch );
        });

    }

    public static function updateOrders( userId : Int, multiDistribId : Int, callbackUrl : String ) {
    
        return redux.thunk.Thunk.Action( function( dispatch : redux.Redux.Dispatch, getState : Void -> OrderBoxState ) {

            var data = new Array<{ id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int }>();
            var state : OrderBoxState = Reflect.field(getState(), "reduxApp");           

            for ( order in state.orders) {

                data.push( { id : order.id,
                            productId : order.product.id,
                            qt : order.quantity,
                            paid : order.paid,
                            invertSharedOrder : order.invertSharedOrder,
                            userId2 : order.userId2 } );
            } 

            return HttpUtil.fetch( "/api/order/update/" + userId + "/" + multiDistribId, POST, { orders : data }, JSON )
            .then( function( data : Dynamic ) {

                js.Browser.location.href = callbackUrl;
            })
            .catchError( function(data) {

                handleError( data, dispatch );
            });
        });

    }
    
    public static function fetchContracts( multiDistribId : Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch : redux.Redux.Dispatch, getState : Void -> OrderBoxState ) {
               
            //Loads all the contracts (of variable type only) for the given multiDistrib
            return HttpUtil.fetch( "/api/order/contracts/" + multiDistribId, GET, { contractType: 1 }, PLAIN_TEXT )
            .then( function( data : String ) {             

                var data : { contracts : Array<ContractInfo> } = tink.Json.parse(data);               
                dispatch( OrderBoxAction.FetchContractsSuccess( data.contracts ) );
            })
            .catchError( function(data) {                    
                
                handleError( data, dispatch );
            });
        });

    }

    public static function fetchProducts( contractId : Int ) {
    
        return redux.thunk.Thunk.Action( function( dispatch : redux.Redux.Dispatch, getState : Void -> OrderBoxState ) {
               
            //Loads all the products for the current contract
            return HttpUtil.fetch( "/api/product/get/", GET, { contractId : contractId }, PLAIN_TEXT )
            .then( function( data : String ) {

                var data : { products : Array<ProductInfo> } = tink.Json.parse(data);               
                dispatch( OrderBoxAction.FetchProductsSuccess( data.products ) );                                     
            })
            .catchError( function(data) {

                handleError( data, dispatch );
            });
        });

    }

    static function handleError( data : Dynamic, dispatch : redux.Redux.Dispatch ) {

        var data = Std.string(data);                
        if( data.substr(0,1) == "{" ) { //json error from server
            
            var data : ErrorInfos = haxe.Json.parse(data);                
            dispatch( OrderBoxAction.FetchFailure( data.error.message ) );
        }
        else { //js error
            
            dispatch( OrderBoxAction.FetchFailure( data ) );
        }
    }
	
}