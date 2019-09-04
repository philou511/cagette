package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.product.redux.components.ProductSelect;
import react.router.Redirect;
import react.router.Link;


typedef InsertOrderProps = {

	var contractId : Int;
	var selectedContractId : Int;
	var redirectTo : String;
	var error : String;
}


/**
 * A box to add an order to a member
 * @author fbarbut
 */
@:connect
class InsertOrder extends react.ReactComponentOfProps<InsertOrderProps>
{

	public function new(props) {

		super(props);
	}	

	override public function render() {

		var contractId = props.contractId != null ? props.contractId : props.selectedContractId;

		var backButtonTo = props.contractId != null ? "/" : "/contracts";

		trace("RENDER");
		trace(props.redirectTo);

		//redirect to orderBox if a product is selected
		return props.redirectTo == "orders" ? jsx('<Redirect to="/" />') : 		
		jsx('			
			<div>				
				<h3>Choisissez le produit à ajouter</h3>
				<Link className="btn btn-default" to=${backButtonTo}><i className="icon icon-chevron-left"></i> Retour</Link>
				<Error error=${props.error} />
				<hr />
				<ProductSelect contractId=${contractId} />			
			</div>			
		');
	}	
	
	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<InsertOrderProps> {
			
		return { 
			
			selectedContractId : Reflect.field(state, "reduxApp").selectedContractId, 
			redirectTo : Reflect.field(state, "reduxApp").redirectTo,
			error : Reflect.field(state, "reduxApp").error
		};
	}
	
}