package react.store;

import Common;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.store.SubCateg;
import mui.core.Tooltip;

class Labels extends react.ReactComponentOfProps<{product:ProductInfo}> {

    public function new(props) {
		super(props);
	}

    override public function render() {

        var style = {
            fontSize:20,
            color:mui.CagetteTheme.CGColors.Secondfont
        };

        var labels = [];

        //bio
        if(props.product.organic){
            labels.push(
                jsx('<Tooltip key="bio" title="Agriculture biologique" placement=${mui.core.popper.PopperPlacement.Top}>
                    ${mui.CagetteIcon.get("bio",style)}
                </Tooltip>')
            );
        }

        //bulk
        
        //variable-weight

        return labels;
    }
}