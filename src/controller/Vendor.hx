package controller;
import sugoi.form.Form;
import sugoi.tools.Utils;


class Vendor extends Controller
{

	public function new()
	{
		super();
		
		if (!app.user.isContractManager()) throw t._("Forbidden access");
		
	}
	
	/*@logged
	@tpl('vendor/default.mtt')
	function doDefault() {
		var browse:Int->Int->List<Dynamic>;
		
		//default display
		browse = function(index:Int, limit:Int) {
			return db.Vendor.manager.search($id > index && $amap==app.user.amap, { limit:limit, orderBy:-id }, false);
		}
		
		var count = db.Vendor.manager.count($amap==app.user.amap);
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.vendors = rb;
	}*/
	
	
	/*@tpl("vendor/view.mtt")
	function doView(vendor:db.Vendor) {
		view.vendor = vendor;
	}*/
	
	@tpl('form.mtt')
	function doEdit(vendor:db.Vendor) {
		
		var form = sugoi.form.Form.fromSpod(vendor);
		//form.removeElement( form.getElement("amapId") );
		
		if (form.isValid()) {
			form.toSpod(vendor); //update model
			vendor.update();
			throw Ok('/contractAdmin', t._("This supplier has been updated"));
		}
		
		view.form = form;
	}
	

	@tpl("form.mtt")
	public function doInsert() {
				
		var m = new db.Vendor();
		var form = sugoi.form.Form.fromSpod(m);
		//form.removeElement(form.getElement("amapId"));
		
		if (form.isValid()) {
			form.toSpod(m); //update model
			//m.amap = app.user.amap;
			m.insert();
			
			throw Ok('/contractAdmin/', t._("This supplier has been saved"));
		}
		
		view.form = form;
	}
	
	/*public function doDelete(v:db.Vendor) {
		if (!app.user.isAmapManager()) throw t._("Forbidden action");
		if (checkToken()) {
					
			if (db.Contract.manager.search($vendorId == v.id).length > 0) throw Error('/contractAdmin', t._("You cannot delete this supplier because some contracts (current or old) are referencing this supplier."));
			
			v.lock();
			v.delete();
			throw Ok("/contractAdmin", t._("Supplier deleted"));
		}
		
	}*/
	
	@tpl('vendor/addimage.mtt')
	function doAddImage(v:db.Vendor) {
		
		view.vendor = v;
		view.image = v.image;
		
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12); //12Mb
		
		if (request.exists("image")) {
			
			//Image
			var image = request.get("image");
			if (image != null && image.length > 0) {
				var img : sugoi.db.File = null;
				if ( Sys.systemName() == "Windows") {
					img = sugoi.db.File.create(request.get("image"), request.get("image_filename"));
				}else {
					img = sugoi.tools.UploadedImage.resizeAndStore(request.get("image"), request.get("image_filename"), 400, 400);	
				}
				
				v.lock();				
				if (v.image != null) {
					//efface ancienne
					v.image.lock();
					v.image.delete();
				}				
				v.image = img;
				v.update();
				throw Ok('/contractAdmin/', t._("Image updated"));
			}
		}
	}	
	
}