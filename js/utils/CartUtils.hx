package utils;

using Lambda;

import Common;

class CartUtils {
  public static function addToCart(order:OrderSimple, productToAdd:ProductInfo, quantity:Int):OrderSimple {
    var products = order.products.copy();
    var total = order.total;

    var existingProduct = products.find(function(p) {
      return p.product.id == productToAdd.id;
    });

    if (existingProduct == null)
      products.push({
        product: productToAdd,
        quantity: quantity
      });
    else
      existingProduct.quantity += quantity;

    total += quantity * productToAdd.price;

    return {
      products: products,
      total: total
    };
  }
}
