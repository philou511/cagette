package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.router.Redirect;
import react.router.Link;


typedef ContractsBoxProps = {
	
	var contractId : Int;
	var multiDistribId : Int;
	var redirectTo : String;
	var error : String;
}


/**
 * A box to select a contract to then choose telated products to be added to the orders of the user
 * @author web-wizard
 */
@:connect
class ContractsBox  extends react.ReactComponentOfProps<ContractsBoxProps>
{

	public function new(props) {

		super(props);		
	}	

	override public function render() {	

		//redirect to InsertOrder if a contract is selected		
		return props.redirectTo == "products" ? jsx('<Redirect to="/insert" />') : 
		jsx('			
			<div>								
				<h3>Choisissez le contrat dont vous voulez voir les produits</h3>
				<Link className="btn btn-default" to="/"><i className="icon icon-chevron-left"></i> Retour</Link>
				<Error error=${props.error} />				
				<hr />
				<ContractSelector multiDistribId=${props.multiDistribId} />						
			</div>			
		');
	}
	
	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<ContractsBoxProps> {

		return { redirectTo : Reflect.field(state, "orderBox").redirectTo, error : Reflect.field(state, "orderBox").error };
	}

}