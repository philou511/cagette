package react;

import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.common.CSSPosition;

import utils.HttpUtil;

import mui.core.Tab;
import mui.core.AppBar;
import mui.core.Tabs;

import Common;
using Lambda;

typedef PageHeaderProps = {userRights:Rights,groupName:String};

class PageHeader extends react.ReactComponentOfProps<PageHeaderProps> {
	
    public function new() {
		super();
	}

    override public function render(){
        return jsx('
            <div>
                <div>
                    <h1>Mon super Groupe</h1>
                </div>
                <$AppBar position=${CSSPosition.Static} color=${mui.Color.Default}>
                    <$Tabs onChange=${ cast handleChange}>
                        <$Tab label="ACCUEIL" value="home"/>
                        <$Tab label="MON COMPTE" value="account"/>
                        <$Tab label="PRODUCTEURS" value="farmers"/>

                        <$Tab label="ADHÉRENTS" value="members"/>
                        <$Tab label="CONTRATS" value="contracts"/>
                        <$Tab label="MESSAGERIE" value="messages"/>
                        <$Tab label="GROUPE" value="group"/>
                        <$Tab label="ADMIN" value="admin"/>
                    </$Tabs>
                </$AppBar>
            </div>
        ');
    }

    /**
    TODO : this kind of signature is not implemented in the extern
    **/
    public function handleChange(_,value:Dynamic){
        
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
}
