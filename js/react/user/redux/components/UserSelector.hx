package react.user.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.UserInfo;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;
import mui.core.OutlinedInput;
import mui.core.NativeSelect;
import react.mui.CagetteTheme;
import mui.core.Button;

typedef UserSelectorProps = {
	
	var users : Array<UserInfo>;  
	var fetchUsers : Void -> Void;
	var selectUser : Int -> String -> Void;	
	var multiDistribId : Int;
	var contractId : Int;
	var contractType : Int;	
	var fetchOrders : Int -> Int -> Int -> Int -> Void;	
}

typedef UserSelectorState = {

	var userIdValue : Int;	
}


/**
 * A User selector
 * @author web-wizard
 */
@:connect
class UserSelector extends react.ReactComponentOfPropsAndState<UserSelectorProps, UserSelectorState>
{

	public function new(props) {

		super(props);
		state = { userIdValue : 0 };

	}

	override public function render() {

		if ( props.users != null ) {

			var options = props.users.map( function( user ) return jsx('<option key=${user.id} value=${user.id}>${user.name}</option>') );
			var inputSelect = jsx('<OutlinedInput labelWidth={0} />');
			return jsx('
			<div style=${{ marginLeft: "30%" }}>
				<NativeSelect value=${state.userIdValue} onChange=${updateUserId} input=${cast inputSelect} style=${{fontSize:"0.95rem", height: 45, width: "70%" }} >	
					<option value="0">Sélectionnez la personne associée à la nouvelle commande</option>
					$options						
				</NativeSelect>					
			</div>');
		}
		else {

			return jsx('<div></div>');
		}
				
	}
	
	override function componentDidMount() {

        props.fetchUsers();
	}

	function updateUserId( e: js.html.Event ) {		

		e.preventDefault();		

		var userId : Int = untyped (e.target.value == "") ? null : e.target.value;
		setState( { userIdValue : userId } );

		var userName : String = props.users.filter( function( user ) return user.id == userId )[0].name;
		props.selectUser( userId, userName );
		props.fetchOrders( userId, props.multiDistribId, props.contractId, props.contractType );		
		js.Browser.location.hash = "/";
	}

	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<UserSelectorProps> {	
		
		return { users: Reflect.field(state, "reduxApp").users };
	}

	static function mapDispatchToProps( dispatch : redux.Redux.Dispatch ) : react.Partial<UserSelectorProps> {
				
		return { 

			fetchUsers : function() { dispatch(OrderBoxThunk.fetchUsers()); },
			selectUser : function( userId : Int, userName : String ) { dispatch(OrderBoxAction.SelectUser( userId, userName ));	},
			fetchOrders : function( userId : Int, multiDistribId : Int, contractId : Int, contractType : Int ) {
							return dispatch( OrderBoxThunk.fetchOrders( userId, multiDistribId, contractId, contractType ) ); }			
		}
	}	

}	