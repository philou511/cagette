package react;
import api.react.ReactMacro.jsx;
/**
 * ...
 * @author fbarbut
 */
class ProductComp extends api.react.ReactComponent
{

	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	override public function render(){
		return jsx('<div className="row ProductComp">
			<div className="col-md-4">
				<b>{this.props.name}</b>
			</div>
			<div className="col-md-4">
			{this.props.qt} {this.props.unit}
			</div>
			<div className="col-md-4">
				<a onClick="$delete" className="btn btn-default btn-xs">
					<span className="glyphicon glyphicon-remove"></span>
				</a>
			</div>
		
		</div>');
	}
	
	
	function delete(){
		
	}
}