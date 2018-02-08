package react;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

/**
 * A User order
 * @author fbarbut
 */
class Order extends react.ReactComponentOfPropsAndState<{order:UserOrder,onUpdate:UserOrder->Void},{order:UserOrder,inputValue:String}>
{

	public function new(props) 
	{
		super(props);
		state = {order:props.order,inputValue:null};
		
		if (state.order.productUnit == null){
			state.order.productUnit = Piece;
		}else{
			//convert ints to enums, enums have been lost in json serialization
			state.order.productUnit = Type.createEnumIndex(UnitType, cast state.order.productUnit );	
		}		
		if (state.order.productQt == null) state.order.productQt = 1;
		
		state.inputValue = if (state.order.productHasFloatQt || state.order.productHasVariablePrice){
			Std.string(round(state.order.quantity * state.order.productQt));
		}else{
			Std.string(state.order.quantity);
		}
	}
	
	override public function render(){
		var o = state.order;
		var unit = if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-1">${Formatting.unit(o.productUnit)}</div>');
		}else{
			jsx('<div className="col-md-1"></div>');
		}
		
		//use smart qt only if hasFloatQt
		var productName = if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-3">${o.productName}</div>');
		}else{			
			jsx('<div className="col-md-3">${o.productName} ${o.productQt} ${Formatting.unit(o.productUnit)}</div>');
		}
		
		var input =  jsx('<div className="col-md-2">
				<input type="text" className="form-control input-sm text-right" value="${state.inputValue}" onChange=${onChange} onKeyPress=${onKeyPress}/>
			</div>');	
		
		
		var s = {backgroundImage:"url(\""+o.productImage+"\")", width:"32px", height:"32px"};
		return jsx('<div className="productOrder row">
			<div className="col-md-1">
				<div style="$s" className="productImg"></div>
			</div>
			<div className="col-md-1 ref">
				${o.productRef}
			</div>
			
			${productName}

			<div className="col-md-1">
				${o.productPrice} &euro;
			</div>
			
			$input
			
			$unit
	
			<div className="col-md-1">
				<!--Payé : <input type="checkbox" name="paid" value="${o.paid}" />-->
			</div>
			<div className="col-md-2">
				<!--alterné avec X <br/>inverser alternance X-->
			</div>				
			${makeInfos()}
		</div>');
		
		
	}
	
	function round(f){
		return Formatting.formatNum(f);
	}
	
	function makeInfos(){
		var o = state.order;
		return if (o.productHasFloatQt || o.productHasVariablePrice){
			jsx('<div className="col-md-12 infos">
				<b> ${round(o.quantity)} </b> x <b>${o.productQt} ${Formatting.unit(o.productUnit)}</b > ${o.productName}
				/ Prix <b>${round(o.quantity * o.productPrice)} &euro;</b>
			</div>');
		}else{
			null;
		}
	}
	
	function onChange(e:js.html.Event){
		e.preventDefault();		
		var value :String = untyped (e.target.value == "") ? "0" : e.target.value;
		state.inputValue = value;
		var v = Formatting.parseFloat(value);
		var o = state.order;
		if ( o.productHasFloatQt || o.productHasVariablePrice){
			//if has float qt or variablePrice, the value is a smart qt, so we need re-compute the quantity
			o.quantity = v / o.productQt;
		}else{
			o.quantity = v;	
		}
		
		this.setState(state);
		if (props.onUpdate != null) props.onUpdate(state.order);
		trace(state);
	}
	
	function onKeyPress(event:js.html.KeyboardEvent){
		/*if(event.key == 'Enter'){
			trace('enter !');
		}*/
	}
}

