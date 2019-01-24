package service;

class VendorService{

	public function new(){

	}


	/**
		Get or create+link user account related to this vendor.
	**/
	public static function getOrCreateRelatedUser(vendor:db.Vendor){
		if(vendor.user!=null){
			return vendor.user;
		}else{
			var u = service.UserService.getOrCreate(vendor.name,null,vendor.email);
			vendor.lock();
			vendor.user = u;
			vendor.update();
			return u;
		}
	}


	public static function getVendorsFromUser(user:db.User):Array<db.Vendor>{
		
		//get vendors linked to this account
		var vendors = Lambda.array( db.Vendor.manager.search($user==user,false) );
		
		#if plugins
		var vendors2 = Lambda.array(Lambda.map(pro.db.PUserCompany.getCompanies(user),function(c) return c.vendor));
		vendors = vendors2.concat(vendors);
		vendors = tools.ObjectListTool.deduplicate(vendors);
		#end
		return vendors;

	}


}