package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

/**
 * A box to manage prices with and without VAT
 * @author fbarbut
 */
class VATBox extends react.ReactComponentOfPropsAndState<{ht:Float,currency:String,vatRates:String,vat:Float,formName:String},{ht:Float,ttc:Float,vat:Float}>
{

	public function new(props) 
	{
		super(props);
		trace(props);
		
		this.state = {ht:round(props.ht), ttc:round(props.ht+(props.ht*(props.vat/100))), vat:props.vat};
	}
	
	override public function render(){
		
		var rates :Array<Float>= props.vatRates.split("|").map(Std.parseFloat);
		
		var options = [for (r in rates) jsx('<option key="$r" value="$r">$r %</option>')  ];
		var priceInputName = props.formName+"_htPrice";
		var vatInputName = props.formName+"_vat";
		
		return jsx('<div>
				
				<div className="row">
					<div className="col-md-4 text-center"> Hors taxe </div>
					<div className="col-md-4 text-center"> Taux de TVA </div>
					<div className="col-md-4 text-center"> TTC </div>
				</div>
				
				<div className="row">
					<div className="col-md-4">
						<div className="input-group">
							<input type="text" name="ht" value="${state.ht}" className="form-control" onChange={onChange}/>
							<div className="input-group-addon">${props.currency}</div>
						</div>
					</div>
				
					<div className="col-md-4">
						<select name="vat" className="form-control" onChange={onChange} defaultValue=${state.vat}>							
							${options}
						</select>
					</div>
					
					<div className="col-md-4">
						<div className="input-group">
							<input type="text" name="ttc" value="${state.ttc}" className="form-control" onChange={onChange}/>
							<div className="input-group-addon">${props.currency}</div>
						</div>
					</div>
				</div>
				
				<input type="hidden" name="$priceInputName" value="${state.ht}" />
				<input type="hidden" name="$vatInputName" value="${state.vat}" />
		
			</div>
		');
	}
	

	/**
	 * Recompute prices 
	 */
	function onChange(e:js.html.Event){
		
		e.preventDefault();
		var name :String = untyped e.target.name;
		var v = StringTools.replace(untyped e.target.value, ",", ".");
		var value : Float = Std.parseFloat(v);
		//trace('onChange : $name = $value');
		
		var rate = 1 + (state.vat / 100);
		
		switch(name){
		case "ht":
			this.setState(cast {ht:value,ttc: round(value*rate) });	
		case "ttc":
			this.setState(cast {ht: round(value/rate)  ,ttc:value });	
		case "vat":
			rate = 1 + (value / 100);
			this.setState( { vat:value, ht:state.ht, ttc:round(state.ht*rate) } );
		default:
			
		}
		
		
	}
	
	function round(f:Float):Float{
		
		return Math.round(f * 100) / 100;
		
	}

	
}