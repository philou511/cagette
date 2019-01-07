package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import css.JustifyContent;
import css.AlignContent;

import mui.core.Button;
import mui.core.Card;
import mui.core.CardMedia;
import mui.core.CardContent;
import mui.core.Modal;
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Typography;
import mui.core.Avatar;
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
    var openModal:ProductInfo->Void;
}

private typedef ReduxProps = {
	var updateCart:ProductInfo->Int->Void;
	var addToCart:ProductInfo->Void;
    var quantity:Int;
}

private typedef TClasses = Classes<[
	button,
    card,
    media,
    area,
    cardContent,
    productBuy,
    starProduct,
    farmerAvatar,
    cagAvatarContainer,
    cagProductTitle,
    cagProductDesc,
    cagProductInfoWrap,
    cagProductInfo,
    cagProductPriceRate,
    cagProductLabel,
]>

typedef ProductState = {
};

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
@:connect
class Product extends ReactComponentOf<Props, ProductState> {

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
            media: {       
                height: 170,
                padding: 1,
            },
            cardContent: {
                padding: 10,
                paddingBottom: 5,
            },
            productBuy: {
                boxShadow: "none",
            },
            starProduct: {
                width: 30,
                height: 30,
                color: '#F9D800',        
                backgroundColor: '#ffffff',
                marginLeft: "auto",
                fontSize: 16,
            },
            farmerAvatar: {       
                color: '#404040',   
                backgroundColor: '#ededed',
                border: "3 solid #ffffff",
                width: 70,
                height: 70,
                marginLeft: "auto",
                fontSize: 10,
            },
            cagAvatarContainer: {
                margin: "3%",
                height: "43%",
                display: "flex",
            },
            cagProductTitle: {
                fontSize: '1.08rem',
                lineHeight: "normal",
                fontStyle: "normal",
                textTransform: UpperCase,
                marginBottom: 3,
                fontWeight: 400,
                maxHeight: 40,
                overflow: Hidden,
            },
            cagProductLabel : {
                marginLeft : -3,
            },
            cagProductDesc: {
                fontSize: '0.9rem',
                color : CGColors.Secondfont,
                marginBottom : 0,
                maxHeight: 65,
                overflow: Hidden,
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
                fontSize: "0.75rem",
                color : CGColors.Secondfont,
                marginTop : -5,
                marginLeft: 5,
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
        this.state = {};
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
                        <i className="icon icon-basket-add"></i>
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

    function displayProductInfos(_) {
        props.openModal(props.product);
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
            <Card elevation={0} className=${classes.card}> 
                <CardActionArea className=${classes.area} onClick=${displayProductInfos}>
                    <CardMedia
                        className=${classes.media}
                        image=${product.image}
                        >
                        <div className=${classes.cagAvatarContainer}>
                            <Avatar className=${classes.starProduct}>
                                <Icon component="i" className=${iconTruck}></Icon>
                            </Avatar>  
                        </div>
                        <div className=${classes.cagAvatarContainer}>
                                <Avatar src="/img/store/vendor.jpg" 
                                        className=${classes.farmerAvatar} 
                                        />  
                        </div>
                    </CardMedia>

                    <CardContent className=${classes.cardContent}>                        
                        <Typography component="h3" className=${classes.cagProductTitle}>
                            ${product.name}
                        </Typography>
                        <Typography component="p" className=${classes.cagProductDesc}>
                            La Ferme 
                        </Typography>
                        <Typography component="p" className=${classes.cagProductLabel}>
                            <$SubCateg label="Label rouge" icon="icon icon-truck" colorClass="cagLabelRouge" />
                            <$SubCateg label="Bio" icon="icon icon-truck" colorClass="cagBio"  />
                        </Typography>
                    </CardContent>           
                </CardActionArea>

                ${renderProductOrderActions(product, productType)}

                ${renderProductPrices(product, productType)}
            </Card>
        ');
    }
}
