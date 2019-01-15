package react.store;

import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.Grid;
import classnames.ClassNames.fastNull as classNames;
import mui.core.styles.Classes;
import react.store.types.FilteredProductList;
import mui.core.styles.Styles;
import mui.core.Modal;
import js.html.Event;
import mui.core.modal.ModalCloseReason;

using Lambda;

typedef ProductListProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
	var categories:Array<CategoryInfo>;
	var products:FilteredProductList;
	var vendors : Array<VendorInfo>;
}

private typedef ProductListState = {
	var modalOpened:Bool;
	var modalProduct:Null<ProductInfo>;
}

private typedef TClasses = Classes<[categories,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class ProductList extends react.ReactComponentOf<ProductListProps, ProductListState> {

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
		this.state = {modalOpened:false, modalProduct:null};
	}

	override public function render() {
		var classes = props.classes;
		return jsx('
			<div className=${classes.categories}>
			  ${renderCategories()}
			  ${renderModal()}
			</div>
    	');
	}

	function openModal(product:ProductInfo,vendor:VendorInfo) {
        setState({modalOpened:true, modalProduct:product}, function() {trace("modal opened");});
    }

    function onModalCloseRequest(event:js.html.Event, reason:ModalCloseReason) {
		trace("ask for closing "+reason);
        setState({modalOpened:false}, function() {trace("modal closed");});
    }

    function renderModal() {
		if( state.modalOpened == false ) return null;
		
		var vendor = Lambda.find(this.props.vendors,function(v){
				return v.id==state.modalProduct.vendorId;
			});

        return jsx('
            <ProductModal 
				product=${state.modalProduct}
				vendor=${vendor}
				onClose=${onModalCloseRequest} 
				/>
        ');
    }

	function renderCategories() {
		return props.categories.map(function(category) {

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
			var vendor = Lambda.find(this.props.vendors,function(v){
				return v.id==product.vendorId;
			});

			return jsx('
				<$Grid item xs={12} sm={4} md={3} key=${product.id}>
					<$Product product=${product} openModal=${openModal} vendor=${vendor} />
				</$Grid>
			');
		});
	}
}
