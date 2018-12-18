package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import css.JustifyContent;
import css.AlignContent;

import mui.core.Backdrop;
import mui.core.Button;
import mui.core.Card;
import mui.core.Grid;
import mui.core.GridList;
import mui.core.CardMedia;
import mui.core.CardContent;
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Modal;
import mui.core.modal.ModalCloseReason;
import mui.core.Typography;
import mui.core.Avatar;
import mui.core.Paper;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import mui.icon.Icon;
import react.cagette.action.CartAction;
import mui.CagetteTheme;

import Formatting.unit;
import Common;

private typedef Props = {
	> PublicProps,
    > ReduxProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    var product:ProductInfo;
    var onClose:js.html.Event->ModalCloseReason->Void;
}

private typedef ReduxProps = {
	var updateCart:ProductInfo->Int->Void;
	var addToCart:ProductInfo->Void;
    var quantity:Int;
}

/*
private typedef ProductModalState = {
    var opened : Bool;
}
*/

private typedef TClasses = Classes<[
	gridItem,

	paper, 
	cartFooter,
	products, 
	product, 
	iconStyle, 
	subcard, 
	cover,
    productBuy,
	cagProductTitle,
    cagProductInfoWrap,
    cagProductInfo,
    cagProductPriceRate,
]>


@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
@:connect
class ProductModal extends ReactComponentOfProps<Props> {
    public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			paper : {
                display: "flex",
				justifyContent: Center,
				alignItems: Center,

                position: Absolute,
                backgroundColor: CGColors.White,
            },
			subcard: {
				flexDirection: css.FlexDirection.Row,
				display: 'flex',
			},
			gridItem: {
				overflow: Hidden,
			},
			cartFooter: {
				display: "flex",
				flexDirection: Column,
				fontSize: "1.8rem",
				alignItems:Center,
				justifyContent:SpaceEvenly,
			},
			products : {
				display: "flex",
				justifyContent: SpaceAround,
				alignItems: Center,
				maxHeight: (4*80),
				overflow: Auto,
			},
			product : {
				height: 80,
				padding: 8,
				marginBottom: 6,
				overflow: Hidden,
				alignItems:Center,
				justifyContent:SpaceEvenly,
			},
			iconStyle:{
				fontSize:12,
			},
			cover: {
				width: '70px',
				height: '70px',
				objectFit: "cover",
			},
			productBuy: {
                boxShadow: "none",
            },
			cagProductTitle: {
                fontSize: '0.8rem',
                fontStyle: "normal",
                textTransform: UpperCase,
                marginBottom: 3,
				overflow: Hidden,
				textOverflow: Ellipsis,
				lineHeight: "1.0em",
  				maxHeight: "1.8em",
				alignSelf: "flex-start",
            },
            cagProductInfoWrap : {       
                justifyContent: SpaceBetween,
                padding: "0 5px",
            },
            cagProductInfo : {
                fontSize : "1.0rem",
                "& .cagProductUnit" : {
                    marginRight: "2rem",
                },
                "& .cagProductPrice" : {
                    color : CGColors.Third,        
                },
            },
            cagProductPriceRate : {        
                fontSize: "0.5rem",
                color : CGColors.Secondfont,
                marginTop : -3,
                marginLeft: 3,
            },
		}
	}

    static function mapStateToProps(st:react.cagette.state.State, ownProps:PublicProps):react.Partial<Props> {
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
        return if(props.quantity == 0 ) {
            jsx(' <Button
                        onClick=${addToCart}
                        variant=${Contained}
                        color=${Primary} 
                        className=${props.classes.productBuy} 
                        disableRipple>                        
                        <i className="icon icon-truck"></i>
                    </Button>
            ');
        } else {
            jsx('<QuantityInput onChange=${updateQuantity} value=${props.quantity}/>');
        }
    }

    function renderProductPrices(product, productType) {
        var classes = props.classes;
        return jsx('
            <CardActions className=${classes.cagProductInfoWrap} style={{ marginBottom: 10}} >                                                      
                <Typography component="p" className=${classes.cagProductPriceRate} >                                 
                    ${product.price} €/${(productType)}
                </Typography>                               
            </CardActions>
        ');
    }

    function renderProductOrderActions(product, productType) {
        var classes = props.classes;
        return jsx('
            <CardActions className=${classes.cagProductInfoWrap} >                                    
                <Typography component="p" className=${classes.cagProductInfo} >                                 
                    <span className="cagProductUnit">1 ${(productType)} </span>
                    <span className="cagProductPrice">${product.price} €</span>                         
                </Typography>
                
                {renderQuantityAction()}
            </CardActions>
        ');
    }

    function getModalStyle() {
        var top = 50;
        var left = 50;
        return {
            top: '${top}%',
            left: '${left}%',
            transform: 'translate(-${top}%, -${left}%)',
        }
    }

    override public function render() {
        var classes = props.classes;
        var product = props.product;
        var productType = unit(product.unitType);

        var iconTruck = classNames({
			'icons':true,
			'icon-truck':true,
		});

        return jsx('
            <Modal open={true} onClose=${props.onClose}>
                <div style={getModalStyle()} className={classes.paper}>
                    <Grid direction=${Column} container={true} spacing={8}>
                        <Grid direction=${Row} container={true} spacing={0}>
                            <Grid item={true} xs={4} direction=${Column} container={true} spacing={0}>
                                <Grid item className=${classes.gridItem}>
                                    <Card className=${classes.subcard} elevation={0}>
                                        <CardMedia className=${classes.cover} image=${product.image}
                                        />
                                    </Card>
                                </Grid>

                                <Grid item={true} className=${classes.gridItem}>
                                    <Typography component="p" className=${classes.cagProductInfo} >
                                        <span className="cagProductUnit">1${(productType)}</span>	
                                    </Typography>
                                    <Typography component="p" className=${classes.cagProductInfo} >
                                        <span className="cagProductPrice">${product.price} €</span>
                                    </Typography>
                                </Grid>
                            </Grid>

                            <Grid item={true} xs={8} className=${classes.gridItem}>
                                <Typography component="h3" className=${classes.cagProductTitle}>
                                    ${product.name}
                                </Typography>
                                    <Typography component="p" className=${classes.cagProductPriceRate} >
                                    ${product.price} €/${(productType)}
                                </Typography>

                                <QuantityInput onChange=${updateQuantity} value={1} />
                            </Grid>
                        </Grid>
                    </Grid>
                </div>
            </Modal>
        ');
    }
}
