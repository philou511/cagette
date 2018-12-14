package react.cagette.action;

import Common.ProductInfo;

enum CartAction {
	UpdateQuantity(product:ProductInfo, quantity:Int);
    AddProduct(product:ProductInfo);
    RemoveProduct(product:ProductInfo);
    ResetCart;
}

