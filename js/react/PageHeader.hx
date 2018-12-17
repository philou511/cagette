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


class PageHeader extends react.ReactComponentOfProps<{}> {
	
    public function new() {
		super();
		state = {};
	}

    override public function render(){
        return jsx('
            <div>
                <$AppBar position=${CSSPosition.Static} color=${mui.Color.Default}>
                    <$Tabs onChange=$handleChange>
                        <$Tab label="ACCUEIL" value="home"/>
                        <$Tab label="MON COMPTE" value="account"/>
                        <$Tab label="PRODUCTEURS" />

                        <$Tab label="ADHÉRENTS" />
                        <$Tab label="CONTRATS" />
                        <$Tab label="MESSAGERIE" />
                        <$Tab label="PRODUCTEURS" />
                        <$Tab label="ADMIN" />
                    </$Tabs>
                </$AppBar>
            </div>
        ');
    }

    public function handleChange(event:js.html.Event){
        
        trace(event);
        
    }
}
