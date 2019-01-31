package react.store;

import Common;
import react.PureComponent;
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

typedef ProductCatalogCategoriesProps = {
	> PublicProps,
};

private typedef PublicProps = {
	var categories:Array<CategoryInfo>;
	var catalog:FilteredProductCatalog;
	var vendors : Array<VendorInfo>;
	var openModal : ProductInfo->VendorInfo->Void;
}

@:publicProps(PublicProps)
class ProductCatalogCategories extends PureComponentOfProps<ProductCatalogCategoriesProps> {

	function new(p) {
		super(p);
	}

	override public function render() {
		var categories = [
			for( category in props.categories ) { 
				if( props.catalog.category == null ||
					props.catalog.category == category.id )
					jsx('<$ProductListCategory key=${category.name} catalog=${props.catalog} category=${category} openModal=${props.openModal} vendors=${props.vendors} />');
			}
		];
		return jsx('
			<>
				${categories}
			</>
		');
	}
}
