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
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Typography;
import mui.core.Avatar;
import mui.core.styles.Classes;
import mui.core.styles.Styles;

import mui.CagetteTheme;
import Formatting.unit;
import Common;

private typedef Props = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    var product:ProductInfo;
    var addToCart:ProductInfo -> Int -> Void;
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
  var quantity:Int;
};

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
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
                "& .labelChip:hover" : {        
                    backgroundColor: CGColors.White,
                },
                "& .labelChip" : {
                    fontSize: "0.7rem",
                    margin: "5px 2px",
                    padding: "0 5px",
                },
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

    public function new(props) {
        super(props);
        this.state = { quantity : 0 };
    }

    static inline var OVERLAY_URL = '/shop/productInfo';
    function openOverlay(_) {
        untyped window._.overlay('$OVERLAY_URL/${props.product.id}', props.product.name);
    }

    function updateQuantity(quantity) {
        setState({
            quantity: Std.int(quantity)
        });
    }

    function addToCart() {
        setState({quantity:1}, function() {
            props.addToCart(props.product, state.quantity);
        });
    }

    function renderQuantityAction() {
        return if(state.quantity == 0 ) {
            jsx(' <Button
                        onClick=${addToCart}
                        variant=${Contained}
                        color=${Primary} 
                        className=${props.classes.productBuy} 
                        disableRipple>                        
                        <i className="icon icon-truck-solid"></i>
                    </Button>
            ');
        } else {
            jsx('<QuantityInput onChange=${updateQuantity} defaultValue={1}/>');
        }
    }
    override public function render() {
        var classes = props.classes;
        var product = props.product;
        var productType = unit(product.unitType);

        return jsx('
            <Card elevation={0} className=${classes.card}> 
                <CardActionArea className=${classes.area} onClick=${openOverlay}>
                    <CardMedia
                        className=${classes.media}
                        image=${product.image}
                        >
                        <div className=${classes.cagAvatarContainer}>
                            <Avatar className=${classes.starProduct}>
                                <i className="icon icon-truck-solid"></i>
                            </Avatar>  
                        </div>
                        <div className=${classes.cagAvatarContainer}>
                                <Avatar src="/img/store/la-ferme-des-2-rivieres.jpg" 
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
                            <$SubCateg label="Label rouge" icon="icon icon-truck-solid" colorClass="cagLabelRouge" />
                            <$SubCateg label="Bio" icon="icon icon-truck-solid" colorClass="cagBio"  />
                        </Typography>
                    </CardContent>           
                </CardActionArea>
                <CardActions className=${classes.cagProductInfoWrap} >                                    
                    <Typography component="p" className=${classes.cagProductInfo} >                                 
                        <span className="cagProductUnit">1 ${(productType)} </span>
                        <span className="cagProductPrice">${product.price} €</span>                         
                    </Typography>
                    
                   {renderQuantityAction()}

                </CardActions>   
                <CardActions className=${classes.cagProductInfoWrap} style={{ marginBottom: 10}} >                                                      
                    <Typography component="p" className=${classes.cagProductPriceRate} >                                 
                        ${product.price} €/${(productType)}
                    </Typography>                               
                </CardActions>
            </Card>
        ');
    }
}
