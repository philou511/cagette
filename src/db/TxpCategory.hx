package db;
import sys.db.Object;
import sys.db.Types;
/**
 * ...
 * @author fbarbut
 */
class TxpCategory extends Object
{

	public var id : SId;
	public var name : SString<128>;	
	
	public function getSubCategories(){
		
		return db.TxpSubCategory.manager.search($category == this, false);
		
	}
	
}