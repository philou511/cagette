
package react.store;


// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import mui.CagetteTheme.CGColors;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import react.types.css.JustifyContent;
import react.types.css.AlignContent;

private typedef Props = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
}

private typedef TClasses = Classes<[
    quantityInput,
]>

@:acceptsMoreProps
@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class QuantityInput extends ReactComponentOfProps<Props> {
    
    public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            quantityInput : {
                border: '1px solid ${CGColors.Second}',
                borderRadius: 3,
                display: "flex",
                maxWidth: 104,
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
                    minWidth: 35,
                    textAlign: Center,
                    verticalAlign: "middle",
                    color: CGColors.Second,
                    backgroundColor: "#fff",
                },
            },
		}
	}

    override function render() {
        var classes = props.classes;
        return jsx('
            <div className=${classes.quantityInput}>
                <div className="quantityMoreLess"> - </div>
                <div className="quantity"> 1 </div>
                <div className="quantityMoreLess"> + </div>
            </div>
        ');
    }
}

