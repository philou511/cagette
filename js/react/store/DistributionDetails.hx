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
	var place:PlaceInfos;
	var orderByEndDates:Array<OrderByEndDate>;
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
                    fontSize: "1em",
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
		//icons
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

		if (props.orderByEndDates == null || props.orderByEndDates.length == 0)
			return null;

		var endDates;
		// TODO Localization here
		if (props.orderByEndDates.length == 1) {
			var orderEndDate = props.orderByEndDates[0].date;
			endDates = [jsx('<div key=$orderEndDate>La commande fermera le $orderEndDate</div>')];
		} else {
			endDates = props.orderByEndDates.map(function(order) {
				if (order.contracts.length == 1) {
					return jsx('
						<div key=${order.date}>
							La commande ${order.contracts[0]} fermera le: ${order.date} 
						</div>
					');
				}

				return jsx('
					<div key=${order.date}>
						Les autres commandes fermeront: ${order.date} 
					</div>
				');
			});
		}

		// TODO Think about the way the place adress is built, why an array for zipCode and city ?
		// TODO LOCALIZATION
		var viewUrl = '${CagetteStore.ServerUrl.ViewUrl}/${props.place}';
		
		var addressBlock = props.place.name;
		var p = props.place;
		if(p.address1!=null) addressBlock+=", "+p.address1;
		if(p.address2!=null) addressBlock+=", "+p.address2;
		if(p.zipCode!=null) addressBlock+=", "+p.zipCode;
		if(p.city!=null) addressBlock+=" "+p.city;


		//TODO localization
        var textInfos1Link = props.displayLinks ? jsx('<a href="#">Changer</a>') : null;
        var textInfos3Link = props.displayLinks ? jsx('<a href="#">Plus d\'infos></a>') : null;

        var textInfos1 = jsx('$addressBlock');
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
