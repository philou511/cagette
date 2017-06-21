package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
/**
 * ...
 * @author fbarbut
 */
class ReportHeader extends react.ReactComponentOfState<OrdersReportOptions>
{

	public function new() 
	{
		super();
		state = {startDate:null, endDate:null, groupBy:null, contracts:[]};
	}
	
	override public function render(){
		
		return jsx('<div className="reportHeader">		
			<DateInput name="startDate" onChange={onDateChange} />
			<DateInput name="endDate" onChange={onDateChange} />			
			<div className="input-group col-md-3">
			<select className="form-control" onChange={onGroupByChange}>
				<option value="ByMember">Par adhérent</option>
				<option value="ByProduct">Par Produit</option>
			</select>
			</div>			
			<div className="input-group col-md-3">
				<a className="btn btn-primary">Afficher</a>
			</div>					
		</div>');
		
	}
	
	function onDateChange(e:js.html.Event){
		trace("onDateChange");
		var name :String = untyped e.target.name;
		var value :String = untyped e.target.value;
		trace('$name $value');
		e.preventDefault();
	}
	
	/**
	 * @doc https://facebook.github.io/react/docs/forms.html
	 */
	function onGroupByChange(e:js.html.Event){
		e.preventDefault();
		trace("onGRoupByChange");
		var name :String = untyped e.target.name;
		var value :String = untyped e.target.value;
		if (value == "ByMember"){
			state.groupBy = ByMember;
		}else{
			state.groupBy = ByProduct;
		}
		trace(state);
		setState(state);
	}
	
	//override function setState(s){
		//trace(s);
		//this.setState(s);
	//}
}