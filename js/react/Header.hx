package react;

import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.common.CSSPosition;

import utils.CartUtils;
import utils.HttpUtil;

import mui.core.Tab;
import mui.core.AppBar;
import mui.core.Tabs;

import Common;
using Lambda;


class Header extends react.ReactComponentOfProps<{}> {
	
    public function new() {
		super();
		state = {};
	}

    override public function render(){
        return jsx('
            <div>
                <$AppBar position=${CSSPosition.Static}>
                    <$Tabs onChange=$handleChange>
                        <$Tab label="Item One" />
                        <$Tab label="Item Two" />
                        <$Tab label="Item Three" />
                    </$Tabs>
                </$AppBar>
            </div>
        ');
    }

    public function handleChange(_){

    }
}
