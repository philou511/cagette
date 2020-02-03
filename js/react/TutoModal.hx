package react;

import react.ReactMacro.jsx;
import react.ReactComponent;
import mui.core.Dialog;

class TutoModal extends ReactComponent {


  override public function render() {
    var res = 
      <Dialog open>
        <div>HELLO</div>
      </Dialog>
    ;

    return jsx('$res');
  }

}