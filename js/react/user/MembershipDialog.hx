package react.user;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.CagetteTheme;
import mui.core.Button;
import mui.core.Dialog;
import mui.core.DialogActions;
import mui.core.DialogContent;
import mui.core.DialogTitle;
import react.user.MembershipBox;



class MembershipDialog extends ReactComponentOfPropsAndState<MembershipBoxProps, {isDialogOpened:Bool}> {

	public function new( props : MembershipBoxProps ) {
		super(props);
		state = { isDialogOpened : true };    
  	}

  	// function handleClickUpload( value : String ) {
	// 	handleClose(null);
  	// }

  	override public function render() {
	
		return jsx('
			<div>
				<Dialog open=${state.isDialogOpened} onClose=$handleClose >
					<DialogContent>
						<MembershipBox userId=${props.userId} groupId=${props.groupId} callbackUrl=${props.callbackUrl} />
					</DialogContent>
				</Dialog>
			</div>'
		);
  	}

  	function handleClose( e : js.html.Event ) {
		setState( { isDialogOpened : false } );
	}
  
}