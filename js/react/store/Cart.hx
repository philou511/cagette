package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.Align;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.FormControl;
import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import Common;

using Lambda;

typedef CartProps = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
	var order:OrderSimple;
	var addToCart:ProductInfo->Int->Void;
	var removeFromCart:ProductInfo->?Int->Void;
	var submitOrder:OrderSimple->Void;
}

private typedef TClasses = Classes<[cagMiniBasketContainer,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
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
                    textAlign: Center,
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

	function addToCart(product:ProductInfo, quantity:Int):Void {
		props.addToCart(product, quantity);
	}

	function removeFromCart(product:ProductInfo, quantity:Int):Void {
		props.removeFromCart(product, quantity);
	}

	function removeAllFromCart(product:ProductInfo):Void {
		props.removeFromCart(product);
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
						<i className="icon icon-truck-solid"></i> (0) <span>0,00 €</span> <i className="icon icon-truck-solid"></i>
					</div>
				</div>
			</Grid>
		');
		/*
		<div className="cart">
			<h3>Ma Commande</h3>
			${renderProducts()}
			${renderFooter()}
		</div>
		 */
	}

	function updateQuantity(cartProduct:ProductWithQuantity, newValue:Int) {
		if (newValue > cartProduct.quantity) {
			this.addToCart(cartProduct.product, 1);
		} else if (newValue < cartProduct.quantity) {
			this.removeFromCart(cartProduct.product, 1);
		}
	}

	function renderProducts() {
		var productsToOrder = props.order.products.map(function(cartProduct:ProductWithQuantity) {
			var quantity = cartProduct.quantity;
			var product = cartProduct.product;

			return jsx('
				<div className="product-to-order" key=${product.name}>
					<div>${product.name}</div>
					<div className="cart-action-buttons">

						<QuantityInput onChange=${updateQuantity.bind(cartProduct)} defaultValue=${quantity}/>
						<div onClick=${function(){
							this.removeAllFromCart(product);
						}}>
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
