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
import mui.core.Typography;

using Lambda;

typedef ProductListSubCategoryProps = {
	> PublicProps,
};

private typedef PublicProps = {
	var subcategory:CategoryInfo;
	var products:Array<ProductInfo>;
	var openModal : ProductInfo->VendorInfo->Void;
	var vendors : Array<VendorInfo>;
}

@:publicProps(PublicProps)
class ProductListSubCategory extends react.ReactComponentOfProps<ProductListSubCategoryProps> {

	function new(p) {
		super(p);
	}

	override public function render() {
		var subcategory = props.subcategory;
		return jsx('
			<div className="subCategory" key=${subcategory.id}>
				<h3>${subcategory.name}</h3>
				<$Grid container style={{ marginBottom: 20}} spacing={Spacing_24}>
					${renderProducts(props.products)}
				</$Grid>
			</div>
		');
	}

	function renderProducts(products:Array<ProductInfo>) {
		return products.map(function(product) {
			var vendor = Lambda.find(this.props.vendors,function(v){
				return v.id == product.vendorId;
			});

			return jsx('
				<$Grid item xs={12} sm={4} md={3} key=${product.id}>
					<$Product product=${product} openModal=${props.openModal} vendor=${vendor} />
				</$Grid>
			');
		});
	}
}
