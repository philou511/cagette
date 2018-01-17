package react;
import utils.HttpUtil;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

//typedef RegisterBoxState = {firstName:String, lastName:String, email:String, password:String, error:String, phone:String};
//typedef RegisterBoxProps = {redirectUrl:String, phoneRequired:Bool};

/**
 * A box to edit the orders of a member
 * @author fbarbut
 */
class OrderBox extends react.ReactComponentOfPropsAndState<{userId:Int,distributionId:Int,contractId:Int,date:String,place:String,userName:String,onSubmit:Void->Void},{orders:Array<UserOrder>,error:String}>
{

	public function new(props) 
	{
		super(props);	
		state = { orders : [], error : null };
	}
	
	override function componentDidMount()
	{
		//request api avec user + distrib
		var p = HttpUtil.fetch("/api/order/get/"+props.userId, GET, {distributionId:props.distributionId,contractId:props.contractId},JSON);
		p.then(function(data:Dynamic) {

			if (Reflect.hasField(data, "error")) {
				setState(cast {error:data.error.message});
			}else{
				//WOOT
				setState({orders:data.orders, error:null});
				
				
				//
			}
			
			
		}).catchError(function(error) {
			trace("PROMISE ERROR :" + Std.string(error));
			setState(cast {error:error.message});
		});
	}
	
	override public function render(){
		
		var renderOrders = this.state.orders.map(function(o) return jsx('<$Order order="$o" onUpdate=$onUpdate  />') );
		
		return jsx('
			<div>
				<h3>Commandes de ${props.userName}</h3>
				<p>
					Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b>			
				</p>
				<$Error error="${state.error}" />
				${renderOrders}	
				<div>
					<a onClick=${onClick} className="btn btn-primary">
						<span className="glyphicon glyphicon-chevron-right"></span> Valider
					</a>
				</div>
			</div>			
		');
	}
	
	/**
	 * called when an order is updated
	 */
	function onUpdate(data:UserOrder){
		trace("ON UPDATE : " + data);
		for ( o in state.orders){
			if (o.productId == data.productId) {
				o.quantity = data.quantity;
				o.paid = data.paid;
			}
		}
	}
	
	/**
	 * submit updated orders to the API
	 */
	function onClick(_){
		
		var data = new Array<{productId:Int,qt:Float,paid:Bool}>();
		for ( o in state.orders) data.push({productId : o.productId, qt: o.quantity, paid : o.paid});
		trace("CLICK : " + data);
		
		var req = {
			orders:haxe.Json.stringify(data),
			distributionId : props.distributionId,
			contractId : props.contractId
		};
		
		var p = HttpUtil.fetch("/api/order/update/"+props.userId, POST, req,JSON);
		p.then(function(data:Dynamic) {
			
			if (Reflect.hasField(data, "error")) {
				setState(cast {error:data.error.message});
			}else{
				//WOOT
				//setState({orders:data.orders,error:null});
				trace("OK");
				if (props.onSubmit != null) props.onSubmit();
			}
		}).catchError(function(error) {
			trace("PROMISE ERROR", error);
			setState(cast {error:error.message});
		});
		
	}
	
	
}