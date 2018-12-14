package react.store;
// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.FormControl;
import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;

import Common;

using Lambda;

typedef CategoriesProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
    var categories:Array<CategoryInfo>;
	var resetFilter:Void->Void;
	var filterByCategory:Int->Void;
	var filterBySubCategory:Int->Int->Void;
	var toggleFilterTag:String->Void;
}

private typedef TClasses = Classes<[
    cagNavCategories,
    cagCategoryActive,
    cagWrap,
]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class Categories extends react.ReactComponentOfProps<CategoriesProps> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            cagWrap: {
				maxWidth: 1240,
                margin : "auto",
                padding: "0 10px",
			},
            cagNavCategories : {
                backgroundColor: CGColors.Bg2,
                textAlign: Center,
                textTransform: UpperCase,
                fontSize: "0.7rem",
                lineHeight: "0.9rem",
                "& .cagCategoryContainer" : {
                    height: 100,  
                    padding: "0 5",   
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    "& img" : {
                        display: "block",
                        margin: "0 auto 10px auto",
                    }
                },
                "& .cagCategoryContainer:hover" : {
                    backgroundColor: CGColors.Bg3,
                },
            },
            cagCategoryActive : {
                backgroundColor: CGColors.Bg3,
            },
        }
    }

    public function new(props) {
		super(props);
	}

    function onCategoryClicked(category:CategoryInfo) {
        if( category.id > 0 )
            props.filterByCategory(category.id);
        else if( category.id == 0 )
            props.resetFilter();

        //resetFilter=${props.resetFilter}
        //filterByCategory=${props.filterByCategory}
        //filterBySubCategory=${props.filterBySubCategory}
        //toggleFilterTag=${props.toggleFilterTag}
    }

	override public function render() {
        var classes = props.classes;
        var CategoryContainerClasses = classNames({
			'cagCategoryContainer': true,
            '${classes.cagCategoryActive}': true,//make this dynamic
		});
        //TODO active
        var categories = [
            for(category in props.categories)
                jsx('<Category  key=${category.id} 
                                active=${false}
                                category=${category} 
                                onClick=${onCategoryClicked.bind(category)}
                />')
        ];
        return jsx('
            <div className=${classes.cagNavCategories}>
                <div className=${classes.cagWrap}>
                    <Grid container spacing={0}>
                        ${categories}
                    </Grid>
                </div>
            </div>
        ');
    }
}
