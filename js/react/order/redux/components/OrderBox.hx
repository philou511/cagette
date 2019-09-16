package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.UserOrder;
import react.router.HashRouter;
import react.router.Route;
import react.router.Switch;
import react.order.redux.actions.OrderBoxAction;
import react.order.redux.actions.thunk.OrderBoxThunk;

//Material UI
import react.mui.CagetteTheme;
import mui.core.Button;


typedef OrderBoxProps = {

	var userId : Int;
	var multiDistribId : Int;
	var contractId : Int;
	var contractType : Int;
	var date : String;
	var place : String;
	var userName : String;
	var callbackUrl : String;
	var currency : String;
	var hasPayments : Bool;
	var orders : Array<UserOrder>;
	var fetchOrders : Int -> Int -> Int -> Int -> Void;
	var updateOrders : Int -> String -> Int -> Int -> Void;
	var error : String;	
};


/**
 * A box to edit/add orders of a member
 * @author fbarbut
 */
@:connect
class OrderBox extends react.ReactComponentOfProps<OrderBoxProps> {

	public function new(props) {

		super(props);
	}
	
	override function componentDidMount() {
		
		props.fetchOrders( props.userId, props.multiDistribId, props.contractId, props.contractType );		
	}
	
	override public function render() {
		
		//Let's group orders by contract id to display them for each contract
		var ordersByContractId = new Map<Int, Array<UserOrder>>();
		for( order in props.orders ) {

			if( ordersByContractId[order.contractId] == null ) {

				ordersByContractId[order.contractId] = [];
			}
			
			ordersByContractId[order.contractId].push(order);			
		}

		var ordersByContract = [];
		var totalPrice = 0.0;
		for( contractId in ordersByContractId.keys() ) {
					
			ordersByContract.push( jsx('<h4 key=${contractId}>${ordersByContractId[contractId][0].contractName}</h4>') );			

			for ( order in ordersByContractId[contractId] ) {

				var key : String = if( order.id != null ) {
				
					Std.string(order.id);
				}
				else {
				
					order.product.id + "-" + Std.random(99999);
				};

				ordersByContract.push( jsx( '<Order key=${key} order=${order} currency=${props.currency} hasPayments=${props.hasPayments} contractType=${props.contractType} />' ));

				totalPrice += order.quantity * order.product.price;
						
			}	
		}

		//total
		// var className1 = this.props.contractType != 0 ? "col-md-5 text-center" : "col-md-3 text-center";
		// var className2 = this.props.contractType != 0 ? "col-md-2 text-center" : "col-md-2 text-center";
		// var className3 = this.props.contractType != 0 ? "col-md-2 text-center" : "col-md-1 text-center";
		// var className4 = this.props.contractType != 0 ? "col-md-2 text-center" : "col-md-2 text-center";

		var className1 = "";
		var className2 = "";
		var className3 = "";
		var className4 = "";

		if ( props.contractType != 0 ) {

			className1 = "col-md-5 text-center";
			className2 = "col-md-3 ref text-center";
			className3 = "col-md-2 text-center";
			className4 = "col-md-2 text-center";

			if ( !props.hasPayments ) {

				className2 = "col-md-2 ref text-center";
			}
		}
		else {

			className1 = "col-md-3 text-center";
			className2 = "col-md-2 ref text-center";
			className3 = "col-md-1 text-center";
			className4 = "col-md-2 text-center";

			if ( !props.hasPayments ) {

				className2 = "col-md-1 ref text-center";
			}
		}		

		ordersByContract.push(jsx('<div className="row">			
			<div className=${className1}></div>
			<div className=${className2}><b>TOTAL</b></div>
			<div className=${className3}><b>${Formatting.formatNum(totalPrice)}&nbsp;&euro;</b></div>
			<div className=${className4}></div>
			</div>'));
			
		var delivery = 	props.date == null ? null : jsx('<p>Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b></p>');

		var validateButton = jsx('<Button onClick=${props.updateOrders.bind( props.userId, props.callbackUrl, props.multiDistribId, props.contractId )} variant={Contained} style=${{color:CGColors.White, backgroundColor:CGColors.Secondary}} >
									${CagetteTheme.getIcon("chevron-right")}&nbsp;Valider
								 </Button>');				
		
		
		
        var renderOrderBox = function( props : react.router.RouteRenderProps ) : react.ReactFragment { 

			return jsx('<div onKeyPress=${onKeyPress}>
							<h3>Commandes de ${this.props.userName}</h3>
							$delivery
							<Error error=${this.props.error} />							
							<hr/>
							<div className="row tableHeader" >
								<div className=${className1}>Produits</div>
								<div className=${className2}>Ref.</div>
								<div className=${className3}>Prix</div>
								<div className=${className4}>Qté</div>
								${ !this.props.hasPayments ? jsx('<div className="col-md-1 text-center">Payé</div>') : null }
								${ this.props.contractType == 0 ? jsx('<div className="col-md-3 text-center">Alterné avec</div>') : null }
							</div>
							${ordersByContract}	
							<div style=${{marginTop: 20}}>
								${validateButton}						
								&nbsp;																
								<Button onClick=${function() { js.Browser.location.hash = this.props.contractId == null ? "/contracts" : "/insert"; }} size={Medium} variant={Outlined}>
									${CagetteTheme.getIcon("plus")}&nbsp;&nbsp;Ajouter un produit
								</Button>			
							</div>
						</div>');
		}

		//Display contracts box
		var renderContractsBox = function( props : react.router.RouteRenderProps ) : react.ReactFragment {
			return jsx('<ContractsBox multiDistribId=${this.props.multiDistribId} />');
		} 

		//insert product box
		var renderInsertBox = function( props : react.router.RouteRenderProps ) : react.ReactFragment {
			return jsx('<InsertOrder contractId=${this.props.contractId} userId=${this.props.userId} multiDistribId=${this.props.multiDistribId} />');
		} 

		return jsx('
			<HashRouter>
				<Switch>
					<Route key="orders" path="/" exact=$true render=$renderOrderBox />
					${ props.contractId != null ? null : jsx('<Route key="contracts" path="/contracts" exact=$true render=$renderContractsBox />') }
					<Route key="products" path="/insert" exact=$true render=$renderInsertBox />
				</Switch>
			</HashRouter>
		');
	}	

	function onKeyPress(e : js.html.KeyboardEvent) {
		
		if ( e.key == "Enter" ) {

			props.updateOrders( props.userId, props.callbackUrl, props.multiDistribId, props.contractId );
		} 
	}	

	static function mapStateToProps( state: react.order.redux.reducers.OrderBoxReducer.OrderBoxState ): react.Partial<OrderBoxProps> {		

		return { orders: Reflect.field(state, "reduxApp").orders,
				 error : Reflect.field(state, "reduxApp").error };
	}

	static function mapDispatchToProps( dispatch : redux.Redux.Dispatch ) : react.Partial<OrderBoxProps> {
				
		return { 
			
			fetchOrders : function( userId : Int, multiDistribId : Int, contractId : Int, contractType : Int ) {
							return dispatch( OrderBoxThunk.fetchOrders( userId, multiDistribId, contractId, contractType ) );
						  },
			updateOrders : function( userId : Int, callbackUrl : String, multiDistribId : Int, contractId : Int ) {
							return dispatch( OrderBoxThunk.updateOrders( userId, callbackUrl, multiDistribId, contractId ) );
						  }
		}

	}	
	
}