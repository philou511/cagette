
package react.store;

// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import mui.CagetteTheme.CGColors;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import mui.core.Button;
import css.JustifyContent;
import css.AlignContent;
import mui.core.Grid;

private typedef Props = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    var onChange:Int->Void;
    var value:Int;
}

private typedef TClasses = Classes<[
    quantityInput,
]>


typedef State = {
    //var quantity:Int;
};


@:acceptsMoreProps
@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class QuantityInput extends ReactComponentOf<Props, State> {
    
    public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            quantityInput : {
                border: '1px solid ${CGColors.Second}',
                borderRadius: 3,
                display: "flex",
               // maxWidth: 104,
                "& div" : {
                    flexGrow: 1,
                },
                "& .quantityMoreLess" : {
                    backgroundColor : CGColors.Second,
                    padding: 8,
                    color : "#ffffff",
                    fontSize: "2rem",
                    lineHeight: "1rem",
                    cursor: "pointer",
                    textAlign: Center,
                    transition: "all 0.5s ease",
                    "&::hover" : {
                        backgroundColor: "#a53fa1",//untyped color("#a53fa1").darken(10),            
                    },
                },
                "& .quantity" : {
                    fontSize: "1.2rem",
                    lineHeight: "2rem",
                    textAlign: Center,
                    verticalAlign: "middle",
                    color: CGColors.Second,
                    backgroundColor: "#fff",
                },
            },
		}
	}

    public function new(props) {
        super(props);
       // state = {quantity : props.defaultValue};
    }

    function updateValue(delta:Int) {
        var v = props.value + delta;
        if( v + delta < 0 ) v = 0;
        //setState({quantity:v}, function() {
            props.onChange(v);
        //});
    }

    override function render() {
        var classes = props.classes;
        return jsx('
        <Grid className=${classes.quantityInput} container={true} direction=${Row}>
            <Grid item={true} xs={4} className="quantityMoreLess">
                <div onClick=${updateValue.bind(-1)}>-</div>
            </Grid>
            <Grid item={true} xs={4} className="quantity">
                <div> ${props.value} </div>
             </Grid>
            <Grid item={true} xs={4} className="quantityMoreLess">
                <div onClick=${updateValue.bind(1)}>+</div>
            </Grid>
         </Grid>
        ');
    }
}

