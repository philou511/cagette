package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.ContractInfo;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;


typedef ContractSelectorProps = {
	
	var multiDistribId : Int;
	var contracts : Array<ContractInfo>;
	var selectContract : Int->Void;	
	var fetchContracts : Int -> Void;
}

/**
 * A Contract selector
 * @author web-wizard
 */
@:connect
class ContractSelector extends react.ReactComponentOfProps<ContractSelectorProps>
{

	public function new(props) {

		super(props);			
	}

	override public function render() {

		var contracts = props.contracts.map(function( contract ){
            			
			return jsx('<div key=${contract.id} className="col-md-6" onClick=${props.selectContract.bind(contract.id)}>
							<div className="clickable"><Contract contract=$contract /></div>			
						</div>');
		});

		return jsx('<div className="contractSelector">${contracts}</div>');		
	}

	override function componentDidMount() {

		props.fetchContracts( props.multiDistribId );
	}

	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<ContractSelectorProps> {	
		
		return { contracts: Reflect.field(state, "reduxApp").contracts };
	}

	static function mapDispatchToProps( dispatch : redux.Redux.Dispatch ) : react.Partial<ContractSelectorProps> {
				
		return { 
			
			selectContract : function( contractId : Int ) { 
								dispatch(OrderBoxAction.SelectContract( contractId ));
								//Redirects to InsertOrder when a contract is selected	
								js.Browser.location.hash = "/insert";
							},
			fetchContracts : function( multiDistribId : Int ) {
								dispatch(OrderBoxThunk.fetchContracts( multiDistribId ));
							}
		}
	}	

}	