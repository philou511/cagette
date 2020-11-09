package service;

class BridgeService {
	private static var _neoManifest:Null<haxe.DynamicAccess<Dynamic>> = null;

	private static function getNeoWebpackManifest():haxe.DynamicAccess<Dynamic> {
		if (BridgeService._neoManifest == null) {
			var url = App.config.get("cagette_bridge_api") + "/neostatic/manifest.json";
			var headers = [
				// "Authorization" => "Bearer " + App.config.get("key"),
				// "Content-type" => "application/json;charset=utf-8",
				"Content-type" => "application/json",
				"Accept" => "application/json",
				"Cache-Control" => "no-cache",
				"Pragma" => "no-cache",
			];

			var curl = new sugoi.apis.linux.Curl();
			var res = curl.call("GET", url, headers);
			var manifest:haxe.DynamicAccess<Dynamic> = haxe.Json.parse(res);

			_neoManifest = manifest;
		};
		return _neoManifest;
	}

	public static function getNeoModuleScripts() {
		var manifest = BridgeService.getNeoWebpackManifest();
		return [manifest.get("runtime.js"), manifest.get("reactlibs.js"), manifest.get("vendors.js"), manifest.get("neo.js")];
	}

	public static function call(uri:String) {
		var baseUrl = App.config.get("cagette_bridge_api") + "/bridge";
		var headers = [
			"Authorization" => "Bearer " + App.config.get("key"),
			"Content-type" => "application/json;charset=utf-8",
			"Accept" => "application/json",
			"Cache-Control" => "no-cache",
			"Pragma" => "no-cache",
		];

		var curl = new sugoi.apis.linux.Curl();
		var res = curl.call("GET", baseUrl + uri, headers);

		return haxe.Json.parse(res);
	}
}
