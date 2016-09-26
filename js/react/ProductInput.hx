package react;
import api.react.ReactComponent;
import api.react.ReactMacro.jsx;
import Common;

typedef ProductInputProps = {
	formName:String,
	txpProductId:Int,
	productName:String,
}
typedef ProductInputRefs = {
	image:js.html.ImageElement,
	input:js.html.InputElement,
}


/**
 * Product Input with autocompletion
 * 
 * @author fbarbut
 */
class ProductInput extends api.react.ReactComponentOfPropsAndRefs<ProductInputProps,ProductInputRefs>
{

	public static var DICO : TxpDictionnary = null;
	
	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	override public function render(){
		var inputName :String = props.formName+"_name";
		var txpProductInputName :String = props.formName+"_txpProductId";
		
		return jsx('
			<div>
				<img ref="image" style={{float:"right"}} className="img-thumbnail"/>
				<input name="$inputName" ref="input" className="form-control typeahead" placeholder="Saisir un nom de produit" style={{width:"350px"}} defaultValue="${props.productName}" />
				<div className="txpProduct">
					
				</div>
				<input type="hidden" name="$txpProductInputName" className="txpProduct" value="${props.txpProductId}" />	
			</div>
		');
	}
	
	/**
	 * init typeahead auto-completion features
	 */
	override function componentDidMount(){
		
		//typeahead matching function
		var substringMatcher = function(strs:Array<String>) {
			return function findMatches(q, cb) {
			var matches = [];
				var substrRegex = new js.RegExp(q, "i");
				
				for ( str in strs){
					if (substrRegex.test(str)) {
						matches.push(str);
					}
				}

				cb(matches);
			};
		};
		
		//get dictionnary
		var products = [];
		if (DICO == null){
			
			var r = new haxe.Http("/product/getTaxo");
			r.onData = function(data){
				//load dico
				DICO = haxe.Unserializer.run(data);
				for ( p in DICO.products) products.push(p.name);
				
				//default values of input
				if (props.txpProductId != null){
					var product = Lambda.find(DICO.products, function(x) return x.id == props.txpProductId);
					setTaxo(product);
				}
			};
			r.request();
		}
		
		//init typeahead
		untyped App.j(".typeahead").typeahead(
			{hint: true, highlight: true, minLength: 2},
			{name: "products", source: substringMatcher(products) , limit:30}
		);
		
		//on suggestion select
		untyped App.j(".typeahead").bind("typeahead:select", untyped function(ev, suggestion) {
			
			var product = Lambda.find(DICO.products, function(x) return x.name == suggestion);
			setTaxo(product);
		});
	}
	
	function setTaxo(product:{id:Int,name:String,category:Int,subCategory:Int}){
		
		//print category and subcategory
		var str = getTaxoString(product);
		App.j("div.txpProduct").html(cast str);
		
		//set txpProductId in the hidden input
		App.j("input.txpProduct").val(Std.string(product.id));
		
		//image
		this.refs.image.src="/img/taxo/cat"+product.category+".png";
	}
	
	/**
	 * generate string like "fruits & vegetables / vegetables / carrots"
	 * @param	name
	 */
	function getTaxoString(product){
		
			
		//cat			
		var str = DICO.categories.get(product.category).name;
		if (product.subCategory != null){
			str += " / " + DICO.subCategories.get(product.subCategory).name;
		}
		str += " / " + product.name;
		return str;
	}
	
	

}