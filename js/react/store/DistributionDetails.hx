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
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import Common;
import Formatting;

using Lambda;

typedef DistributionDetailsProps = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
	var sticky:Bool;
	var displayLinks:Bool;
	var place:PlaceInfos;
	var orderByEndDates:Array<OrderByEndDate>;
	var paymentInfos:String;
	var date : Date;
}

private typedef TClasses = Classes<[cagNavInfo,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class DistributionDetails extends react.ReactComponentOfPropsAndState<DistributionDetailsProps,{placePopup:PlaceInfos}> {
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
		this.state = {placePopup:null};
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
		var clIconClock = classNames({
			'icons':true,
			'icon-clock':true,
		});

		if (props.orderByEndDates == null || props.orderByEndDates.length == 0)
			return null;

		

		// TODO Think about the way the place adress is built, why an array for zipCode and city ?
		// TODO LOCALIZATION
		var viewUrl = '${CagetteStore.ServerUrl.ViewUrl}/${props.place}';
		
		
        /*var textInfos1Link = props.displayLinks ? jsx('<a href="#">Changer</a>') : null;
        var textInfos3Link = props.displayLinks ? jsx('<a href="#">Plus d\'infos></a>') : null;*/
		return jsx('
            <div className=${classes.cagNavInfo}> 
				${renderMap()}
				${renderCalendar()}
				${renderClock()}
				${renderPaymentInfos()}
			</div>
        ');
	}

	function renderMap() {
		if( props.sticky ) return null;

		var addressBlock = props.place.name;
		var p = props.place;
		if(p.address1!=null) addressBlock+=", "+p.address1;
		if(p.address2!=null) addressBlock+=", "+p.address2;
		if(p.zipCode!=null) addressBlock+=", "+p.zipCode;
		if(p.city!=null) addressBlock+=" "+p.city;

		return jsx('
			<Typography component="p">
				${mui.CagetteIcon.get("map-marker")}
				${addressBlock}
			</Typography>'
		);
	}

	function renderCalendar() {
		var distribDate = jsx('<span>Distribution le ${Formatting.hDate(props.date)}.</span>');
		return jsx('
			<Typography component="p">
				${mui.CagetteIcon.get("calendar")}
				${distribDate}
			</Typography>'
		);
	}

	function renderClock() {
		var endDates;
		if (props.orderByEndDates.length == 1) {
			var orderEndDate = Date.fromString(props.orderByEndDates[0].date);
			endDates = [jsx('<span key=$orderEndDate>La commande fermera le ${Formatting.hDate(orderEndDate)}</span>')];
		} else {
			endDates = props.orderByEndDates.map(function(order) {
				if (order.contracts.length == 1) {
					return jsx('
						<span key=${order.date}>
							La commande ${order.contracts[0]} fermera le ${Formatting.hDate(Date.fromString(order.date))} 
						</span>
					');
				}

				return jsx('
					<span key=${order.date}>
						Les autres commandes fermeront le ${Formatting.hDate(Date.fromString(order.date))} 
					</span>
				');
			});
		}

		return jsx('
			<Typography component="p">
				${mui.CagetteIcon.get("clock")}
				${endDates}
			</Typography>'
		);
	}

	function renderPaymentInfos() {
		if( props.sticky ) return null;

		var paymentInfos = jsx('<span>Paiement: ${props.paymentInfos}</span>');
		return jsx('
<<<<<<< HEAD
            <div className=${classes.cagNavInfo}> 
				<Typography component="p" onClick=$openMapWindow style=${{cursor:"pointer"}}>
					${mui.CagetteIcon.get("map-marker")}
					${addressBlock}
				</Typography>
				<Typography component="p">
					${mui.CagetteIcon.get("calendar")}
					${distribDate}
				</Typography>
				<Typography component="p">
					${mui.CagetteIcon.get("clock")}
					${endDates}
				</Typography>
				<Typography component="p">
					${mui.CagetteIcon.get("cash")}
					${paymentInfos}
				</Typography>   

				${state.placePopup!=null?jsx('<OSMWindow place=${state.placePopup} onClose=$onOSMWindowClose  />'):null}                  
			</div>
        ');
	}

	function onOSMWindowClose(_,_){
		setState({placePopup:null});
	}

	function openMapWindow(_){
		setState({placePopup:props.place});
	}
=======
			<Typography component="p">
				${mui.CagetteIcon.get("cash")}
				${paymentInfos}
			</Typography>
		');
	}

>>>>>>> 5e698a1d6226045c0273d77f7a388a6154ce8f2c
}
