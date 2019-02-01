package react.store.types;

import Common;

typedef FilteredProductCatalog = {
	var products:Array<ProductInfo>;
	@:optionnal var producteur:Bool;//TODO
	@:optionnal var category:Int;//TODO
	@:optionnal var search:String;
	var subCategory:Int;
}
