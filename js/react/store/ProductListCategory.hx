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
import mui.core.Typography;
import js.html.Event;
import mui.core.modal.ModalCloseReason;

using Lambda;

typedef ProductListCategoryProps = {
	> PublicProps,
};

private typedef PublicProps = {
	var category:CategoryInfo;
	var catalog:FilteredProductCatalog;
	var openModal : ProductInfo->VendorInfo->Void;
	var vendors : Array<VendorInfo>;
}

@:publicProps(PublicProps)
class ProductListCategory extends react.ReactComponentOfProps<ProductListCategoryProps> {

	function new(p) {
		super(p);
	}

	override public function render() {
		var category = props.category;
		var shouldDisplayCategoryName = props.catalog.category != null && props.catalog.subCategory == null
									|| props.catalog.category == null && props.catalog.subCategory == null;
		
		if( shouldDisplayCategoryName ) {
			//TODO Should be done by server ideally
			var hasProducts = Lambda.exists(props.catalog.products, function(p) {
				return Lambda.has(p.categories, category.id);
			});

			if( !hasProducts && category.subcategories != null ) {
				for( subcategory in category.subcategories ) {
					hasProducts = Lambda.exists(props.catalog.products, function(p) {
						return Lambda.has(p.subcategories, subcategory.id);
					});
					if( hasProducts ) break;
				}
			}

			if( !hasProducts ) {
				shouldDisplayCategoryName = false;
			}
		}

		var categoryName =  if(shouldDisplayCategoryName) jsx('<h2>${category.name}</h2>')
							else null;
		
		return jsx('
			<div className="category" key=${category.name}>
				{categoryName}
				<div className="subCategories">
					${renderSubCategories(category)}
				</div>
			</div>
		');
	}

	function renderSubCategories(category:CategoryInfo) {
		if( category.subcategories == null || category.subcategories.length == 0 ) 
			return null;
		
		var list = category.subcategories.map(function(subcategory) {
			var subProducts = props.catalog.products.filter(function(p) {
				return Lambda.has(p.subcategories, subcategory.id);
			});
			
			if( subProducts.length == 0 ) return null;

			return jsx('
				<ProductListSubCategory key=${subcategory.id} subcategory=${subcategory} products=${subProducts} vendors={props.vendors} openModal=${props.openModal}  />
			');
		});

		while(list.remove(null)){}

		var content = list.length == 0 ? jsx('
					<Typography component="h4" align={Center}>
						Il n\'y a aucun produit dans cette catégorie ${category.name}
					</Typography>
		') : jsx('<>${list}</>');

		return content;
	}
}
