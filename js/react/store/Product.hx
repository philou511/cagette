package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import mui.CagetteTheme.CGColors;
import mui.core.Button;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import react.types.css.JustifyContent;
import react.types.css.AlignContent;

import mui.core.Card;
import mui.core.Button;
import mui.core.CardMedia;
import mui.core.CardContent;
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Typography;
import mui.core.Avatar;

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
                lineHeight: "normal",
                fontSize: '1.08rem',
                fontStyle: "normal",
                fontWeight: 400,
                textTransform: UpperCase,
                marginBottom: 3,
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
    override public function render() {

        var classes = props.classes;
        var CardMediaClasses = classNames({
			'${classes.media}': true,
		});

        return jsx('
            <Card elevation={0} className=${classes.card}> 
                <CardActionArea>
                    <CardMedia
                        className=${CardMediaClasses}                                    
                        image="/img/produit-oranges2.jpg"               
                        >
                        <div className=${classes.cagAvatarContainer}>
                            <Avatar className=${classes.starProduct}>
                                <i className="icon icon-truck-solid"></i>
                            </Avatar>  
                        </div>
                        <div className=${classes.cagAvatarContainer}>
                                <Avatar src="/img/la-ferme-des-2-rivieres.jpg" 
                                    className=${classes.farmerAvatar} 
                                />  
                        </div>                      
                    </CardMedia>
                    <CardContent className=${classes.cardContent}>                        
                        <Typography component="h3" className=${classes.cagProductTitle}>
                            Orange  Naveline de Catatania 
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
                        <span className="cagProductUnit">1 kg </span>
                        <span className="cagProductPrice">2,50 €</span>                         
                    </Typography>
                    
                    <QuantityInput/>

                    <Button
                        variant=${Contained}
                        color=${Primary} 
                        className=${classes.productBuy} 
                        disableRipple>                        
                        <i className="icon icon-truck-solid"></i>
                    </Button>
                </CardActions>   
                <CardActions className=${classes.cagProductInfoWrap} style={{ marginBottom: 10}} >                                                      
                    <Typography component="p" className=${classes.cagProductPriceRate} >                                 
                        2,50 €/kg
                    </Typography>                               
                </CardActions>
            </Card>
        ');
    }
}
