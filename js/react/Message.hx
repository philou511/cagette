package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

/**
 * A message Div
 */
class Message extends react.ReactComponentOfProps<{message:String}>
{

	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	override public function render(){
		
		if (props.message == null) return null;
		
		return jsx('<div className="alert alert-warning">
				<span className="glyphicon glyphicon glyphicon-info-sign"></span> ${props.message}
			</div>
		');
	}
}