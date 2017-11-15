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
};

class Store extends react.ReactComponentOfPropsAndState<StoreProps, StoreState>
{
  static inline var CATEGORY_URL = '/api/shop/categories';
  static inline var PRODUCT_URL = '/api/shop/products';

  override function componentDidMount() {
    var categoriesRequest = HttpUtil.fetch(CATEGORY_URL, GET, {date: props.date, place: props.place}, JSON);

    categoriesRequest.then(function(categories:Dynamic) { 
      var categories:Array<CategoryInfo> = categories.categories;
      var subCategories = [];

      for (c in categories) {
        subCategories = subCategories.concat(c.subcategories);
      }

      setState({
        categories: categories
      });

      var productsRequests = subCategories.map(function(category:CategoryInfo) {
        return HttpUtil.fetch(PRODUCT_URL, GET, {date: props.date, place: props.place, subcategory: category.id}, JSON).then(function(result) {

          setState({
            categories: categories
          });

        });
      });




    });


  }

  override public function render(){
    return jsx('
      <div>
        COUCOU TOI
      </div>
    ');
  }
}

