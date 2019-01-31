package react.store;

import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.Grid;
import classnames.ClassNames.fastNull as classNames;
import mui.core.styles.Classes;
import react.store.types.FilteredProductCatalog;
import mui.core.styles.Styles;
import mui.core.Modal;
import js.html.Event;
import mui.core.modal.ModalCloseReason;

using Lambda;

typedef ProductCatalogProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
	var categories:Array<CategoryInfo>;
	var catalog:FilteredProductCatalog;
	var vendors : Array<VendorInfo>;
}

private typedef ProductCatalogState = {
	@:optional var modalProduct:Null<ProductInfo>;
	@:optional var modalVendor:Null<VendorInfo>;
}

private typedef TClasses = Classes<[categories,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class ProductCatalog extends ReactComponentOf<ProductCatalogProps, ProductCatalogState> {

	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			categories : {
                maxWidth: 1240,
                margin : "auto",
                padding: "0 10px",
            },
		}
	}

	function new(p) {
		super(p);
		this.state = {};
	}

	override public function render() {
		var classes = props.classes;
		trace('filter catalog', props.catalog.products.length, props.catalog.category);
		return jsx('
			<div className=${classes.categories}>
			   <ProductModal 	product=${state.modalProduct}
								vendor=${state.modalVendor}
								onClose=${onModalCloseRequest} />
			  <ProductCatalogCategories categories=${props.categories} catalog=${props.catalog} vendors=${props.vendors} openModal=${openModal} />
			</div>
    	');
	}

	function openModal(product:ProductInfo, vendor:VendorInfo) {
        setState({modalProduct:product, modalVendor:vendor}, function() {trace("modal opened");});
    }

    function onModalCloseRequest(event:js.html.Event, reason:ModalCloseReason) {
        setState({modalProduct:null, modalVendor:null}, function() {trace("modal closed");});
    }

}
