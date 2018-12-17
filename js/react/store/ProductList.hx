package react.store;

import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.Grid;

import react.store.types.FilteredProductList;

using Lambda;

typedef ProductListProps = {
	var categories:Array<CategoryInfo>;
	var products:FilteredProductList;
};

class ProductList extends react.ReactComponentOfProps<ProductListProps> {
	override public function render() {
		return jsx('
			<div className="categories">
			  ${renderCategories()}
			</div>
    	');
	}

	function renderCategories() {
		return props.categories.map(function(category) {
			//if (!props.filters.has(category.name))
			//	return null;
			
			var shouldDisplayCategory = props.products.category != null && props.products.subCategory == null
										|| props.products.category == null && props.products.subCategory == null;

			//TODO Should be done by server ideally
			if( shouldDisplayCategory ) {
				var hasProducts = false;
				hasProducts = Lambda.exists(props.products.products, function(p) {
					return Lambda.has(p.categories, category.id);
				});

				if( !hasProducts && category.subcategories != null ) {
					for( subcategory in category.subcategories ) {
						hasProducts = Lambda.exists(props.products.products, function(p) {
							return Lambda.has(p.subcategories, subcategory.id);
						});
						if( hasProducts ) break;
					}
				}

				if( !hasProducts ) shouldDisplayCategory = false;
			}

			var categoryName =  if(shouldDisplayCategory) jsx('<h2>${category.name}</h2>')
								else null;
			
			return jsx('
				<div className="category" key=${category.name}>
					{categoryName}
					<div className="subCategories">
						${renderSubCategories(category)}
					</div>
				</div>
			');
		});
	}

	function renderSubCategories(category:CategoryInfo) {
		if( category.subcategories == null || category.subcategories.length == 0 ) 
			return null;
		//
		var list = category.subcategories.map(function(subcategory) {
			var subProducts = props.products.products.filter(function(p) {
				return Lambda.has(p.subcategories, subcategory.id);
			});
			
			if( subProducts.length == 0 ) return null;
			
			return jsx('
				<div className="subCategory" key=${subcategory.id}>
					<h3>${subcategory.name}</h3>
					<div className="products">
						<$Grid container style={{ marginBottom: 20}}  spacing={Spacing_24}>
							${renderProducts(subProducts)}
						</$Grid>
					</div>
				</div>
			');
		});

		return jsx('
			<>
				$list
			</>
		');
	}

	function renderProducts(products:Array<ProductInfo>) {
		if (products == null || products.length == 0)
			return null;
		
		return products.map(function(product) {
			return jsx('
				<$Grid item xs={12} sm={4} md={3} key=${product.id}>
					<$Product product=${product} />
				</$Grid>
			');
		});
	}
}
