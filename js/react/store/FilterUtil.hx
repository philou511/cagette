
package react.store;

import js.Promise;
import haxe.Json;

import react.store.types.FilteredProductCatalog;
import Common.ProductInfo;
using Lambda;


class FilterUtil
{
    public static function filterProducts(products:Array<ProductInfo>, ?category:Int, ?subcategory:Int, ?tags:Array<String>, ?producteur:Bool ):FilteredProductCatalog
    {
        var fproducts = products.copy();

        if( category != null ) {
            fproducts = fproducts.filter(function(p:ProductInfo) {
                return Lambda.has(p.categories, category);
            });
        }

        if( category != null && subcategory != null ) {
            fproducts = fproducts.filter(function(p:ProductInfo) {
                return Lambda.has(p.subcategories, subcategory);
            });
        }

        if( tags != null ) {
            //WRONG !!! Bad implementation at the moment,  it is an OR filter on tags
            for( tag in tags ) {
                fproducts = switch( tag.toLowerCase() ) {
                    case "bio": fproducts.filter(function(p) return p.organic);
                    default: fproducts;
                }
            }
        }

        //TODO PRODUCTEUR group

        return {products:fproducts, producteur:producteur, category:category, subCategory:subcategory, search:null};
    }

    public static function searchProducts(products:Array<ProductInfo>, criteria:String ):FilteredProductCatalog
    {
        var results = [];
        //case non sensitive search
        criteria = criteria.toLowerCase();
        for( p in products ) 
        {
            if( !StringTools.startsWith(p.name.toLowerCase(), criteria) ) continue;
            results.push(p);
        }

        return {products:results, producteur:null, category:null, subCategory:null, search:criteria};
    }
}