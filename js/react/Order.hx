package react;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
//typedef OrderState = {>UserOrder,};
//typedef RegisterBoxProps = {redirectUrl:String, phoneRequired:Bool};


/**
 * A User order
 * @author fbarbut
 */
class Order extends react.ReactComponentOfPropsAndState<{order:UserOrder,onUpdate:UserOrder->Void},{order:UserOrder}>
{

	public function new(props) 
	{
		super(props);
		
		state = {order:props.order};
		//convert ints to enums
		state.order.productUnit = Type.createEnumIndex(UnitType, Std.parseInt(cast state.order.productUnit));
		if (state.order.productQt == null) state.order.productQt = 1;
		if (state.order.productUnit == null) state.order.productUnit = Piece;		
		//state.infos = makeInfos();
		
		trace(state);
	}
	
	override public function render(){
		var o = state.order;
		var unit = if (o.productHasFloatQt){
			jsx('<div className="col-md-1">${Formatting.unit(o.productUnit)}</div>');
		}else{
			jsx('<div className="col-md-1"></div>');
		}
		
		//use smart qt only if hasFloatQt
		var productName = if (o.productHasFloatQt){
			jsx('<div className="col-md-3">${o.productName}</div>');
		}else{			
			jsx('<div className="col-md-3">${o.productName} ${o.productQt} ${Formatting.unit(o.productUnit)}</div>');
		}
		
		var input =  if (o.productHasFloatQt){
			jsx('<div className="col-md-2">
				<input type="text" className="form-control input-sm text-right" value="${round(o.quantity*o.productQt)}" onChange=${onChange}/>
			</div>');
		}else{
			jsx('<div className="col-md-2">
				<input type="text" className="form-control input-sm text-right" value="${o.quantity}" onChange=${onChange}/>
			</div>');	
		}
		
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
		return if (o.productHasFloatQt){
			jsx( '<div className="col-md-12 infos">
				<b> ${round(o.quantity)} </b> x <b>${o.productQt} ${Formatting.unit(o.productUnit)}</b> ${o.productName}
			</div>');
		}else{
			null;
		}
	}
	
	function onChange(e:js.html.Event){
		e.preventDefault();		
		var value = Std.parseFloat(untyped (e.target.value == "") ? 0 : e.target.value);
		var o = state.order;
		if ( o.productHasFloatQt){
			//if has float qt, the value is a smart qt, so we need re-compute the quantity
			o.quantity = value / o.productQt;
		}else{
			o.quantity = value;	
		}
		
		this.setState(state);
		if (props.onUpdate != null) props.onUpdate(state.order);
		trace(state);
		
	}
}