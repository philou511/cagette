package react.store;

import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.FormControl;
import mui.core.Chip;
import mui.icon.Icon;

import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.cagette.action.CartAction;

import Common;
using Lambda;


typedef CartDetailsProps = {
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

private typedef TClasses = Classes<[cartDetails,]>

@:publicProps(PublicProps)
@:connect
@:wrap(untyped Styles.withStyles(styles))
class CartDetails extends react.ReactComponentOfProps<CartDetailsProps> {
	
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			cartDetails : {
                fontSize: "1.2rem",
                fontWeight: "bold",//TODO use enum from externs when available
                display: "flex",
                width: 300,
            },
		}
	}

	static function mapStateToProps(st:react.cagette.state.State):react.Partial<CartDetailsProps> {
		return {
			order: cast st.cart,
		}
	}

	static function mapDispatchToProps(dispatch:redux.Redux.Dispatch):react.Partial<CartDetailsProps> {
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

	override public function render() {
		var classes = props.classes;
		return jsx('
			<div className=${classes.cartDetails}>
				<h3>Ma Commande</h3>
				${renderProducts()}
				${renderFooter()}
			</div>
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
				<>
					<QuantityInput onChange=${updateQuantity.bind(cartProduct)} value=${quantity} />
					<Icon>star</Icon>
					<Chip color=${Secondary} onDelete=${props.removeProduct.bind(product)} variant=${Default} />
				</>
			');
		});
		//
		return jsx('
			<div>
				${productsToOrder}
			</div>
		');
	}

    function renderFooter() {
		var buttonClasses = ["order-button"];
		var submit = props.submitOrder;

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

