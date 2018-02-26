package controller.api;
import haxe.Json;
import Common;

/**
 * Groups API
 * @author fbarbut
 */
class Group extends Controller
{
	/**
	 * JSON map datas
	 * 
	 * Request by zone : http://localhost/api/group/map?minLat=42.8115217450979&maxLat=51.04139389812637=&minLng=-18.369140624999996&maxLng=23.13720703125
	 * Request by location : http://localhost/api/group/map?lat=48.85&lng=2.32
	 * Request by address : http://localhost/api/group/map?address=105%20avenue%20d%27ivry%20Paris
	 */
	public function doMap(args:{?minLat:Float, ?maxLat:Float, ?minLng:Float, ?maxLng:Float, ?lat:Float, ?lng:Float, ?address:String}) {
	
		var out  = new Array<GroupOnMap>();
		var places  =  new List<db.Place>();
		if (args.minLat != null && args.maxLat != null && args.minLng != null && args.maxLng != null){
			
			//Request by zone
			#if plugins
			var sql = "select p.* from Place p, Hosting h where h.id=p.amapId and h.visible=1 and ";
			sql += 'p.lat > ${args.minLat} and p.lat < ${args.maxLat} and p.lng > ${args.minLng} and p.lng < ${args.maxLng}';			
			#else
			var sql = "select p.* from Place p where ";
			sql += 'p.lat > ${args.minLat} and p.lat < ${args.maxLat} and p.lng > ${args.minLng} and p.lng < ${args.maxLng}';
			#end
			places = db.Place.manager.unsafeObjects(sql, false);
			
		}else if (args.lat!=null && args.lng!=null){
			
			//Request by location
			places = findGroupByDist(args.lat, args.lng);
			
		}else{
			//Request by address
			if (args.address == null) throw "Please provide parameters";
			
			var geocode = new sugoi.apis.google.GeoCode(App.config.get("google_geocoding_key"));
			var loc = geocode.geocode(args.address)[0].geometry.location;
			
			args.lat = loc.lat;
			args.lng = loc.lng;
			
			places = findGroupByDist(args.lat, args.lng);
		}
		
		for ( p in places){
			out.push({
				id : p.amap.id,
				name : p.amap.name,
				image : p.amap.image==null ? null : view.file(p.amap.image),
				place : p.getInfos()
			});
		}

		Sys.print(haxe.Json.stringify({success:true,groups:out}));
	}
	
	/**
	 * ~~ Pythagore rulez ~~
	 */
	function findGroupByDist(lat:Float, lng:Float,?limit=5){
		#if plugins
		var sql = 'select p.*,SQRT( POW(p.lat-$lat,2) + POW(p.lng-$lng,2) ) as dist from Place p, Hosting h ';
		sql += "where h.id=p.amapId and h.visible=1 and p.lat is not null ";		
		sql += 'order by dist asc LIMIT $limit';
		#else
		var sql = 'select p.*,SQRT( POW(p.lat-$lat,2) + POW(p.lng-$lng,2) ) as dist from Place p ';
		sql += "where p.lat is not null ";
		sql += 'order by dist asc LIMIT $limit';
		#end
		return db.Place.manager.unsafeObjects(sql, false);
	}
	
}