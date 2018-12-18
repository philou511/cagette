package db;
import sys.db.Object;
import sys.db.Types;

/**
 * Category
 * @author fbarbut
 */
class TxpCategory extends Object
{

	public var id : SId;
	public var image : Null<SString<64>>;
	public var displayOrder : STinyInt;
	public var name : SString<128>;	
	
	public function getSubCategories(){
		
		return db.TxpSubCategory.manager.search($category == this, false);
		
	}
	
	override public function toString(){
		return '#$id-$name';
	}
}