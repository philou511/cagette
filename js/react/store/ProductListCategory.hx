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
import mui.core.CircularProgress;
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

private typedef ProductListCategoryState = {
	var currentSubCategoryCount:Int;
	var data:Array<{subcategory:CategoryInfo, products:Array<ProductInfo>}>;
	var catalogSize:Int;
	var loadMore:Bool;
}

@:publicProps(PublicProps)
class ProductListCategory extends react.ReactComponentOf<ProductListCategoryProps, ProductListCategoryState> {

	function new(p) {
		super(p);
		this.state = {currentSubCategoryCount:0, catalogSize:0, data:[], loadMore:false};
	}

	override function componentWillUnmount() {
		if( timer != null ) timer.stop();
		timer = null;
	}

	/**
		Triggered when props are updated
	**/
	static function getDerivedStateFromProps(nextProps:ProductListCategoryProps, currentState:ProductListCategoryState):ProductListCategoryState {
		if( nextProps.category == null ) return null;
		//trace("getDerivedStateFromProps "+nextProps.catalog.category+", "+nextProps.catalog.subCategory);
		//trace(nextProps.catalog.products.length);
		var data = cleanData(nextProps.category, nextProps.catalog);
		if( currentState.catalogSize == nextProps.catalog.products.length && data.length == currentState.data.length ) return null;
		//trace("we change state, we need to reload");
		return {data:data, currentSubCategoryCount:0, catalogSize: nextProps.catalog.products.length, loadMore:true};
	}

	static function cleanData(category:CategoryInfo, catalog:FilteredProductCatalog) {
		if( category.subcategories == null ) return [];
		
		var a = [];
		for( i in 0...category.subcategories.length) {
			var subcategory = category.subcategories[i];
			var subProducts = catalog.products.filter(function(p) {
				return Lambda.has(p.subcategories, subcategory.id);
			});

			if( subProducts.length == 0 ) continue;
			a.push({subcategory:subcategory, products:subProducts});
		}
		return a;
	}

	var timer:haxe.Timer;
	function loadMore() {
		if( state.data.length == 0 ) return;
		if( state.currentSubCategoryCount == state.data.length) return;
		setState({currentSubCategoryCount:state.currentSubCategoryCount+1}, function() {
			timer = haxe.Timer.delay(loadMore, 400);
		});
	}

	override function componentDidMount() {
		//trace("componentDidMount "+state.loadMore);
		if( state.loadMore == true ) {
			//trace("we ask for reloading");
			setState({loadMore:false}, loadMore);
		}
	}
	override function componentDidUpdate(prevProps:ProductListCategoryProps, prevState:ProductListCategoryState) {
		//trace("componentDidUpdate "+state.loadMore);
		if( state.loadMore == true ) {
			//trace("we ask for reloading");
			setState({loadMore:false}, loadMore);
		}
	}

	override public function render() {
		var categoryName =  if(state.data.length > 0) jsx('<h2>${props.category.name}</h2>')
							else null;
		
		return jsx('
			<div className="category" key=${props.category.name}>
				{categoryName}
				<div className="subCategories">
					${renderSubCategories()}
				</div>
			</div>
		');
	}

	function renderSubCategories() {
		var shouldOfferDifferedLoading = props.catalog.category == null;
		
		var totalProducts = Lambda.fold(state.data, function(d, count:Int) { return count + d.products.length; }, 0);
		
		if( (state.data.length == 0 || totalProducts == 0) && props.catalog.category != null ) {
			return jsx('
				<Typography component="h4" align={Center}>
					Il n\'y a aucun produit dans cette catégorie ${props.category.name}
				</Typography>
			');
		}

		//trace("renderSubCategories "+state.currentSubCategoryCount);
		//trace("shouldLoad "+state.loadMore);
		var list = [for( i in 0...state.currentSubCategoryCount ) {
			var subcategory = state.data[i].subcategory;
			var subProducts = state.data[i].products;
			jsx('
				<ProductListSubCategory displayAll=${!shouldOfferDifferedLoading} key=${subcategory.id} subcategory=${subcategory} products=${subProducts} vendors={props.vendors} openModal=${props.openModal}  />
			');
		}];

		return jsx('<>${list}</>');
	}
}
