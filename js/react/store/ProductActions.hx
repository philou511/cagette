package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import css.JustifyContent;
import css.AlignContent;
import react.store.redux.action.CartAction;
import mui.core.Button;
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Typography;
import mui.core.Grid;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import mui.icon.Icon;
import mui.CagetteTheme;
import Common;

private typedef Props = {
	> PublicProps,
    > ReduxProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    var product:ProductInfo;
}

private typedef ReduxProps = {
	var updateCart:ProductInfo->Int->Void;
	var addToCart:ProductInfo->Void;
    var quantity:Int;
}

private typedef TClasses = Classes<[
	button,
    card,
    area,
    productBuy,    
    cagProductInfoWrap,
    cagProductInfo,
    cagProductPriceRate,
    cagProductLabel,
]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
@:connect
class ProductActions extends ReactComponentOfProps<Props> {

    //https://cssinjs.org/jss-expand-full?v=v5.3.0
    //https://cssinjs.org/jss-expand-full/?v=v5.3.0#supported-properties
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			button:{
                size: "small",
                textTransform: None,
                color: '#84BD55',
            },
            card: {     
                backgroundColor: '#F8F4E5',
            },
            area: {     
                width: '100%',
            },
            productBuy: {
                boxShadow: "none",
            },
            cagProductLabel : {
                marginLeft : -3,
            },
            cagProductInfoWrap : {       
                justifyContent: SpaceBetween,
                padding: "0 10px",
            },
            cagProductInfo : {
                fontSize : "1.3rem",

                "& .cagProductUnit" : {
                    marginRight: "2rem",
                },

                "& .cagProductPrice" : {
                    color : CGColors.Third,        
                },
            },
            cagProductPriceRate : {        
                fontSize: "0.9rem",
                color : CGColors.Secondfont,
                //marginTop : -5,
                //marginLeft: 5,
            },
		}
	}

    static function mapStateToProps(st:react.store.redux.state.State, ownProps:PublicProps):react.Partial<Props> {
        var storeProduct = 0;
        for( p in st.cart.products ) { if( p.product == ownProps.product) {storeProduct = p.quantity ; break; }}
		return {
			quantity: storeProduct,
		}
	}

	static function mapDispatchToProps(dispatch:redux.Redux.Dispatch):react.Partial<Props> {
		return {
			updateCart: function(product, quantity) {
				dispatch(CartAction.UpdateQuantity(product, quantity));
			},
			addToCart: function(product) {
				dispatch(CartAction.AddProduct(product));
			},
		}
	}
    
    public function new(props) {
        super(props);
    }

    function updateQuantity(quantity:Int) {
        props.updateCart(props.product, quantity);
    }

    function addToCart() {
        props.addToCart(props.product);
    }

    function renderQuantityAction() {
        return if(props.quantity <= 0 ) {
            jsx(' <Button
                        onClick=${addToCart}
                        variant=${Contained}
                        color=${Primary} 
                        className=${props.classes.productBuy} 
                        disableRipple>                        
                        <i className="icon icon-basket-add"></i>
                    </Button>
            ');
        } else {
            jsx('<QuantityInput onChange=${updateQuantity} value=${props.quantity}/>');
        }
    }

    override public function render() {
        var classes = props.classes;
        var product = props.product;

        return jsx('
            <CardActions className=${classes.cagProductInfoWrap} >
                <Grid container>
                    
                    <Grid item xs={5} style={{textAlign:css.TextAlign.Left}}>
                        <Typography component="div" className=${classes.cagProductInfo} >                                 
                            <span className="cagProductUnit">
                                ${Formatting.formatNum(product.qt)}&nbsp;${Formatting.unit(product.unitType,product.qt)} 
                                <div className=${classes.cagProductPriceRate}>
                                    ${Formatting.pricePerUnit(product.price,product.qt,product.unitType)}
                                </div>
                            </span>
                        </Typography>
                    </Grid>
                    
                    <Grid item xs={3} style={{textAlign:css.TextAlign.Center}}>
                        <Typography component="div" className=${classes.cagProductInfo} >
                            <span className="cagProductPrice">
                                ${Formatting.formatNum(product.price)} €
                            </span> 
                        </Typography>  
                    </Grid>
                    
                    <Grid item xs={4} style={{textAlign:css.TextAlign.Right}}>
                        ${renderQuantityAction()}
                    </Grid>

                </Grid>
           </CardActions>
        ');

    }

}
