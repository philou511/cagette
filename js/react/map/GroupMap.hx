package react.map;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

/**
 * Groups Map
 * @author fbarbut
 */
class GroupMap extends react.ReactComponentOfPropsAndState<{lat:Float,lng:Float,address:String},{}>{

	public function new(props) 
	{
		super(props);
	}
	
	override public function render(){
		return jsx("<div><h1>new Map in React JS</h1></div>");
	}
	
}