package db;
import sys.db.Types;

@:id(productId,categoryId)
class ProductCategory extends sys.db.Object
{
	
	@:relation(productId)
	public var product : db.Product;
	
	@:relation(categoryId)
	public var category : db.Category;
	
	
	public static function create(product, category){
		
		var x = new db.ProductCategory();
		x.product = product;
		x.category = category;
		x.insert();
		return x;
		
	}
	
}