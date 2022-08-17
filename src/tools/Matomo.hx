package tools;

typedef MatomoData = {
    events:Array<{category:String,action:String,name:String,value:Int}>,
}

/**
    track events in Matomo.
    Events are stored in session and tracked on the *frontend*
**/
class Matomo{

    public static function trackEvent(category:String,action:String,?name:String,?value:Int){
        var data = getData();
        data.events.push({
            category:category,
            action:action,
            name:name,
            value:value
        });
        App.current.session.data.matomo = data;
    }

    public static function getEvents(){
        var events = getData().events;
        App.current.session.data.matomo = null;
        return events;
    }

    public static function getData():MatomoData{
        var data:MatomoData = App.current.session.data.matomo;
        if(data==null) {
            data = {events:[]};
        }
        return data;
    }


}