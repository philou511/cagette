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

typedef HeaderCategoriesProps = {
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
    cagNavHeaderCategories,
    cagCategoryActive,
    cagWrap,
]>

private typedef HeaderCategoriesState = {
    activeCategory : CategoryInfo,
    activeSubCategory : CategoryInfo,
}

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class HeaderCategories extends react.ReactComponentOfPropsAndState<HeaderCategoriesProps,HeaderCategoriesState> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            cagWrap: {
				maxWidth: 1240,
                margin : "auto",
                padding: "0 10px",
			},
            cagNavHeaderCategories : {
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
        this.state = {activeCategory:null, activeSubCategory:null};
	}

    override function componentDidMount() {
        //default category is "all products"
        setState({activeCategory:props.categories[0], activeSubCategory:null});
    }

    function onSubCategoryClicked(subcategory:CategoryInfo) {
        setState({activeSubCategory:subcategory}, function() {
            applyFilter();
        });
    }

    function applyFilter() {
        if( state.activeCategory == null ) return;

        if( state.activeCategory.id == 0 )
            props.resetFilter();
        else if( state.activeSubCategory == null  )
            props.filterByCategory(state.activeCategory.id);
        else
            props.filterBySubCategory(state.activeCategory.id, state.activeSubCategory.id);
    }

    function onCategoryClicked(category:CategoryInfo) {
        if( category == state.activeCategory ) {
            setState({activeSubCategory:null}, function() {
                applyFilter();
            });
        } else {
            setState({activeCategory:category}, function(){
                applyFilter();
            });
        }
        //resetFilter=${props.resetFilter}
        //filterByCategory=${props.filterByCategory}
        //filterBySubCategory=${props.filterBySubCategory}
        //toggleFilterTag=${props.toggleFilterTag}
    }

	override public function render() {
        var classes = props.classes;
        var categories = [
            for(category in props.categories)
                jsx('<HeaderCategoryButton
                                key=${category.id} 
                                active=${category == state.activeCategory}
                                category=${category} 
                                onClick=${onCategoryClicked.bind(category)}
                />')
        ];

        return jsx('
            <div className=${classes.cagNavHeaderCategories}>
                <div className=${classes.cagWrap}>
                    <Grid container spacing={0}>
                        ${categories}
                    </Grid>
                </div>
                <HeaderSubCategories category=${state.activeCategory} subcategory=${state.activeSubCategory} onClick=${onSubCategoryClicked} />
            </div>
        ');
    }
}
