package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.common.Position;
import mui.core.TextField;
import mui.core.FormControl;
import mui.core.Popover;
import mui.core.popover.AnchorPosition;
import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import Common;
import react.cagette.action.CartAction;

using Lambda;

typedef CartProps = {
	> PublicProps,
	> ReduxProps,
	var classes:TClasses;
}

private typedef ReduxProps = {
	var order:OrderSimple;
}

private typedef PublicProps = {
	var submitOrder:OrderSimple->Void;
}

private typedef TClasses = Classes<[cagMiniBasketContainer,]>

private typedef CartState = {
	var cartOpen:Bool;
}

@:publicProps(PublicProps)
@:connect
@:wrap(untyped Styles.withStyles(styles))
class Cart extends react.ReactComponentOf<CartProps, CartState> {
	
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			cagMiniBasketContainer : {
                fontSize: "1.2rem",
                fontWeight: "bold",//TODO use enum from externs when available
                display: "flex",
                alignItems: Center,
                justifyContent: Center,
                 
                "& .cagMiniBasket" : {
                    borderRadius : 5,
                    border : '1px solid ${CGColors.Bg1}',
                    width: "100%",
                    textAlign: css.TextAlign.Center,
                    padding: "0.5em",
                },

                "& i": { 
                    verticalAlign: "middle",
                },
                "& span" : {
                    color : CGColors.Third,  
                },
            },
		}
	}

	static function mapStateToProps(st:react.cagette.state.State):react.Partial<CartProps> {
		return {
			order: cast st.cart,
		}
	}

	static function mapDispatchToProps(dispatch:redux.Redux.Dispatch):react.Partial<CartProps> {
		return {
		}
	}

	var cartRef:Dynamic;//TODO
	public function new(props) {
		super(props);
		this.state = {cartOpen : false};
		this.cartRef = React.createRef();
	}

	function onCartClicked() {
		trace(state.cartOpen ? "closing" : "opening");
		setState({cartOpen : !state.cartOpen});
	}

	function handleClose(e : Null<js.html.Event>, reason: mui.core.modal.ModalCloseReason) {
		setState({cartOpen: false});
	}

	override public function render() {
		var classes = props.classes;
		return jsx('
			<Grid item xs={3}>
				<div className=${classes.cagMiniBasketContainer} onClick=${onCartClicked}>
					<div className="cagMiniBasket" ref={this.cartRef}>
						<i className="icon icon-truck"></i> (${props.order.count}) <span>${props.order.total} €</span>
					</div>
				</div>
				<Popover open={state.cartOpen}
						anchorEl={this.cartRef.current}
						onClose={this.handleClose}
						anchorOrigin={{vertical: Bottom, horizontal: Right,}}
						transformOrigin={{vertical: Top,horizontal: Right,}}
					>
					<CartDetails submitOrder=${props.submitOrder}/>
				</Popover>
			</Grid>
		');
	}
}
