package react.store;

import js.Browser.window;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

typedef ProductProps = {
  var product:ProductInfo;
  var addToCart:ProductInfo -> Int -> Void;
};

typedef ProductState = {
  var quantity:Int;
};

class Product extends react.ReactComponentOfPropsAndState<ProductProps, ProductState>
{
  static inline var OVERLAY_URL = '/shop/productInfo';
  
  public function new() {
    super();
    state = {
      quantity: 1
    };
  }

  function openOverlay() {
    untyped window._.overlay('$OVERLAY_URL/${props.product.id}', props.product.name);
  }

  override public function render(){
    var product = props.product;

    return jsx('
      <div className="product">
        <img src=${product.image} alt={product.name} />
        <div className="body">
          <a onClick=$openOverlay>
            ${product.name}						
					</a>
          <div>${product.price} €</div>
          <input type="number" value=${state.quantity} onChange=$updateQuantity />
          <div className="button" onClick=$addToCart>Ajouter</div>
        </div>
      </div>
    ');
  }

  function updateQuantity(event:Dynamic) {
    var quantity = Std.parseInt(event.target.value);

    if (Std.is(quantity, Int) && quantity > 0)
      setState({
        quantity: Std.int(quantity)
      });
  }

  function addToCart() {
    props.addToCart(props.product, state.quantity);
  }

  function openPopin() {
    trace('Opening Popin');
  }
}

