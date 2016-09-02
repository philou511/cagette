package react;
import api.react.ReactComponent;
import api.react.ReactMacro.jsx;
import Common;

/**
 * Product Input with autocompletion
 * 
 * @author fbarbut
 */
class ProductInput extends api.react.ReactComponent
{

	public static var DICO : TxpDictionnary = null;
	
	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	override public function render(){
		return jsx('
			<div>
				<input ref="input" className="form-control typeahead" placeholder="Saisir un nom de produit" style={{width:"350px"}}/>
				<div className="txpProduct">
					blabla
				</div>
				<input type="hidden" name="txpProduct" className="txpProduct" value="PROUT" />	
			</div>
		');
	}
	
	/**
	 * init typeahead auto-completion features
	 */
	override function componentDidMount(){
		
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
				DICO = haxe.Unserializer.run(data);
				for ( p in DICO.products) products.push(p.name);	
			};
			r.request();
			
			
		}
		
		
		untyped App.j(".typeahead").typeahead(
			{hint: true, highlight: true, minLength: 2},
			{name: "products", source: substringMatcher(products)}
		);
		
		//on suggestion select
		untyped App.j(".typeahead").bind("typeahead:select", untyped function(ev, suggestion) {
			
			var product = Lambda.find(DICO.products, function(x) return x.name == suggestion);
			
			//cat			
			var str = DICO.categories.get(product.category).name;
			if (product.subCategory != null){
				str += " / " + DICO.subCategories.get(product.subCategory).name;
			}
			str += " / " + product.name;
						
			App.j("div.txpProduct").html(cast str);
			App.j("input.txpProduct").val(suggestion);
		});
		
	}
	

}