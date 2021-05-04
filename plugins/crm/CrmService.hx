package crm;

import haxe.Json;
import haxe.Http;

/**
    bridge to CRM Module in Cagette 2 API
**/
class CrmService{

    public static function syncToHubspot(vendor:db.Vendor) {       
        // if(App.config.DEBUG) return;
        var key = haxe.crypto.Md5.encode(App.config.KEY + vendor.id);
        var req = Http.requestUrl(App.config.get("cagette_bridge_api")+"/crm/hubspot/"+vendor.id+"/"+key);       
    }  
    
    
    public static function syncToSiB(user:db.User,?newsletter:Bool,?event:String, ?eventData:Dynamic) {
        // if(App.config.DEBUG) return;
        var key = haxe.crypto.Md5.encode(App.config.KEY + user.id);
        var url = App.config.get("cagette_bridge_api")+"/crm/sib/"+user.id+"/"+key;
       /* var params = [];
        if(newsletter) params.push("newsletter=1");
        if(event!=null) params.push("event="+event);
        if(eventData!=null) params.push("eventData="+Json.stringify(params));
        
        //send as GET
        if(params.length>0){
            url  = url + "?" + params.join("&");
        }
        var req = Http.requestUrl(url);*/

        //Send as POST
        var req = new Http(url);
        if(newsletter) req.addParameter("newsletter","1");
        if(event!=null) req.addParameter("event",event);
        if(eventData!=null) req.addParameter("eventData",Json.stringify(eventData)); 

        /*req.onData = function(res:String){
            Sys.print("<br/>"+res);
        };
        req.onError = function(res:String){
            Sys.print("<br/>ERROR : "+res);
        };
        Sys.print(url);*/
        req.request(true);
        
    }   


}