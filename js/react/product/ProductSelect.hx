package react.product;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;

/**
 * A Product selector
 * @author fbarbut
 */
class ProductSelect extends react.ReactComponentOfPropsAndState<{onSelect:ProductInfo->Void,products:Array<ProductInfo>},{selected:Int}>
{
	public function new(props) 
	{
		super(props);	
		state = { selected : null };
	}

	override public function render(){

		var products = props.products.map(function(info){
			//var selector = info.id==state.selected ? jsx(''):jsx('<div className="clickable"><$Product productInfo=$info /></div>');
			return jsx('<div key=${info.id} className="col-md-6" onClick=${onClick.bind(info.id)}>
				<div className="clickable"><$Product productInfo=$info /></div>			
			</div>');
		});

		return jsx('<div className="productSelect">${products}</div>');
	}

	function onClick(i:Int){
		this.setState(cast {selected:i});
		if(props.onSelect!=null){
			var p = Lambda.find(props.products,function(x) return x.id==i);
			props.onSelect(p);
		} 
	}

}	