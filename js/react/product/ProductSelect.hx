package react.product;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.order.redux.actions.OrderBoxAction;


typedef ProductSelectProps = {
	var products: Array<ProductInfo>;
	var onClick: ProductInfo->Void;	
}


//Julie
// class ProductSelect extends react.ReactComponentOfPropsAndState<{onSelect:ProductInfo->Void,products:Array<ProductInfo>},{selected:Int}>

/**
 * A Product selector
 * @author fbarbut
 */
@:connect
class ProductSelect extends react.ReactComponentOfProps<ProductSelectProps>
{
	public function new(props) 
	{
		super(props);	
		//Julie
		// state = { selected : null };
	}

	override public function render(){

		var products = props.products.map(function(product){
            
			//Julie
			// return jsx('<div key=${info.id} className="col-md-6" onClick=${onClick.bind(info.id)}>
			
			return jsx('<div key=${product.id} className="col-md-6" onClick=${props.onClick.bind(product)}>
							<div className="clickable"><$Product productInfo=$product /></div>			
						</div>');
		});

		return jsx('<div className="productSelect">${products}</div>');
	}

	//Julie
	// function onClick(i:Int){
	// 	this.setState(cast {selected:i});
	// 	if(props.onSelect!=null){
	// 		var p = Lambda.find(props.products,function(x) return x.id==i);
	// 		props.onSelect(p);
	// 	} 
	// }

	// function selectProduct(productId: Int) {
    //     props.onClick(productId);
    // }

	static function mapDispatchToProps( dispatch: redux.Redux.Dispatch ) : react.Partial<ProductSelectProps> {
		
		return { onClick: function(product) { dispatch(OrderBoxAction.SelectProduct(product)); } }
				
		// .then(function() {
		// 	 js.Browser.console.log(store.getState()); }) }

	}

}	