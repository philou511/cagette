package react.product;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;


typedef ProductSelectProps = {
	var contractId: Int;
	var products: Array<ProductInfo>;
	var onClick: ProductInfo->Void;	
	var fetchContractProducts: Int -> Void;
}

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
	}

	override public function render(){

		var products = props.products.map(function(product){
            			
			return jsx('<div key=${product.id} className="col-md-6" onClick=${props.onClick.bind(product)}>
							<div className="clickable"><$Product productInfo=$product /></div>			
						</div>');
		});

		return jsx('<div className="productSelect">${products}</div>');		
	}

	override function componentDidMount()
	{
		props.fetchContractProducts( props.contractId );
	}

	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<ProductSelectProps> {	
		
		return { products: Reflect.field(state, "orderBox").products };
	}

	static function mapDispatchToProps( dispatch: redux.Redux.Dispatch ) : react.Partial<ProductSelectProps> {
				
		return { 
			
			onClick: function(product) { dispatch(OrderBoxAction.SelectProduct(product)); },
			fetchContractProducts: function( contractId: Int ) return dispatch( OrderBoxThunk.fetchContractProducts( contractId ) ) 
		
		}

	}	

}	