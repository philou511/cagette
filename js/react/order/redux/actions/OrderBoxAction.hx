package react.order.redux.actions;

import Common.ProductInfo;

enum OrderBoxAction
{
    SelectProduct( product: ProductInfo );
    AddOrder( product: ProductInfo );
    UpdateQuantity( product: ProductInfo, quantity: Float );
    // Validate;
    // FetchMultidistribOrders( userId: Int, multiDistributionId: Int );
    // FetchContractProducts( contractId: Int );
}