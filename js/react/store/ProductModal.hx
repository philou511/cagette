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

import Common;

private typedef Props = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    var product:ProductInfo;
    var onClose:js.html.Event->ModalCloseReason->Void;
}


private typedef TClasses = Classes<[
	gridItem,
	modal, 
	cartFooter,
	products, 
	product, 
	iconStyle, 
	subcard, 
	cover,
	cagProductTitle,
    cagProductInfoWrap,
    cagProductInfo,
]>


@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))

class ProductModal extends ReactComponentOfProps<Props> {
    public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			modal : {
                //display: "flex",
				//justifyContent: Center,
				//alignItems: Center,
                position:css.Position.Absolute,
                width:"80%",
                backgroundColor: CGColors.White,
                padding:"24px",
                outline:"none"
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
				maxWidth: '300px',
				//maxHeight: '300px',
				//objectFit: "cover",
			},
		
			cagProductTitle: {
                fontSize: '1.4rem',
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
 
		}
	}
    
    public function new(props) {
        super(props);
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

        return jsx('
            <Modal open={true} onClose=${props.onClose}>
                <div style=${getModalStyle()} className=${classes.modal}>
                    
                    <Grid container spacing={24}>

                        <Grid item xs={4} className=${classes.gridItem}>
                            <div className=${classes.subcard}>
                                <img className=${classes.cover} src=${product.image}/>
                            </div>
                        </Grid>

                        <Grid item xs={8}  className=${classes.gridItem}>

                            <Typography component="h3" className=${classes.cagProductTitle}>
                                ${product.name}
                            </Typography>

                            <Typography component="p" dangerouslySetInnerHTML={{ __html: ${product.desc} }}></Typography>

                            <$ProductActions product=$product />                            
                        </Grid>
                    </Grid>

                    <Grid container>
                        Vendor Infos
                    </Grid>
                   
                </div>
            </Modal>
        ');
    }
}
