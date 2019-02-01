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
    var isSticky:Bool;
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
    shadow,
    cagSticky, 
    cagGridHeight, cagGridHeightSticky, cagGrid,
]>

private typedef HeaderCategoriesState = {
    activeCategory : CategoryInfo,
    activeSubCategory : CategoryInfo,
}

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class HeaderCategories extends react.ReactComponentOfPropsAndState<HeaderCategoriesProps, HeaderCategoriesState> {
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
            },
            cagSticky : {
                maxWidth: 1240,
                margin : "auto",
            },
            cagCategoryActive : {
                backgroundColor: CGColors.Bg3,
            },
            shadow : {
                filter: "drop-shadow(0px 4px 1px #00000055)",
            },
            cagGrid: {
                
            },
            cagGridHeight: {
                height: "9em", 
            },
            cagGridHeightSticky: {
                height: "5em",
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
        js.Browser.window.scrollTo({ top: 0, behavior: 'smooth' });
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

        js.Browser.window.scrollTo({ top: 0, behavior: 'smooth' });
        
        if( category == state.activeCategory ) {
            setState({activeSubCategory:null}, function() {
                applyFilter();
            });
        } else {
            setState({activeCategory:category, activeSubCategory:null}, function(){
                applyFilter();
            });
        }

        // pour le bio et le label rouge..
        // Attention : vérifier l'implémentation du filtre qui n'a pas du être faite !
        //toggleFilterTag=${props.toggleFilterTag}
    }

	override public function render() {
        var classes = props.classes;
        var headerClasses = classNames({
			'${classes.cagNavHeaderCategories}': true,
            '${classes.cagSticky}': props.isSticky,
            '${classes.shadow}': props.isSticky,
		});

        var categoryGridClasses = classNames({
            '${classes.cagGrid}': true,
            '${classes.cagGridHeight}': !props.isSticky,
            '${classes.cagGridHeightSticky}': props.isSticky,
        });

        var categories = [
            for(category in props.categories)
                jsx('<HeaderCategoryButton
                                key=${category.id} 
                                isSticky=${props.isSticky}
                                active=${category == state.activeCategory}
                                category=${category} 
                                onClick=${onCategoryClicked.bind(category)}
                />')
        ];
        
        return jsx('
            <div className=${headerClasses}>
                <div className=${classes.cagWrap}>
                    <Grid container spacing={0} className=${categoryGridClasses}>
                        ${categories}
                    </Grid>
                    <HeaderSubCategories category=${state.activeCategory} subcategory=${state.activeSubCategory} onClick=${onSubCategoryClicked} />
                </div>
            </div>
        ');
    }
}
