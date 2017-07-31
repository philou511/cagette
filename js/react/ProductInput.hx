package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import react.Typeahead;

typedef ProductInputProps = {
	formName:String,
	txpProductId:Int,
	productName:String,
}
typedef ProductInputState = {
	txpProductId:Int,
	productName:String,
	categoryId:Int,
	breadcrumb:String,
	
}


/**
 * Product Input with autocompletion
 * 
 * @author fbarbut
 */
class ProductInput extends react.ReactComponentOfPropsAndState<ProductInputProps,ProductInputState>
{

	public static var DICO : TxpDictionnary = null;
	var options : Array<{id:Int,label:String}>;
	
	public function new(props:ProductInputProps) 
	{
		super(props);
		options = [];
		
		trace(props);
		this.state = {
			txpProductId : props.txpProductId,
			productName : props.productName,
			categoryId : 0,
			breadcrumb : ""
		};
		
	}
	
	override public function render(){
		var inputName :String = props.formName+"_name";
		var txpProductInputName :String = props.formName+"_txpProductId";
		
		return jsx('
			<div className="row">
			
				<div className="col-md-8">
					<AsyncTypeahead placeholder="Saisissez un nom de produit" options=$options onSearch=$onSearch minLength={3} style={{width:"350px"}} onChange=$onChange selected={["${props.productName}"]} />				
					<div className = "txpProduct" > ${state.breadcrumb}</div>				
					
					<input className="txpProduct" type="hidden" name="$txpProductInputName" value="${state.txpProductId}" />
					<input className="txpProduct" type="hidden" name="$inputName" value="${state.productName}" />
				</div>
				
				<div className="col-md-4">
					<img ref="image" className="img-thumbnail" />
				</div>

			</div>
		');
	}
	
	
	function onSearch(o){
		//trace("on search : "+o);
	}
	
	function onChange(selection:Array<{label:String,id:Int}>){
		
		if (selection == null || selection.length == 0) return;
		
		trace(selection[0]);
		
		var product = Lambda.find(DICO.products, function(x) return x.id == selection[0].id);
		setTaxo(product);
	}
	
	/**
	 * init typeahead auto-completion features when component is mounted
	 */
	override function componentDidMount(){
		
		//get dictionnary
		if (DICO == null){
			
			var r = new haxe.Http("/product/getTaxo");
			r.onData = function(data){
				//load dico
				DICO = haxe.Unserializer.run(data);
				
				for ( p in DICO.products){
					options.push({label:p.name,id:p.id});
				}
				
				//default values of input
				if (props.txpProductId != null){
					var product = Lambda.find(DICO.products, function(x) return x.id == props.txpProductId);
					setTaxo(product);
				}
				
			
			};
			r.request();
		}
		
		
	}
	
	function setTaxo(product:{id:Int, name:String, category:Int, subCategory:Int}){
		
		if (product == null) return;
		
		//print category and subcategory
		//state.breadcrumb = getTaxoString(product);
		//App.j("div.txpProduct").html(cast str);
		
		//this.refs.input.value = Std.string(product.id);
		
		//set txpProductId in the hidden input
		//state.txpProductId = product.id;
		
		//image
		//state.categoryId = product.category;
		
		this.setState({categoryId:product.category,txpProductId:product.id,breadcrumb:getTaxoString(product)});
		
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