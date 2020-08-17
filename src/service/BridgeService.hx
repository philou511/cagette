package service;

class BridgeService {
	public static function call(uri: String) {
		var baseUrl = App.config.get("cagette_api") + "/bridge";
        var headers = [
			"Authorization" => "Bearer " + App.config.get("key"),
			"Content-type" 	=> "application/json;charset=utf-8",
			"Accept" 		=> "application/json",
			"Cache-Control" => "no-cache",
			"Pragma" 		=> "no-cache",
		];

		var curl = new sugoi.apis.linux.Curl();
		var res = curl.call("GET", baseUrl + uri, headers);
		
        return haxe.Json.parse(res);
	}
}
