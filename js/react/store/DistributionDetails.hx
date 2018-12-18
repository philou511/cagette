package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.Typography;
import mui.core.FormControl;
import mui.icon.Icon;
import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import Common;

using Lambda;

typedef DistributionDetailsProps = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
	var displayLinks:Bool;
}

private typedef TClasses = Classes<[cagNavInfo,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class DistributionDetails extends react.ReactComponentOfProps<DistributionDetailsProps> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			cagNavInfo : {
                fontSize: "0.7rem",
				fontWeight: "lighter",
                color: CGColors.Secondfont,
                padding: "10px 0",
                
                "& p" : {
                    margin: "0 0 0.2rem 0",// !important  hum...
                },

                "& a" : {
                    color : CGColors.Firstfont, // !important   hum....
                },

                "& i" : {
                    color : CGColors.Firstfont,
                    fontSize: "0.6em",
                    verticalAlign: "middle",//TODO replace later with proper externs enum
                    marginRight: "0.2rem",
                },
            },
		}
	}

	public function new(props) {
		super(props);
	}

	override public function render() {
		var classes = props.classes;
		var clIconMap = classNames({
			'icons':true,
			'icon-map-marker':true,
		});
		var clIconEuro = classNames({
			'icons':true,
			'icon-cash':true,
		});
		var clIconDate = classNames({
			'icons':true,
			'icon-calendar':true,
		});

		//TODO localization
        var textInfos1Link = props.displayLinks ? jsx('<a href="#">Changer</a>') : null;
        var textInfos3Link = props.displayLinks ? jsx('<a href="#">Plus d\'infos></a>') : null;

        var textInfos1 = jsx('120 rue Fondaudège, Bordeaux.');
        var textInfos2 = jsx('Distribution le vendredi 29 juin entre 18h et 20h. Commandez jusqu\'au 27 juin.');
        var textInfos3 = jsx('Paiement: CB, chèque ou espèces.');
		
		return jsx('
            <div className=${classes.cagNavInfo}> 
				<Typography component="p">
					<Icon component="i" className=${clIconMap}></Icon>
					${textInfos1} ${textInfos1Link}
				</Typography>
				<Typography component="p">
					<Icon component="i" className=${clIconDate}></Icon>
					${textInfos2}
				</Typography>
				<Typography component="p">
					<Icon component="i" className=${clIconEuro}></Icon>
					${textInfos3} ${textInfos3Link}
				</Typography>                     
			</div>
        ');
	}
}
