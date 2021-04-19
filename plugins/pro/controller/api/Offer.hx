package pro.controller.api;

import pro.db.POffer;
import Common;
using tools.ObjectListTool;

class Offer extends controller.Controller
{

	public function new() 
	{
		super();
	}
	
    function doImage(offer:POffer) {
		
		if (pro.db.CagettePro.getCurrentCagettePro().id != offer.product.company.id) {
			throw t._("Forbidden access");
		}
		
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12);
		
		if (request.exists("file")) {
			
			//Image
			var image = request.get("file");
			if (image != null && image.length > 0) {
				
				var img = sugoi.db.File.createFromDataUrl(request.get("file"), request.get("filename"));

				offer.lock();
				if (offer.image != null) {
					offer.image.lock();
					offer.image.delete();
				}				
				offer.image = img;
				offer.update();
				Sys.print(haxe.Json.stringify({success:true}));
			}
		}else{
			Sys.print(haxe.Json.stringify({success:false}));
		}
	}	
	
}