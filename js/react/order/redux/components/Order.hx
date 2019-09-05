package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.Unit;
import Common.UserInfo;
import Common.UserOrder;
import react.product.Product;
import react.order.redux.actions.OrderBoxAction;
import mui.core.input.InputAdornmentPosition;
import mui.core.TextField;
import mui.core.InputAdornment;
import mui.core.OutlinedInput;
import mui.core.NativeSelect;


typedef OrderProps = {

	var order : UserOrder;
	var users : Null<Array<UserInfo>>;
	var currency : String;
	var contractType : Int;	
	var updateOrderQuantity : Float -> Void;
	var reverseRotation : js.html.Event -> Void;
	var updateOrderUserId2 : js.html.Event -> Void;
}

typedef OrderState = {

	var quantityInputValue : String;
}


/**
 * A User order
 * @author fbarbut
 */
@:connect
class Order extends react.ReactComponentOfPropsAndState<OrderProps, OrderState>
{
	public function new(props) {

		super(props);
		if (props.order.product.qt == null) props.order.product.qt = 1;
		state = { quantityInputValue : getDisplayQuantity() };
	}
	
	override public function render() {

		var inputProps = { endAdornment: jsx('<InputAdornment position={End}>${getProductUnit()}</InputAdornment>') };
		var input =  isSmartQtInput() ?
		jsx('<TextField variant={Outlined} type={Text} value=${state.quantityInputValue} onChange=${updateQuantity} InputProps=${cast inputProps} />') :
		jsx('<TextField variant={Outlined} type={Text} value=${state.quantityInputValue} onChange=${updateQuantity} /> ');

		var alternated = if( props.contractType == 0 && props.users != null ) {

			//constant orders
			var options = props.users.map(function(x) return jsx('<option key=${x.id} value=${x.id}>${x.name}</option>') );

			var checkbox = if(props.order.invertSharedOrder) {

				jsx('<input data-toggle="tooltip" title="Inverser l\'alternance" checked="checked" type="checkbox" value="1"  onChange=${props.reverseRotation} />');				
			}
			else {

				jsx('<input data-toggle="tooltip" title="Inverser l\'alternance" type="checkbox" value="1"  onChange=${props.reverseRotation} />');
			}	

			var inputSelect = jsx('<OutlinedInput />');
			jsx('<div>
					<NativeSelect value=${props.order.userId2} onChange=${props.updateOrderUserId2} input=${cast inputSelect} >	
						<option value="0">-</option>
						$options						
					</NativeSelect>
					$checkbox
			</div>');

		}
		else {

			null;
		}

		var className1 = props.contractType != 0 ? "col-md-5" : "col-md-3";
		var className2 = props.contractType != 0 ? "col-md-3 ref text-center" : "col-md-2 ref text-center";
		var className3 = props.contractType != 0 ? "col-md-2 text-center" : "col-md-1 text-center";
		var className4 = props.contractType != 0 ? "col-md-2" : "col-md-2";
		
		return jsx('<div className="productOrder row">
			<div className=${className1}>
				<Product productInfo=${props.order.product} />
			</div>

			<div className=${className2} style=${{ paddingTop: 15 }} >
				${props.order.productRef}
			</div>

			<div className=${className3} style=${{ paddingTop: 15 }} >
				${round(props.order.quantity * props.order.productPrice)}&nbsp;${props.currency}
			</div>
			
			<div className=${className4} >
				$input			
				${makeInfos()}
			</div>

			${ props.contractType == 0 ? jsx('<div className="col-md-4">$alternated</div>') : null }
			
		</div>');
	}
	
	function round(f) {

		return Formatting.formatNum(f);
	}

	function makeInfos() {

		return if ( isSmartQtInput() ) {

			jsx('
			<div className="infos">
				<b> ${getProductQuantity()} </b> x <b>${props.order.product.qt} ${getProductUnit()} </b> ${props.order.productName}
			</div>');
		}
		else {

			null;
		}
	}

	function isSmartQtInput() : Bool {

		return props.order.product.hasFloatQt || props.order.product.variablePrice || props.order.product.wholesale;
	}

	function updateQuantity( e: js.html.Event ) {		

		e.preventDefault();		

		var value: String = untyped (e.target.value == "") ? "0" : e.target.value;
		setState( { quantityInputValue : value } );

		var orderQuantity : Float = Formatting.parseFloat(value);
		if ( isSmartQtInput() ) {

			//the value is a smart qt, so we need re-compute the quantity
			orderQuantity = orderQuantity / props.order.product.qt;
		}				
		props.updateOrderQuantity(orderQuantity); 
	}	

	function getProductUnit() : String {

		var productUnit : Unit = props.order.product.unitType != null ? props.order.product.unitType : Piece;
		return Formatting.unit( productUnit ); 		
	}

	function getDisplayQuantity() : String {

		if ( isSmartQtInput() ) {

			return Std.string( round( props.order.quantity * props.order.product.qt ) );
		}
		else {

			return Std.string( props.order.quantity );
		}

	}

	function getProductQuantity() : String {

		return Std.string( round(  Formatting.parseFloat(state.quantityInputValue) / props.order.product.qt ) );
	}

	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<OrderProps> {	
		
		return { users : Reflect.field(state, "reduxApp").users };
	}

	static function mapDispatchToProps( dispatch: redux.Redux.Dispatch, ownProps: OrderProps ) : react.Partial<OrderProps> {
				
		return { 

			updateOrderQuantity : function( orderQuantity ) {
									dispatch( OrderBoxAction.UpdateOrderQuantity( ownProps.order.id, orderQuantity ) ); 
								},
			reverseRotation : function( e: js.html.Event ) {
								dispatch( OrderBoxAction.ReverseOrderRotation( ownProps.order.id, untyped e.target.checked ) ); 
							  },
			updateOrderUserId2 : function( e: js.html.Event ) { 
									var userId2 = Std.parseInt(untyped e.target.value); 
									dispatch( OrderBoxAction.UpdateOrderUserId2( ownProps.order.id, userId2 == 0 ? null : userId2 ) );				
								 }
		}
	}

}