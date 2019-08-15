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
import react.order.redux.reducers.OrderBoxReducer;

typedef OrderBoxState = {
	orders : Array<UserOrder>,	
	error:String,
	users:Null<Array<UserInfo>>,
};

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
	hasPayments:Bool,
	orders2 : Array<UserOrder>
};

/**
 * A box to edit/add orders of a member
 * @author fbarbut
 */
// @:connect
class OrderBox extends react.ReactComponentOfPropsAndState<OrderBoxProps,OrderBoxState>
{

	public function new(props) 
	{
		super(props);	
		state = { orders : [], error : null, users:null };
	}
	
	override function componentDidMount()
	{

		//request api avec user + distrib
		HttpUtil.fetch("/api/order/get/"+props.userId, GET, {distributionId:props.distributionId,contractId:props.contractId}, PLAIN_TEXT)
		.then(function(data:String) {
			
			var data : {orders:Array<UserOrder>} = tink.Json.parse(data);
			/*for( o in orders){
				//convert ints to enums, enums have been lost in json serialization
				o.productUnit = Type.createEnumIndex(Unit, cast o.productUnit );	
			}*/
			setState({orders:data.orders, error:null});

			if(props.contractType==0) loadUsers();

		}).catchError(function(data) {

			var data = Std.string(data);			
			if(data.substr(0,1)=="{"){
				//json error from server
				var data : ErrorInfos = haxe.Json.parse(data);
				setState( cast {error:data.error.message} );
			}else{
				//js error
				setState( cast {error:data} );
			}
		});
	}

	/**
	 *  load user list when contract is constant orders
	 */
	function loadUsers(){
		HttpUtil.fetch("/api/user/getFromGroup/", GET, {}, PLAIN_TEXT)
		.then(function(data:String) {

			var data : {users:Array<UserInfo>} = tink.Json.parse(data);
			setState({users:data.users, error:null});

		}).catchError(function(data) {

			var data = Std.string(data);
			if(data.substr(0,1)=="{"){
				//json error from server
				var data : ErrorInfos = haxe.Json.parse(data);
				setState( cast {error:data.error.message} );
			}else{
				//js error
				setState( cast {error:data} );
			}
		});
	}
	
	override public function render(){
		//edit orders 
		var renderOrders = this.state.orders.map(function(o){
			var k :String = if(o.id!=null) {
				Std.string(o.id);
			} else {
				o.product.id + "-" + Std.random(99999);
			};
			return jsx('<$Order key=${k} order=${o} onUpdate=$onUpdate parentBox=${this} />')	;
		}  );


		var delivery = 	if(props.date == null) {
							null;
						} else {
							jsx('<p>Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b></p>');
						}

		var renderOrderBox = function(props:react.router.RouteRenderProps):react.ReactFragment { 
			return jsx('
				<div onKeyPress=${onKeyPress}>
					<h3>Commandes de ${this.props.userName}</h3>
					$delivery			
					<$Error error=${state.error} />
					<hr/>
					<div className="row tableHeader">
						<div className="col-md-4">Produit</div>
						<div className="col-md-1">Ref.</div>
						<div className="col-md-1">Prix</div>
						<div className="col-md-2">Qté</div>
						${ this.props.contractType == 0 ? jsx('<div className="col-md-3">Alterné avec</div>') : null }
					</div>
					${renderOrders}	
					<div>
						<a onClick=${onClick} className="btn btn-primary">
							<i className="icon icon-chevron-right"></i> Valider
						</a>
						&nbsp;
						<$Link className="btn btn-default" to="/insert"><i className="icon icon-plus"></i> Ajouter un produit</$Link>
					</div>
				</div>			
			');
		}


		var onProductSelected = function(uo:UserOrder) {
			var existingOrder = Lambda.find(state.orders,function(x) return x.product.id == uo.product.id );
			if(existingOrder != null) {
				existingOrder.quantity += uo.quantity;
				this.setState(this.state);
			} else {
				this.state.orders.push(uo);
				this.setState(this.state);
			}
		};


		//insert product box
		var renderInsertBox = function(props:react.router.RouteRenderProps):react.ReactFragment {
			return jsx('<$InsertOrder selectedProduct=${null} contractId=${this.props.contractId} userId=${this.props.userId} distributionId=${this.props.distributionId} />');
		} 

		return jsx('
			<$HashRouter>
				<$Switch>
					<$Route path="/" exact=$true render=$renderOrderBox	 />
					<$Route path="/insert" exact=$true render=$renderInsertBox />
				</$Switch>
			</$HashRouter>
		');
	}
	
	/**
	 * called when an order is updated
	 */
	function onUpdate(data:UserOrder){
		/*trace("ON UPDATE : " + data);
		for ( o in state.orders){
			if (o.id == data.id) {
				o.quantity = data.quantity;
				o.paid = data.paid;
				break;
			}
		}
		setState(this.state);*/
	}
	
	/**
	 * submit updated orders to the API
	 */
	function onClick(?_){
		
		var data = new Array<{id:Int,productId:Int,qt:Float,paid:Bool,invertSharedOrder:Bool,userId2:Int}>();
		for ( o in state.orders) data.push({id:o.id, productId : o.product.id, qt: o.quantity, paid : o.paid, invertSharedOrder:o.invertSharedOrder, userId2:o.userId2});
		
		var req = { orders:data };
		
		var p = HttpUtil.fetch("/api/order/update/"+props.userId+"?distributionId="+props.distributionId+"&contractId="+props.contractId, POST, req, JSON);
		p.then(function(data:Dynamic) {

			//WOOT
			if (props.onValidate != null) props.onValidate();

		}).catchError(function(data) {

			var data = Std.string(data);
			if(data.substr(0,1)=="{"){
				//json error from server
				var data : ErrorInfos = haxe.Json.parse(data);
				setState( cast {error:data.error.message} );
			}else{
				//js error
				setState( cast {error:data} );
			}
		});
		
	}

	function onKeyPress(e:js.html.KeyboardEvent){
		if(e.key=="Enter") onClick();
	}


	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState, ownProps: OrderBoxProps ): react.Partial<OrderBoxProps> {		

		var existingOrder = Lambda.find( ownProps.orders2, function(order) return order.product.id == state.selectedProduct.id );
		if( existingOrder != null ) {
		
			existingOrder.quantity += 1;			
		}
		else {

			var order : UserOrder = cast {
						id: null,
						product: state.selectedProduct,
						quantity: 1,
						productId: state.selectedProduct.id,
						productPrice: state.selectedProduct.price,
						paid: false,
						invert: false,
						user2: null
						};
			
			ownProps.orders2.push(order);
		}

		return { orders2 : ownProps.orders2 };
	}
	
}