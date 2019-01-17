package mui;

import react.ReactMacro.jsx;
import classnames.ClassNames.fastNull as classNames;
import mui.icon.Icon;

class CagetteIcon{

    /**
        Get a mui Icon using Cagette's icon font
    **/
    public static function get(iconId:String,?style:Dynamic){
        var classes = {'icons':true};
        Reflect.setField(classes,"icon-"+iconId,true);
        var iconObj = classNames(classes);
        return jsx('<Icon component="i" className=${iconObj} style=$style></Icon>');
    }

}