package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.router.HashRouter;
import react.router.Route;
import react.router.Switch;
import react.router.Link;

typedef OrderBoxState = {orders:Array<UserOrder>,error:String};
typedef OrderBoxProps = {
	userId:Int,
	distributionId:Int,
	contractId:Int,
	contractType:Int,
	date:String,
	place:String,
	userName:String,
	onValidate:Void->Void,
	currency:String,
	hasPayments:Bool
};

/**
 * A box to edit/add orders of a member
 * @author fbarbut
 */
class OrderBox extends react.ReactComponentOfPropsAndState<OrderBoxProps,OrderBoxState>
{

	public function new(props) 
	{
		super(props);	
		state = { orders : [], error : null };
	}
	
	override function componentDidMount()
	{
		/*if(App.SAVED_ORDER_STATE!=null) {
			//get state from saved state
			trace("restore previous state");
			setState(App.SAVED_ORDER_STATE);
			return;
		}*/

		//request api avec user + distrib
		HttpUtil.fetch("/api/order/get/"+props.userId, GET, {distributionId:props.distributionId,contractId:props.contractId}, PLAIN_TEXT)
		.then(function(data:String) {

			var data : {orders:Array<UserOrder>} = tink.Json.parse(data);
			/*for( o in orders){
				//convert ints to enums, enums have been lost in json serialization
				o.productUnit = Type.createEnumIndex(UnitType, cast o.productUnit );	
			}*/
			setState({orders:data.orders, error:null});
		}).catchError(function(data) {
			var data = Std.string(data);
			trace("Error",data);
			if(data.substr(0,1)=="{"){
				//json error from server
				var data : ErrorInfos = haxe.Json.parse(data);
				setState(cast {error:data.error.message} );
			}else{
				//js error
				setState(cast {error:data} );
			}
		});
	}
	
	override public function render(){
		
		//edit orders 


		var renderOrders = this.state.orders.map(function(o){
			var k :String = if(o.id!=null) {
				Std.string(o.id);
			} else {
				o.productId+"-"+Std.random(99999);
			};
			return jsx('<$Order key="$k" order="$o" onUpdate=$onUpdate parentBox=${this} />')	;
		}  );
		var renderOrderBox = function() return jsx('
			<div>
				<h3>Commandes de ${props.userName}</h3>
				<p>
					Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b>			
				</p>
				<$Error error="${state.error}" />
				<hr/>
				${renderOrders}	
				<div>
					<a onClick=${onClick} className="btn btn-primary">
						<span className="glyphicon glyphicon-chevron-right"></span> Valider
					</a>
					&nbsp;
					<$Link className="btn btn-default" to="/insert"><span className="glyphicon glyphicon-plus-sign"></span> Nouvelle commande</$Link>
				</div>
			</div>			
		');


		var onProductSelected = function(uo:UserOrder){

			var existingOrder = Lambda.find(state.orders,function(x) return x.productId==uo.productId );
			if(existingOrder!=null){
				existingOrder.quantity += uo.quantity;
				this.setState(this.state);
			}else{
				this.state.orders.push(uo);
				this.setState(this.state);
			}
		
		};


		//insert product box
		var renderInsertBox = function(){
			return jsx('<$InsertOrderBox contractId="${props.contractId}" userId="${props.userId}" distributionId="${props.distributionId}" onInsert=$onProductSelected/>');
		} 

		return jsx('<$HashRouter>
			<$Switch>
				<$Route path="/" exact=$true render=$renderOrderBox	 />
				<$Route path="/insert" exact=$true render=$renderInsertBox />
			</$Switch>
		</$HashRouter>');



		
	}
	
	/**
	 * called when an order is updated
	 */
	function onUpdate(data:UserOrder){
		trace("ON UPDATE : " + data);
		for ( o in state.orders){
			if (o.id == data.id) {
				o.quantity = data.quantity;
				o.paid = data.paid;
				break;
			}
		}
		setState(this.state);
		/*
		//save state outside component
		trace("save state");
		App.SAVED_ORDER_STATE = this.state;*/
	}
	
	/**
	 * submit updated orders to the API
	 */
	function onClick(_){
		
		var data = new Array<{id:Int,productId:Int,qt:Float,paid:Bool}>();
		for ( o in state.orders) data.push({id:o.id, productId : o.productId, qt: o.quantity, paid : o.paid});
		trace("CLICK : " + data);
		
		var req = {
			orders:haxe.Json.stringify(data),
			distributionId : props.distributionId,
			contractId : props.contractId
		};
		
		var p = HttpUtil.fetch("/api/order/update/"+props.userId, POST, req,JSON);
		p.then(function(data:Dynamic) {

			//WOOT
			trace("OK");
			if (props.onValidate != null) props.onValidate();

		}).catchError(function(data) {
			trace("PROMISE ERROR", data);
			this.state.error = data.error.message;
			setState(this.state);
		});
		
	}

	
	
}