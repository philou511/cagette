package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.product.redux.components.ProductSelect;

//Material UI
import react.mui.CagetteTheme;
import mui.core.Button;


typedef InsertOrderProps = {

	var contractId : Int;
	var selectedContractId : Int;
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

		return jsx('<div>				
						<h3>Choisissez le produit à ajouter</h3>
						<Button onClick=${function(){ js.Browser.location.hash = props.contractId != null ? "/" : "/contracts"; }} size={Medium} variant={Outlined}>
							${CagetteTheme.getIcon("chevron-left")}&nbsp;&nbsp;Retour
						</Button>
						<Error error=${props.error} />
						<hr />
						<ProductSelect contractId=${contractId} />			
					</div>			
		');
	}	
	
	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<InsertOrderProps> {
			
		return { 
			
			selectedContractId : Reflect.field(state, "reduxApp").selectedContractId, 
			error : Reflect.field(state, "reduxApp").error
		};
	}
	
}