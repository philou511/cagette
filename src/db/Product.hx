package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Product
 */
class Product extends Object
{
	public var id : SId;
	public var name : SString<128>;	
	public var ref : SNull<SString<32>>;	//référence produit
	
	@:relation(contractId)
	public var contract : Contract;
	
	//prix TTC
	public var price : SFloat;
	public var vat : SFloat;
	
	public var desc : SNull<SText>;
	public var stock : SNull<SFloat>; //if qantity can be float, stock should be float
	
	public var unitType : SNull<SEnum<UnitType>>; // Kg / L / g / units
	public var qt : SNull<SFloat>;
	public var organic : SBool;
	
	@hideInForms public var type : SInt;	//icones
	
	@hideInForms @:relation(imageId) public var image : SNull<sugoi.db.File>;
	@:relation(txpProductId) public var txpProduct : SNull<db.TxpProduct>; //taxonomy
	
	public var hasFloatQt:SBool; //this product can be ordered in "float" quantity
	public var active : SBool; 	//if false, product disabled, not visible on front office
	
	
	public function new() 
	{
		super();
		type = 0;
		organic = false;
		hasFloatQt = false;
		active = true;
		vat = 0;
		
	}
	
	/**
	 * Renvoie l'URL complète d'une image en fonction du type
	 * ou une photo uploadée si elle existe
	 */
	public function getImage() {
		if (image == null) {
			
			if (txpProduct != null){				
				return "/img/taxo/cat" + txpProduct.category.id + ".png";
				
			}else{
				//old "type" field
				var e = Type.createEnumIndex(ProductType, type);		
				return "/img/"+Std.string(e).substr(2).toLowerCase()+".png";		
			}
			
			
		}else {
			return App.current.view.file(image);
		}
	}
	
	public function getName(){
	
		if (unitType != null && qt != null && qt != 0){
			return name +" " + qt + " " + App.current.view.unit(unitType);
		}else{
			return name;
		}
	}
	
	override function toString() {
		return getName();
	}
	
	/**
	 * get price including margins
	 */
	public function getPrice():Float{
		return price + contract.computeFees(price);
	}
	
	public function infos(?CategFromTaxo=false,?populateCategories=true):ProductInfo {
		var o :ProductInfo = {
			id : id,
			ref : ref,
			name : name,
			type : Type.createEnumIndex(ProductType, type),
			image : getImage(),
			contractId : contract.id,
			price : getPrice(),
			vat : vat,
			vatValue: (vat != 0 && vat != null) ? (  this.price - (this.price / (vat/100+1))  )  : null,
			contractTax : contract.percentageValue,
			contractTaxName : contract.percentageName,
			desc : desc,
			categories : null,
			subcategories:null,
			orderable : this.contract.isUserOrderAvailable(),
			stock : contract.hasStockManagement() ? this.stock : null,
			hasFloatQt : hasFloatQt,
			qt:qt,
			unitType:unitType,
			organic:organic
		}
		
		if(populateCategories){
			if (CategFromTaxo){
				o.categories = [txpProduct == null?null:txpProduct.category.id];
				o.subcategories = [txpProduct == null?null:txpProduct.subCategory.id];
			}else{
				o.categories = Lambda.array(Lambda.map(getCategories(), function(c) return c.id));
				o.subcategories = o.categories;
			}
		}
		
		return o;
	}
	
	/**
	 * customs categs
	 */
	public function getCategories() {
		return Lambda.map(db.ProductCategory.manager.search($productId == id, false), function(x) return x.category);
	}
	
	/**
	 * general categs
	 */
	public function getFullCategorization(){
		if (txpProduct == null) return [];
		return txpProduct.getFullCategorization();
	}
	
	/**
	 * get cost per unit , like 4.5EUR/Kg.
	 */
	public function getCostPerUnit():{cost:Float, qt:Float, unit:UnitType}{
		
		if (this.qt == null || this.qt == 1) return null;
		
		var _cost = getPrice() / qt;
		var _qt = 1;
		var _unit = unitType;
		
		//turn small prices in Kg
		if (_cost < 1 && this.unitType == Gram){
			_cost *= 1000;
			_unit = Kilogram;
		}
		
		return {cost:_cost,qt:_qt,unit:_unit};
		
	}
	
	public static function getByRef(c:db.Contract, ref:String){
		
		var pids = tools.ObjectListTool.getIds(c.getProducts(false));
		return db.Product.manager.select($ref == ref && $id in pids, false);
		
	}
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 				=> t._("Product name"),
			"ref" 				=> t._("Product ID"),
			"price" 			=> t._("Price"),
			"desc" 				=> t._("Description"),
			"stock" 			=> t._("Stock"),
			"unitType" 			=> t._("Base unit"),
			"qt" 				=> t._("Quantity"),			
			"hasFloatQt" 		=> t._("Allow fractional quantities"),			
			"active" 			=> t._("Active"),			
			"organic" 			=> t._("Organic agriculture"),			
			"vat" 				=> t._("VAT Rate"),			
		];
	}
	
}

