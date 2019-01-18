package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.Dialog;
import mui.core.DialogActions;
import mui.core.DialogContent;
import mui.core.DialogContentText;
import mui.core.DialogTitle;

import mui.core.Button;
import Common;

/**
 * An Error Dialog
 */
class MuiError extends react.ReactComponentOfProps<{errorMessage:String,onClose:Void->Void}>
{

	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	
	override public function render(){
		return jsx('<Dialog open=${props.errorMessage != null} onClose=${props.onClose}>                
				<DialogTitle id="alert-dialog-title">
                    Erreur
                </DialogTitle>
                    <DialogContent>
                        <DialogContentText id="alert-dialog-description">
                            <i className="icon icon-alert" style={{color:"#C00"}}></i>
                            &nbsp;${props.errorMessage}
                        </DialogContentText>
                    </DialogContent>
                    <DialogActions>
                        <Button onClick=${props.onClose}>
                        OK
                        </Button>
                    </DialogActions>
			</Dialog>');
	}

	
}