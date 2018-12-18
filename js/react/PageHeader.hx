package react;

import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.common.CSSPosition;

import utils.HttpUtil;

import mui.core.*;

import Common;
using Lambda;

typedef PageHeaderProps = {userRights:Rights,groupName:String,userName:String,userId:Int};

class PageHeader extends react.ReactComponentOfPropsAndState<PageHeaderProps,{anchorMenu:js.html.Element}> {
	
   
    public function new() {
		super();
        state = {anchorMenu:null};
	}

    override public function render(){

        var members = hasRight(Right.Membership) ? jsx('<$Tab label="ADHÉRENTS" value="members"/>') : null;
        var contracts = hasRight(Right.ContractAdmin()) ? jsx('<$Tab label="CONTRATS" value="contracts"/>') : null;
        var messages = hasRight(Right.Messages) ? jsx('<$Tab label="MESSAGERIE" value="messages"/>') : null;
        var group = hasRight(Right.GroupAdmin) ? jsx('<$Tab label="GROUPE" value="group"/>') : null;

        var anchorEl = state.anchorMenu;

        return jsx('
            <$Grid container justify=${css.JustifyContent.Center} style=${{marginBottom:"12px",maxWidth:"1240px",marginLeft:"auto",marginRight:"auto"}}>
                <$Grid item xs={6}>
                    <h1>${props.groupName}</h1>
                </$Grid>
                <$Grid item xs={6} style=${{textAlign:"right"}}>
                    <div>
                        <$Button onClick=$onUserMenuOpen aria-owns=${anchorEl!=null ? "simple-menu" : null} aria-haspopup="true" >
                            <i className="icon icon-user"></i> ${props.userName}
                        </$Button>
                        <$Menu id="simple-menu"
                        anchorEl=${anchorEl}
                        open=${anchorEl!=null}
                        onClose=$onUserMenuClose>
                            <$MenuItem onClick=$onUserMenuClick>Profile</MenuItem>
                            <$MenuItem onClick=$onUserMenuClick>My account</MenuItem>
                            <$MenuItem onClick=$onUserMenuClick>Logout</MenuItem>
                        </$Menu>
                    </div>

                </$Grid>

                <$Grid item xs={12}>
                    <$AppBar position=${CSSPosition.Static} color=${mui.Color.Default}>
                        <$Tabs onChange=${ cast handleChange}>
                            <$Tab label="ACCUEIL" value="home"/>
                            <$Tab label="MON COMPTE" value="account"/>
                            <$Tab label="PRODUCTEURS" value="farmers"/>

                            $members
                            $contracts
                            $messages
                            $group
                            
                        </$Tabs>
                    </$AppBar>
                </$Grid>
            </$Grid>
        ');
    }

    /**
        TODO : this kind of signature is not implemented in the extern
    **/
    public function handleChange(_,value:String){
        
        js.Browser.window.location.href = switch(value){
            case "account":"/contract";
            case "farmers":"/amap";
            case "members":"/member";
            case "contracts":"/contractAdmin";
            case "messages":"/messages";
            case "group":"/amapadmin";
            case "admin":"/admin";
            default : "/";

        } ; 
    }

    function onUserMenuClose(event:js.html.Event,cause:mui.core.modal.ModalCloseReason){

        this.setState({ anchorMenu:null});

    }

    function onUserMenuClick(event:js.html.Event){

        this.setState({ anchorMenu:null});

    }

    function onUserMenuOpen(event:js.html.Event){
        trace(event.currentTarget);
       this.setState({ anchorMenu:cast event.currentTarget});
    }

    public function hasRight(r:Common.Right):Bool {
		if (props.userRights == null) return false;
		for ( right in props.userRights) {
			if ( Type.enumEq(r,right) ) return true;
		}
		return false;
	}
}
