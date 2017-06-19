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
	}
	
	override public function render(){
		
		return jsx('<div className="reportHeader">		
			<DateInput />
			<DateInput />			
			<div className="input-group col-md-3">
			<select className="form-control">
				<option value="ByMember">Par adhérent</option>
				<option value="ByProduct">Par Produit</option>
			</select>
			</div>			
			<div className="input-group col-md-3">
				<a className="btn btn-primary">Afficher</a>
			</div>					
		</div>');
		
	}
	
}