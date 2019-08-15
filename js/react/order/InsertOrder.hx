package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.product.ProductSelect;
import react.router.Redirect;
import react.router.Link;
import react.order.redux.reducers.OrderBoxReducer.StateProduct;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;


typedef InsertOrdersProps = {
	
	var selectedProduct : StateProduct;
	var contractId : Int;
	var userId : Int;
	var distributionId : Int;
	var products: Array<ProductInfo>;
	
}

typedef InsertOrdersState = {
	
	var error: String;	
}


/**
 * A box to add an order to a member
 * @author fbarbut
 */
@:connect
class InsertOrder extends react.ReactComponentOfPropsAndState<InsertOrdersProps, InsertOrdersState>
{

	public function new(props) 
	{
		super(props);	
		state = { error: null };
	}	
	
	override public function render(){

		//redirect to orderBox if a product is selected		
		return jsx('			
			<div>
				${ props.selectedProduct != null ? jsx('<$Redirect to="/" />') : null }
				<h3>Choisissez le produit à ajouter</h3>
				<$Link className="btn btn-default" to="/"><i className="icon icon-chevron-left"></i> Retour</$Link>
				<$Error error=${state.error} />
				<hr />
				<$ProductSelect contractId=${props.contractId} />			
			</div>			
		');
	}
	
	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<InsertOrdersProps> {
			
		return { 

			selectedProduct: Reflect.field(state, "orderBox").selectedProduct,
			products: state.products
		 };
	}		
			
}