package service;

import db.Vendor;
import haxe.Json;
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
		List of HS workflows to be used in the triggerWorflow function
	**/
	public static var HUBSPOT_WORKFLOWS_ID = {
		vendorCertifiedAndOnboarding: 29858317,
		vendorFirstSaleDone: 29858959,
		discoveryTurnoverLimitReached: 29858927,
		turnoverLimitReached: 30100220,
		vendorSignedUp: 29858832,
		vendorLimitReachedUnlock: 29861865,
		firstGroupCreated: 29805116,
		vendorSubscribed: 31422026,
		subscriptionCanceledAtPeriodEnd: 31746160,
		yearlySubscriptionRenewedInOneMonth: 31746177,
		setContactAsNonMarketing: 34278655,
		setContactAsMarketing: 34278796,
	  }

	/**
		Trigger workflow in HS
	**/
	public static function triggerWorkflow(workflowId: Int, contactEmail: String) {		
		var curl = new sugoi.apis.linux.Curl();
		return curl.call("GET", '${App.config.get("cagette_bridge_api")}/crm/triggerWorkflow/$workflowId/$contactEmail', getHeaders());
	}

	/**
		Post an event to track with Matomo
	**/
	public static function matomoEvent(userId:Int,category:String,action:String,?name:String,?value:Int){
		var curl = new sugoi.apis.linux.Curl();
		var post = {
			userId:userId,
			category:category,
			action:action,
			name:name,
			value:value
		}
		return curl.call("POST", '${App.config.get("cagette_bridge_api")}/bridge/matomo', getHeaders(), Json.stringify(post));
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
		var key = haxe.crypto.Md5.encode(App.config.KEY + vendor.id);
		var req = haxe.Http.requestUrl(App.config.get("cagette_bridge_api")+"/crm/hubspot/"+vendor.id+"/"+key);
	}

	public static function syncUserToHubspot(user:db.User, ?vendor: db.Vendor) {
		var curl = new sugoi.apis.linux.Curl();
		var url = '${App.config.get("cagette_bridge_api")}/crm/syncUser/${user.id}';
		if (vendor!=null) url += '/${vendor.id}';
		return curl.call("GET", url, getHeaders());
	}

	public static function deleteHubspotAssociationContactToCompany(user:db.User, vendor: db.Vendor) {
		var curl = new sugoi.apis.linux.Curl();
		return curl.call("GET", '${App.config.get("cagette_bridge_api")}/crm/deleteAssociation/${user.id}/${vendor.id}', getHeaders());
	}
}
