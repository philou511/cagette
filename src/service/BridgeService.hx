package service;

import sugoi.apis.linux.Curl;

class BridgeService {
	private static var _neoManifest:Null<haxe.DynamicAccess<Dynamic>> = null;

	private static function getNeoWebpackManifest():haxe.DynamicAccess<Dynamic> {
		if (BridgeService._neoManifest == null) {
			var url = App.config.get("cagette_bridge_api") + "/neostatic/manifest.json";
			var curl = new Curl();			
			var res = curl.call("GET", url, getHeaders());
			var manifest:haxe.DynamicAccess<Dynamic> = haxe.Json.parse(res);
			_neoManifest = manifest;
		};
		return _neoManifest;
	}

	public static function getNeoModuleScripts() {
		try{
			var manifest = BridgeService.getNeoWebpackManifest();
			return [manifest.get("runtime.js"), manifest.get("reactlibs.js"), manifest.get("vendors.js"), manifest.get("neo.js")];
		}catch(e:Dynamic){
			throw "Unable to load NeoModuleScripts from Nest backend.";
		}
	}

	public static function call(uri:String) {
		var baseUrl = App.config.get("cagette_bridge_api") + "/bridge";
		var curl = new Curl();
		var res = curl.call("GET", baseUrl + uri, getHeaders());
		try{
			return haxe.Json.parse(res);
		}catch(e:Dynamic){
			throw "Bridge Error :"+Std.string(e)+", raw : "+Std.string(res);			
		}		
	}

	public static function getAuthToken(user:db.User) {
		var baseUrl = App.config.get("cagette_bridge_api") + "/bridge";
		var curl = new Curl();
		//no json
		return curl.call("GET", baseUrl + "/auth/tokens/"+user.id, getHeaders());
	}

	public static function logout(user:db.User) {
		if (user==null) return null;
		var baseUrl = App.config.get("cagette_bridge_api") + "/bridge";
		var curl = new sugoi.apis.linux.Curl();
		return curl.call("GET", baseUrl + "/auth/logout/"+user.id, getHeaders());
	}

	/**
		Trigger workflow in HS
	**/
	public static function triggerWorkflow(workflowId: Int, contactEmail: String) {		
		var curl = new sugoi.apis.linux.Curl();
		return curl.call("GET", '${App.config.get("cagette_bridge_api")}/crm/triggerWorkflow/$workflowId/$contactEmail', getHeaders());
	}

	static function getHeaders():Map<String,String>{
		return [
			"Authorization" => "Bearer " + App.config.get("key"),
			"Content-type" => "application/json;charset=utf-8",
			"Accept" => "application/json",
			"Cache-Control" => "no-cache",
			"Pragma" => "no-cache",
		];

	}

	public static function syncVendorToHubspot(vendor:db.Vendor) {       
        // if(App.config.DEBUG) return;
        var key = haxe.crypto.Md5.encode(App.config.KEY + vendor.id);
        var req = haxe.Http.requestUrl(App.config.get("cagette_bridge_api")+"/crm/hubspot/"+vendor.id+"/"+key);     		  
    }  

	public static function syncUserToHubspot(user:db.User) {       
		var curl = new sugoi.apis.linux.Curl();
		return curl.call("GET", '${App.config.get("cagette_bridge_api")}/crm/syncUser/${user.id}', getHeaders());
		  
    }  
}
