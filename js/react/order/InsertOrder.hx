package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.product.ProductSelect;
import react.router.Redirect;
import react.router.Link;
// import react.order.redux.reducers.OrderBoxReducer.StateProduct;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;


typedef InsertOrderProps = {
	
	var selectedProductId : Int;
	var contractId : Int;
	var userId : Int;
	var multiDistribId : Int;
	var products : Array<ProductInfo>;
	var resetSelectedProduct : Void -> Void;
}

typedef InsertOrdersState = {
	
	var error : String;	
}


/**
 * A box to add an order to a member
 * @author fbarbut
 */
@:connect
class InsertOrder extends react.ReactComponentOfPropsAndState<InsertOrderProps, InsertOrdersState>
{

	public function new(props) 
	{
		super(props);	
		state = { error : null };
	}	
	
	// ${ props.selectedProductId != null ? jsx('<Redirect to="/" />') : null }

	override public function render(){

		//redirect to orderBox if a product is selected		
		return jsx('			
			<div>				
				${ props.selectedProductId != null ? jsx('<Redirect to="/" />') : null }
				<h3>Choisissez le produit à ajouter</h3>
				<Link className="btn btn-default" to="/"><i className="icon icon-chevron-left"></i> Retour</Link>
				<Error error=${state.error} />
				<hr />
				<ProductSelect contractId=${props.contractId} />			
			</div>			
		');
	}

	override function componentDidMount()
	{
		trace("ON EST DANS componentDidMount DE InsertOrder");
	}

	override function componentWillUnmount()
	{
		trace("ON EST DANS componentWillUnmount DE InsertOrder");
		props.resetSelectedProduct();
	}
	
	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<InsertOrderProps> {
			
		return { 

			selectedProductId : Reflect.field(state, "orderBox").selectedProductId,
			products : state.products
		 };
	}

	static function mapDispatchToProps( dispatch: redux.Redux.Dispatch ) : react.Partial<InsertOrderProps> {
				
		return { resetSelectedProduct : function() { dispatch(OrderBoxAction.ResetSelectedProduct); } }
	}		
			
}