package pro.controller.api;

class Company extends controller.Controller {

	public function doDefault(company:pro.db.CagettePro) {
    	switch (sugoi.Web.getMethod()) {
			case "POST":
        	// TODO : not REST
			if (company.id != pro.db.CagettePro.getCurrentCagettePro().id) {
			throw t._("Forbidden access");
			}

			var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12); //12Mb

			if (
				request.exists("logo") || 
				request.exists("portrait") ||
				request.exists("banner") ||
				request.exists("farm1") ||
				request.exists("farm2") ||
				request.exists("farm3") ||
				request.exists("farm4")
			){
				if (request.exists("logo")) {
					var img = updateImage(company, "logo", request.get("logo"), request.get("filename"));

					company.vendor.lock();
					company.vendor.image = img;
					company.vendor.update();	
				}

				if (request.exists("portrait")) {
					updateImage(company, "portrait", request.get("portrait"), request.get("filename"));
				}

				if (request.exists("banner")) {
					updateImage(company, "banner", request.get("banner"), request.get("filename"));
				}

				if (request.exists("farm1")) {
					updateImage(company, "farm1", request.get("farm1"), request.get("filename"));
				}
				if (request.exists("farm2")) {
					updateImage(company, "farm2", request.get("farm2"), request.get("filename"));
				}
				if (request.exists("farm3")) {
					updateImage(company, "farm3", request.get("farm3"), request.get("filename"));
				}
				if (request.exists("farm4")) {
					updateImage(company, "farm4", request.get("farm4"), request.get("filename"));
				}
			}
        
			Sys.print(haxe.Json.stringify(company.infos()));
			
			default: Sys.print(haxe.Json.stringify({}));
		}
  	}

  public function doAddVendorImage(v:db.Vendor) {
    switch (sugoi.Web.getMethod()) {
			case "POST":
        var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12); //12Mb
        if (request.exists("logo")) {
          var img = sugoi.db.File.createFromDataUrl(request.get("logo"));
          v.lock();
          v.image = img;
          v.update();
        }
        return Sys.print(haxe.Json.stringify({ message: "success" }));
      default: Sys.print(haxe.Json.stringify({ message: "fail" }));
    }
  }


	private function updateImage(company:pro.db.CagettePro, type: String, imageData: String, ?filename: String = "", ?forceToCreate: Bool = false) {
    	var entityFile = sugoi.db.EntityFile.getByEntity("vendor", company.vendor.id, type)[0];
    	var img = sugoi.db.File.createFromDataUrl(imageData, filename);
    
    	if (entityFile == null || forceToCreate) {					
      		sugoi.db.EntityFile.make("vendor", company.vendor.id, type, img);
    	} else {
      		entityFile.lock();
      		entityFile.file = img;
      		entityFile.update();
    	}

    	return img;
  	}
}