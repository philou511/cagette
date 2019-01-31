package react.store;

import js.html.Event;
import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import classnames.ClassNames.fastNull as classNames;
import react.store.types.FilteredProductCatalog;
import mui.core.styles.Classes;
import mui.core.Grid;
import mui.core.styles.Styles;
import mui.core.Modal;
import mui.core.Button;
import mui.icon.ExpandMore;
import mui.core.modal.ModalCloseReason;
import mui.core.Typography;
import css.TextAlign;

using Lambda;

typedef ProductListSubCategoryProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
	@:optional var displayAll:Bool;
	var subcategory:CategoryInfo;
	var products:Array<ProductInfo>;
	var openModal : ProductInfo->VendorInfo->Void;
	var vendors : Array<VendorInfo>;
}

typedef ProductListSubCategoryState = {
	var displayAll:Bool;
}

private typedef TClasses = Classes<[
    subCategory,
	button,
]>


@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class ProductListSubCategory extends react.ReactComponentOf<ProductListSubCategoryProps, ProductListSubCategoryState> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            subCategory: {
                textAlign: TextAlign.Left,
            },
			button: {
				width: '100%',
				textAlign: TextAlign.Center,
				marginBottom: 8,
			}
        }
	}

	function new(p) {
		super(p);
		this.state = {displayAll:false};
	}

	override function componentWillMount() {
		if( props.products.length <= LIMIT_TO_DISPLAY
			|| props.displayAll ) 
			setState({displayAll:true});
	}

	override public function render() {
		var classes = props.classes;
		var subcategory = props.subcategory;
		return jsx('
			<div className=${classes.subCategory} key=${subcategory.id}>
				<h3>${subcategory.name}</h3>
				<$Grid container style={{ marginBottom: 20}} spacing={Spacing_24}>
					${renderProducts(props.products)}
				</$Grid>
				<div className=${classes.button}>
					${renderLoadMoreButton()}
				</div>
			</div>
		');
	}

	function toggleDisplayAll() {
		setState({displayAll:true});
	}

	function renderLoadMoreButton() {
		if( state.displayAll ) return null;
		return jsx('
			<Button variant={Contained} color={Primary} onClick=${toggleDisplayAll}>
				<ExpandMore /> Afficher plus de produits
			</Button>
		');
	}

	public static var LIMIT_TO_DISPLAY = 8;
	
	function renderProducts(products:Array<ProductInfo>) {
		var numberToDisplay = state.displayAll ? products.length : LIMIT_TO_DISPLAY;

		return [ for( i in 0...numberToDisplay ) {
				var product = products[i];
				if( product == null ) continue;
				//get the vendor
				// should be optimized..
				var vendor = Lambda.find(this.props.vendors,function(v){
					return v.id == product.vendorId;
				});

				jsx('
					<$Grid item xs={12} sm={4} md={3} key=${product.id}>
						<$Product product=${product} openModal=${props.openModal} vendor=${vendor} />
					</$Grid>
				');
			}
		];
	}
}
