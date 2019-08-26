package react.order.redux.actions;

import Common.ProductInfo;
import Common.UserOrder;


enum OrderBoxAction
{
    FetchContractProductsSuccess( products: Array<ProductInfo> );
    FetchContractProductsFailure( error: String );
    SelectProduct( productId: Int );    
    UpdateOrderQuantity( orderId: Int, quantity: Float );
    ReverseOrderRotation( orderId: Int, reverseRotation: Bool );
    UpdateOrderUserId2( orderId: Int, userId2: Int );
    FetchMultiDistribOrdersSuccess( orders : Array<UserOrder> );
    ResetSelectedProduct;
}