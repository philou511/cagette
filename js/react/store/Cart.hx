package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.FormControl;
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
	var updateCart:ProductInfo->Int->Void;
	var removeProduct:ProductInfo->Void;
	var resetCart:Void->Void;
	var order:OrderSimple;
}

private typedef PublicProps = {
	var submitOrder:OrderSimple->Void;
}

private typedef TClasses = Classes<[cagMiniBasketContainer,]>


@:publicProps(PublicProps)
@:connect
@:wrap(untyped Styles.withStyles(styles))
class Cart extends react.ReactComponentOfProps<CartProps> {
	
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
                }
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
			updateCart: function(product, quantity) {
				dispatch(CartAction.UpdateQuantity(product, quantity));
			},
			resetCart: function() {
				dispatch(CartAction.ResetCart);
			},
			removeProduct: function(p:ProductInfo) {
				dispatch(CartAction.RemoveProduct(p));
			}
		}
	}

	function submitOrder():Void {
		props.submitOrder(props.order);
	}

	override public function render() {
		var classes = props.classes;
		
		return jsx('
			<Grid item xs={3}>
				<div className=${classes.cagMiniBasketContainer}>
					<div className="cagMiniBasket">
						<i className="icon icon-truck-solid"></i> (${props.order.count}) <span>${props.order.total} €</span>
					</div>
					<div className="cart">
						<h3>Ma Commande</h3>
						${renderProducts()}
						${renderFooter()}
					</div>
				</div>
			</Grid>
		');
	}

	function updateQuantity(cartProduct:ProductWithQuantity, newValue:Int) {
		props.updateCart(cartProduct.product, newValue);
	}

	function renderProducts() {
		var productsToOrder = props.order.products.map(function(cartProduct:ProductWithQuantity) {
			var quantity = cartProduct.quantity;
			var product = cartProduct.product;

			return jsx('
				<div className="product-to-order" key=${product.name}>
					<div>${product.name}</div>
					<div className="cart-action-buttons">

						<QuantityInput onChange=${updateQuantity.bind(cartProduct)} value=${quantity}/>
						<div onClick=${props.removeProduct.bind(product)}>
							x
						</div>
					</div> 
				</div>
			');

		});

		return jsx('
			<div className="products-to-order">
				${productsToOrder}
			</div>
		');
	}

	function renderFooter() {
		var buttonClasses = ["order-button"];
		var submit = submitOrder;

		if (props.order.products.length == 0) {
			buttonClasses.push("order-button--disabled");
			submit = null;
		}

		return jsx('
			<div className="cart-footer">
				<div className="total">
					Total
					<div>${props.order.total} €</div>
				</div>
				<div className=${buttonClasses.join(" ")} onClick=$submit>Commander</div>
			</div>
		');
	}
}
