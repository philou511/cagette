package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import react.product.Product;
import react.order.redux.actions.OrderBoxAction;


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
	public function new(props) 
	{
		super(props);
		state = { quantityInputValue : null };
		state.quantityInputValue = if ( isSmartQtInput() ) {

										Std.string( round( props.order.quantity * props.order.productQt ) );
								  	}
								  	else {

										Std.string( props.order.quantity );
									}		
		
		if (props.order.productQt == null) props.order.productQt = 1;		
	}
	
	override public function render() {
		
		var input =  if ( isSmartQtInput() ) {

			jsx('<div className="input-group">
					<input type="text" className="form-control input-sm text-right" value=${state.quantityInputValue} onChange=${updateQuantity}/>
					<div className="input-group-addon">${getProductUnit()}</div>
				</div>');	
		}
		else {

			jsx('<div className="input-group">
					<input type="text" className="form-control input-sm text-right" value=${state.quantityInputValue} onChange=${updateQuantity}/>
				</div>');
		}

		var alternated = if( props.contractType == 0 && props.users != null ) {

			//constant orders
			var options = props.users.map(function(x) return jsx('<option key=${x.id} value=${x.id}>${x.name}</option>') );

			var checkbox = if(props.order.invertSharedOrder){
				jsx('<input data-toggle="tooltip" title="Inverser l\'alternance" checked="checked" type="checkbox" value="1"  onChange=${props.reverseRotation} />');
			}else{
				jsx('<input data-toggle="tooltip" title="Inverser l\'alternance" type="checkbox" value="1"  onChange=${props.reverseRotation} />');
			}	

			jsx('<div>
				<select className="form-control input-sm" style=${{width:"150px",display:"inline-block"}} onChange=${props.updateOrderUserId2} value=${props.order.userId2}>
					<option value="0">-</option>
					$options					
				</select>				
				$checkbox
			</div>');
		}else{
			null;
		}
		
		return jsx('<div className="productOrder row">
			<div className="col-md-4">
				<Product productInfo=${props.order.product} />
			</div>

			<div className="col-md-1 ref">
				${props.order.productRef}
			</div>

			<div className="col-md-1">
				${round(props.order.quantity * props.order.productPrice)}&nbsp;${props.currency}
			</div>
			
			<div className="col-md-2">
				$input			
				${makeInfos()}
			</div>

			${ props.contractType == 0 ? jsx('<div className="col-md-3">$alternated</div>') : null }
			
		</div>');
	}
	
	function round(f) {

		return Formatting.formatNum(f);
	}

	function makeInfos() {

		return if ( isSmartQtInput() ) {

			jsx('
			<div className="infos">
				<b> ${round(props.order.quantity)} </b> x <b>${props.order.productQt} ${getProductUnit()} </b> ${props.order.productName}
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
			orderQuantity = orderQuantity / props.order.productQt;
		}				
		props.updateOrderQuantity(orderQuantity); 
	}

	function getQuantityValue() : String {

		trace("on passe dans getQuantityValue!!!!");
		var temp : String = 	isSmartQtInput() ? Std.string( round( props.order.quantity * props.order.productQt ) ) : Std.string( props.order.quantity );
		trace(temp);
		return temp;
		
	}

	function getProductUnit() : String {

		var productUnit: Unit = props.order.productUnit != null ? props.order.productUnit : Piece;
		return Formatting.unit( productUnit ); 		
	}

	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<OrderProps> {	
		
		return { users: Reflect.field(state, "orderBox").users };
	}

	static function mapDispatchToProps( dispatch: redux.Redux.Dispatch, ownProps: OrderProps ) : react.Partial<OrderProps> {
				
		return { 

				updateOrderQuantity: function( orderQuantity ) {
					dispatch( OrderBoxAction.UpdateOrderQuantity( ownProps.order.id, orderQuantity ) ); 
				},
				reverseRotation: function( e: js.html.Event ) {
					dispatch( OrderBoxAction.ReverseOrderRotation( ownProps.order.id, untyped e.target.checked ) ); 
				},
				updateOrderUserId2: function( e: js.html.Event ) { 
					var userId2 = Std.parseInt(untyped e.target.value); 
					dispatch( OrderBoxAction.UpdateOrderUserId2( ownProps.order.id, userId2 == 0 ? null : userId2 ) );				
				}
		}
	}

}