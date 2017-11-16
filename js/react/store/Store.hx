package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import js.html.XMLHttpRequest;
import haxe.Json;
import utils.HttpUtil;
import Common;

typedef StoreProps = {
  var place:Int;
  var date:String;
};

typedef StoreState = {
  var categories:Array<CategoryInfo>;
  var productsMap:Map<Int, Array<ProductInfo>>;
};

class Store extends react.ReactComponentOfPropsAndState<StoreProps, StoreState>
{
  static inline var CATEGORY_URL = '/api/shop/categories';
  static inline var PRODUCT_URL = '/api/shop/products';

  public function new() {
    super();
    state = {
      categories: [],
      productsMap: new Map()
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
          var productsMapCopy = [
            for (key in state.productsMap.keys())
              key => state.productsMap.get(key)
          ];
          productsMapCopy.set(category.id, result.products);

          setState({
            productsMap: productsMapCopy
          });
        });
      });
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
      if (!state.productsMap.exists(category.id))
        return jsx('<div key=${category.name}>Loading...</div>');

      return jsx('
        <div className="subCategory" key=${category.name}>
          <h3>${category.name}</h3>
          <div>
            ${renderProducts(state.productsMap.get(category.id))}
          </div>
        </div>
      ');
    });

    return jsx('
      <div className="categories">
        $subCategories
      </div>
    ');
  }

  function renderProducts(products) {
    trace('Products', products);
    return products.map(function(product) {
      return jsx('
        <div className="product" key=${product.name}>
          ${product.name}
        </div>
      ');
    });
  }
}

