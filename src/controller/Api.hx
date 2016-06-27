package controller;
import db.UserAmap;
import haxe.Json;
import neko.Web;

/**
 * REST JSON API
 * 
 * @author fbarbut
 */
class Api extends Controller
{

	/**
	 * Public infos about this Cagette.net installation
	 */
	public function doDefault(){
		
		var json : Dynamic = {
			version:App.VERSION.toString(),
			debug:App.config.DEBUG,			
			email:App.config.get("webmaster_email"),
			groups:[]
			
		};
		
		for ( g in db.Amap.manager.all()){
			
			//a strange way to exclude "test" accounts
			if ( UserAmap.manager.count($amapId == g.id) > 20){
				
				var place = g.getMainPlace();
				
				var d = {
					name:g.name,
					cagetteNetwork:g.flags.has(db.Amap.AmapFlags.CagetteNetwork),
					id:g.id,
					url:"http://" + Web.getHostName() + "/group/" + g.id,
					membersNum : g.getMembersNum(),
					contracts: Lambda.array(Lambda.map(g.getActiveContracts(false), function(c) return c.name)),
					place : {name:place.name, address1:place.address1,address2:place.address2,zipCode:place.zipCode,city:place.city }
				};
				json.groups.push(d);	
			}
			
		}
		
		Sys.print( Json.stringify(json) );
		
	}
	
}