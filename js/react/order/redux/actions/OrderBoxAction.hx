package react.order.redux.actions;

import Common.ProductInfo;

enum OrderBoxAction
{
    FetchContractProductsSuccess( products: Array<ProductInfo> );
    FetchContractProductsFailure( error: String );
    SelectProduct( product: ProductInfo );    
    // Validate;
    // FetchMultidistribOrders( userId: Int, multiDistributionId: Int );    
}