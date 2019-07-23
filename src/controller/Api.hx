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
	
	/*public function doError(){
		sugoi.Web.setReturnCode(403);
	}*/
	
	
	#if plugins
	//cagette-pro
	public function doPro(d:haxe.web.Dispatch) {
		d.dispatch(new pro.controller.api.Main());
	}	
	#end
	
	public function doShop(d:haxe.web.Dispatch) {
		d.dispatch(new controller.api.ShopApi());
	}	
	
	public function doOrder(d:haxe.web.Dispatch) {
		d.dispatch(new controller.api.Order());
	}	

	/**
	 * Get distribution planning for this group
	 * 
	 * @param	group
	 */
	public function doPlanning(group:db.Amap){
		
		var contracts = group.getActiveContracts(true);
		var cids = Lambda.map(contracts, function(p) return p.id);
		var now = Date.now();
		var now = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
		var twoMonths = new Date(now.getFullYear(), now.getMonth()+2, now.getDate(), 0, 0, 0);
		var distribs = db.Distribution.manager.search(($contractId in cids) && ($date >= now) && ($date<=twoMonths), { orderBy:date }, false);
		
		var out = new Array<{id:Int,start:Date,end:Date,contract:String,contractId:Int,place:Dynamic}>();
		
		for ( d in distribs){
			
			var place = d.place;
			var p =  {name:place.name, address1:place.address1,address2:place.address2,zipCode:place.zipCode,city:place.city }			
			out.push({id:d.id,start:d.date,end:d.end,contract:d.contract.name,contractId:d.contract.id,place:p});
		}
		
		Sys.print(Json.stringify(out));
		
	}
	
	public function doUser(d:haxe.web.Dispatch){
		d.dispatch(new controller.api.User());
	}
	
	public function doGroup(d:haxe.web.Dispatch){
		d.dispatch(new controller.api.Group());
	}

	public function doProduct(d:haxe.web.Dispatch){
		d.dispatch(new controller.api.Product());
	}
	
}