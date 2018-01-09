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
class Order extends react.ReactComponentOfPropsAndState<{order:UserOrder,onUpdate:UserOrder->Void},{order:UserOrder,infos:String}>
{

	public function new(props) 
	{
		super(props);
		
		state = {order:props.order, infos:null};
		//convert ints to enums
		state.order.productUnit = Type.createEnumIndex(UnitType, Std.parseInt(cast state.order.productUnit));
		if (state.order.productQt == null) state.order.productQt = 1;
		if (state.order.productUnit == null) state.order.productUnit = Piece;		
		state.infos = makeInfos();
		
		trace(state);
	}
	
	override public function render(){
		var o = state.order;
		var unit = Formatting.unit(o.productUnit);
		//var smartQt = Formatting.smartQt(o.quantity, o.productQt, o.productUnit);
		
		var s = {backgroundImage:"url(\""+o.productImage+"\")", width:"32px", height:"32px"};
		var infos = o.quantity!=Math.abs(o.quantity) && o.productQt!=1 ? jsx( '<div className="col-md-12 infos"> ${state.infos}</div>') : null;
		return jsx('<div className="productOrder row">
			<div className="col-md-1">
				<div style="$s" className="productImg"></div>
			</div>
			<div className="col-md-1 ref">
				${o.productRef}
			</div>
			<div className="col-md-3">
				${o.productName}
			</div>
			<div className="col-md-1">
				${o.productPrice} &euro;
			</div>
			<div className="col-md-2">
				<input type="text" className="form-control input-sm text-right" name="productXXX:" id="productXXX" value="${round(o.quantity*o.productQt)}" onChange=${onChange}/>
			</div>			
			<div className="col-md-1">
				${unit}
			</div>
			<div className="col-md-1">
				Payé : <input type="checkbox" name="paid" value="${o.paid}" />
			</div>
			<div className="col-md-2">
				alterné avec X <br/>inverser alternance X
			</div>				
			$infos
		</div>');
		
		
	}
	
	function round(f){
		return Formatting.formatNum(f);
	}
	
	function makeInfos(){
		var o = state.order;
		return round(o.quantity) +" x "+ o.productName + " " + o.productQt + " " + Formatting.unit(o.productUnit);
	}
	
	function onChange(e:js.html.Event){
		e.preventDefault();		
		var value = Std.parseFloat(untyped (e.target.value == "") ? 0 : e.target.value);
		state.order.quantity = value / state.order.productQt;
		state.infos = makeInfos();
		this.setState(state);
		if (props.onUpdate != null) props.onUpdate(state.order);
		trace(state);
		
	}
}