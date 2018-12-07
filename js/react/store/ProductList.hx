package react.store;
import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.Grid;

using Lambda;

typedef ProductListProps = {
  var categories:Array<CategoryInfo>;
  var productsBySubcategoryIdMap:Map<Int, Array<ProductInfo>>;
  var filters:Array<String>;
  var addToCart:ProductInfo -> Int -> Void;
};

class ProductList extends react.ReactComponentOfProps<ProductListProps>
{
  override public function render(){
    return jsx('
      <div className="categories">
        ${renderCategories()}
      </div>
    ');
  }

  function renderCategories() {
    return props.categories.map(function(category) {
      if (!props.filters.has(category.name))
        return null;

      return jsx('
        <div className="category" key=${category.name}>
          <h2>${category.name}</h2>
          <div className="subCategories">
            ${renderSubCategories(category)}
          </div>
        </div>
      ');
    });
  }

  function renderSubCategories(category) {
    var subCategories = category.subcategories.map(function(category) {
      if (!props.productsBySubcategoryIdMap.exists(category.id))
        return jsx('<div key=${category.name}>Loading...</div>');

      var products = props.productsBySubcategoryIdMap.get(category.id);

      return jsx('
        <div className="sub-category" key=${category.name}>
          <h3>${category.name}</h3>
          <div className="products">
            <$Grid container style={{ marginBottom: 20}}  spacing={Spacing_24}>
              ${renderProducts(products)}
            </$Grid>
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

  function renderProducts(products:Array<ProductInfo>) {
    if( products == null || products.length == 0 ) return null;
    
    //for debug purpose only
    //var products = [products[0]];

    return products.map(function(product) {
      return jsx('
        <$Grid item xs={12} sm={4} md={3} key=${product.id}>
          <$Product product=${product}  addToCart=${props.addToCart}/>
        </$Grid>
      ');
    });
  }
}

