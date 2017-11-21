package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

typedef CartProps = {
  var order:OrderSimple;
};

class Cart extends react.ReactComponentOfProps<CartProps>
{
  override public function render(){
    return jsx('
      <div className="cart">
      </div>
    ');
  }

  function renderProducts() {

  }
}





