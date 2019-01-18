package react.product;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import react.Typeahead;

private typedef CategorySelectorProps = {
	formName:String,
	txpProductId:Int,
	productName:String,
}

private typedef CategorySelectorState = {
	txpProductId:Int,
	productName:String,
	categoryId:Int,
	breadcrumb:String,	
}

/**
 * Select the category of a product
 * 
 * @author fbarbut
	@deprecated
 */
class CategorySelector extends react.ReactComponentOfPropsAndState<PCategorySelectorProps,CategorySelectorState> {

	public static var DICO : TxpDictionnary = null;
	var options : Array<{id:Int,label:String}>;
	var imgRef: react.ReactRef<{src:String}>;

	public function new(props:ProductInputProps) {
		super(props);
		options = [];
		this.state = {
			txpProductId : props.txpProductId,
			productName : props.productName,
			categoryId : 0,
			breadcrumb : ""
		};
		this.imgRef  = React.createRef();
	}
	
	override public function render(){
		var inputName :String = props.formName+"_name";
		var txpProductInputName :String = props.formName+"_txpProductId";
		
		return jsx('
			<div className="row">
			
				<div className="col-md-8">
					
                    

					<div className = "txpProduct" > ${state.breadcrumb}</div>				
					
					<input className="txpProduct" type="hidden" name="$txpProductInputName" value="${state.txpProductId}" />
					<input className="txpProduct" type="hidden" name="$inputName" value="${state.productName}" />
				</div>
				
				<div className="col-md-4">
					<img ref=${this.imgRef} className="img-thumbnail" />
				</div>

                <Modal>
                    <ExpansionPanel>
                        <ExpansionPanelSummary expandIcon={<ExpandMoreIcon />}>
                        <Typography className={classes.heading}>Expansion Panel 1</Typography>
                        </ExpansionPanelSummary>
                        <ExpansionPanelDetails>
                        <Typography>
                            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse malesuada lacus ex,
                            sit amet blandit leo lobortis eget.
                        </Typography>
                        </ExpansionPanelDetails>
                    </ExpansionPanel>
                </Modal>


			</div>
		');
	}
	
	/**
	 * Called when typing is stopped 
	 * @param	o
	 */
	function onSearch(o){
		//trace("on search : "+o);
	}
	
	/**
	 * Each time a single letter change in the input
	 * @param	input
	 */
	function onInputChange(input:String){
		trace('on input change $input');
		this.setState({productName:input});
	}
	
	/**
	 * Called when an item is selected in suggestions
	 */
	function onChange(selection:Array<{label:String,id:Int}>){
		
		if (selection == null || selection.length == 0) return;
		
		trace("on change "+selection[0]);
		
		var product = Lambda.find(DICO.products, function(x) return x.id == selection[0].id);
		setTaxo(product);
		this.setState({productName:selection[0].label});
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
					var txp = Lambda.find(DICO.products, function(x) return x.id == props.txpProductId);
					setTaxo(txp);
				}
			};
			r.request();
		}
	}
	
	function setTaxo(txp:{id:Int, name:String, category:Int, subCategory:Int}){
		
		if (txp == null) return;
		
		//trace(txp);
		
		this.setState({
			categoryId:txp.category,
			txpProductId:txp.id,
			breadcrumb:getBreadcrumb(txp)/*,
			productName:product.name	//do not override product name !		*/
		});
		
		this.imgRef.current.src="/img/taxo/cat"+txp.category+".png";
	}
	
	/**
	 * generate string like "fruits & vegetables / vegetables / carrots"
	 * @param	name
	 */
	function getBreadcrumb(product){
		//cat			
		var str = D
		ICO.categories.get(product.category).name;
		if (product.subCategory != null){
			str += " / " + DICO.subCategories.get(product.subCategory).name;
		}
		str += " / " + product.name;
		return str;
	}
}