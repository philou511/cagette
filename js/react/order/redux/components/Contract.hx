package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common.ContractInfo;

/**
 * A Contract
 * @author web-wizard
 */
class Contract extends react.ReactComponentOfProps<{ contract : ContractInfo }>
{

	public function new(props) 
	{
		super(props);	
	}

	override public function render() {

		var imgStyle = { width: '64px', height:'64px', 'backgroundImage': 'url("${props.contract.image}")' };
		
		return jsx('<div className="contract row">
						<div className="col-md-4">
							<div src="${props.contract.image}" className="productImg" style=$imgStyle/>
						</div>
						<div className="col-md-8">
							<strong>${props.contract.name}</strong><br/>							
						</div>
					</div>');
	}

}	