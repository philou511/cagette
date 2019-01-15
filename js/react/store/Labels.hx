package react.store;

import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.store.SubCateg;

class Labels extends react.ReactComponentOfProps<{product:ProductInfo}> {

    public function new(props) {
		super(props);
	}

    override public function render() {
        if(props.product.organic){
            return jsx('<$SubCateg label="Bio" colorClass="cagBio"  />');
        }else{
            return null;
        }
    }
}