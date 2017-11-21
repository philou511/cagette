package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.ReactUtil.copy;
import js.html.XMLHttpRequest;
import haxe.Json;

using Lambda;

import Common;
import utils.CartUtils;
import utils.HttpUtil;

typedef StoreProps = {
  var place:Int;
  var date:String;
};

typedef StoreState = {
  var categories:Array<CategoryInfo>;
  var productsBySubcategoryIdMap:Map<Int, Array<ProductInfo>>;
  var order:OrderSimple;
};

class Store extends react.ReactComponentOfPropsAndState<StoreProps, StoreState>
{
  static inline var CATEGORY_URL = '/api/shop/categories';
  static inline var PRODUCT_URL = '/api/shop/products';

  public function new() {
    super();
    state = {
      categories: [],
      productsBySubcategoryIdMap: new Map(),
      order: {
        products: [],
        total: 0
      }
    };
  }

  override function componentDidMount() {
    var categoriesRequest = HttpUtil.fetch(CATEGORY_URL, GET, {date: props.date, place: props.place}, JSON);

    categoriesRequest.then(function(categories:Dynamic) {
      var categories:Array<CategoryInfo> = categories.categories;
      var subCategories = [];

      for (category in categories) {
        subCategories = subCategories.concat(category.subcategories);
      }

      setState({
        categories: categories
      });

      var productsRequests = subCategories.map(function(category:CategoryInfo) {
        return HttpUtil.fetch(PRODUCT_URL, GET, {date: props.date, place: props.place, subcategory: category.id}, JSON)
        .then(function(result) {
          var productsBySubcategoryIdMapCopy = [
            for (key in state.productsBySubcategoryIdMap.keys())
              key => state.productsBySubcategoryIdMap.get(key)
          ];
          productsBySubcategoryIdMapCopy.set(category.id, result.products);

          setState({
            productsBySubcategoryIdMap: productsBySubcategoryIdMapCopy
          });
        });
      });
    });
  }

  function addToCart(productToAdd:ProductInfo, quantity:Int) {
    setState({
      order: CartUtils.addToCart(state.order, productToAdd, quantity)
    });
  }

  override public function render(){
    return jsx('
      <div className="shop">
        ${renderCategories()}
      </div>
    ');
  }

  function renderCategories() {
    var categories = state.categories.map(function(category) {
      return jsx('
        <div className="category" key=${category.name}>
          <h2>${category.name}</h2>
          <div className="subCategories">
            ${renderSubCategories(category)}
          </div>
        </div>
      ');
    });

    return jsx('
      <div className="categories">
        $categories
      </div>
    ');
  }

  function renderSubCategories(category) {
    var subCategories = category.subcategories.map(function(category) {
      if (!state.productsBySubcategoryIdMap.exists(category.id))
        return jsx('<div key=${category.name}>Loading...</div>');

      var products = state.productsBySubcategoryIdMap.get(category.id);

      return jsx('
        <div className="sub-category" key=${category.name}>
          <h3>${category.name}</h3>
          <div className="products">
            ${renderProducts(products)}
          </div>
        </div>
      ');
    });

    return jsx('
      <div className="sub-categories">
        $subCategories
      </div>
    ');
  }

  function renderProducts(products) {
    return products.map(function(product) {
      return jsx('
        <Product product=${product} key=${product.id} addToCart=$addToCart/>
      ');
    });
  }
}

