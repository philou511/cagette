package controller.api;
import haxe.Json;
import Common;
import service.Mapbox;

/**
 * Groups API
 * @author fbarbut
 */
class Group extends Controller
{
	/**
	 * 
	 */
	 public function doDefault(group:db.Group) {
		switch (sugoi.Web.getMethod()) {
			case "POST":
				if (!app.user.isAmapManager()) throw Error("/", t._("Access forbidden"));

				var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12); //12Mb
				
				// IMAGE
				if (request.exists("file")) {
					var image = request.get("file");

					if (image != null && image.length > 0) {
						var img = sugoi.db.File.createFromDataUrl(request.get("file"), request.get("filename"));
						group.lock();
						if (group.image != null) {
							//efface ancienne
							group.image.lock();
							group.image.delete();
						}				
						group.image = img;
						group.update();
					}
				}
				Sys.print(haxe.Json.stringify(group.infos()));
			default: Sys.print(haxe.Json.stringify({}));
		}
	}	


}