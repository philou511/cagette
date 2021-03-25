package pro.controller.api;

import Common;
using tools.ObjectListTool;

class Product extends controller.Controller
{

	public function new() 
	{
		super();
	}
	
    function doImage(product:pro.db.PProduct) {
		
		if (pro.db.CagettePro.getCurrentCagettePro().id != product.company.id) {
			throw t._("Forbidden access");
		}
		
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12);
		
		if (request.exists("file")) {
			
			//Image
			var image = request.get("file");
			if (image != null && image.length > 0) {
				
				var img = sugoi.db.File.createFromDataUrl(request.get("file"), request.get("filename"));

				product.lock();
				if (product.image != null) {
					product.image.lock();
					product.image.delete();
				}				
				product.image = img;
				product.update();

				//if offers are in catalogs, update the lastUpdate field of the catalog (for sync purpose)
				var offersId = Lambda.map(product.getOffers(false), function(o) return o.id);
				var coffers = pro.db.PCatalogOffer.manager.search($offerId in offersId, false);
				var catalogs = pro.db.PCatalog.manager.search( $id in Lambda.map(coffers, function(x) return x.catalog.id) , true);
				for ( c in catalogs) c.toSync();		

				Sys.print(haxe.Json.stringify({success:true}));
			}
		}else{
			Sys.print(haxe.Json.stringify({success:false}));
		}
	}	
	
}