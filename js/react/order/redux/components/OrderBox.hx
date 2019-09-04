package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.UserOrder;
import react.router.HashRouter;
import react.router.Route;
import react.router.Switch;
import react.router.Link;
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
	var orders : Array<UserOrder>;
	var fetchOrders : Int -> Int -> Int -> Int -> Void;
	var updateOrders : Int -> Int -> String -> Void;
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
	
	override public function render(){
		
		//Let's group orders by contract id to display them for each contract
		var ordersByContractId = new Map<Int, Array<UserOrder>>();
		for( order in props.orders ) {

			if( ordersByContractId[order.contractId] == null ) {

				ordersByContractId[order.contractId] = [];
			}
			
			ordersByContractId[order.contractId].push(order);			
		}

		var ordersByContract = [];
		for( contractId in ordersByContractId.keys() ) {
					
			ordersByContract.push( jsx('<h4 key=${contractId}>${ordersByContractId[contractId][0].contractName}</h4>') );			

			for ( order in ordersByContractId[contractId] ) {

				var key : String = if( order.id != null ) {
				
					Std.string(order.id);
				}
				else {
				
					order.product.id + "-" + Std.random(99999);
				};

				ordersByContract.push( jsx( '<Order key=${key} order=${order} currency=${props.currency} contractType=${props.contractType} />' ));
			}	
		}
				
		var delivery = 	props.date == null ? null : jsx('<p>Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b></p>');

		//Julie
		// var validateButton = jsx('<a onClick=${props.updateOrders.bind( props.userId, props.multiDistribId, props.callbackUrl )} className="btn btn-primary">
		// 							<i className="icon icon-chevron-right"></i> Valider
		// 						 </a>' );

		var validateButton = jsx('<Button onClick=${props.updateOrders.bind( props.userId, props.multiDistribId, props.callbackUrl )} variant={Contained} style=${{color:CGColors.White, backgroundColor:CGColors.Secondary}} >
									${CagetteTheme.getIcon("chevron-right")}&nbsp;Valider
								 </Button>');				
		 		 
		var addButtonTo = props.contractId == null ? "/contracts" : "/insert";

		// var className1 = this.props.contractType != 0 ? "col-md-4 text-center" : ;
		
        var renderOrderBox = function( props : react.router.RouteRenderProps ) : react.ReactFragment { 
			return jsx('<div onKeyPress=${onKeyPress}>
							<h3>Commandes de ${this.props.userName}</h3>
							$delivery
							<Error error=${this.props.error} />							
							<hr/>
							<div className="row tableHeader" >
								<div className="col-md-4 text-center">Produit</div>
								<div className="col-md-3 text-center">Ref.</div>
								<div className="col-md-1 text-center">Prix</div>
								<div className="col-md-2 text-center">Qté</div>
								${ this.props.contractType == 0 ? jsx('<div className="col-md-3 text-center">Alterné avec</div>') : null }
							</div>
							${ordersByContract}	
							<div style=${{marginTop: 20}}>
								${validateButton}						
								&nbsp;																
								<Button onClick=${function() { js.Browser.location.hash = addButtonTo; }} size={Medium} variant={Outlined}>
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
					<Route path="/" exact=$true render=$renderOrderBox />
					${ props.contractId != null ? null : jsx('<Route path="/contracts" exact=$true render=$renderContractsBox />') }
					<Route path="/insert" exact=$true render=$renderInsertBox />
				</Switch>
			</HashRouter>
		');
	}	

	function onKeyPress(e : js.html.KeyboardEvent) {
		
		if ( e.key == "Enter" ) {

			props.updateOrders( props.userId, props.multiDistribId, props.callbackUrl );
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
			updateOrders : function( userId : Int, multiDistribId : Int, callbackUrl : String ) {
							return dispatch( OrderBoxThunk.updateOrders( userId, multiDistribId, callbackUrl ) );
						  }
		}

	}	
	
}