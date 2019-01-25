package service;

class VendorService{

	public function new(){}

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

	/**
		Get vendors linked to a user account
	**/
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

	/**
		Send an email to the vendor
	**/
	public static function sendEmailOnAccountCreation(vendor:db.Vendor,source:db.User,group:db.Amap){
		
		// the vendor and the user is the same person
		if(vendor.email==source.email) return;
		if(vendor.user==null) throw "Vendor should have a user";
		if(group==null) throw "a group should be provided";

		#if plugins
		var k = sugoi.db.Session.generateId();
		sugoi.db.Cache.set("validation" + k, vendor.user.id, 60 * 60 * 24 * 30); //expire in 1 month
		
		var e = new sugoi.mail.Mail();
		e.setSubject("Vous êtes référencé sur Cagette.net !");
		e.addRecipient(vendor.email,vendor.name);
		e.setSender(App.config.get("default_email"),"Cagette.net");			
		
		var html = App.current.processTemplate("mail/vendorInvitation.mtt", { 
			source:source,
			sourceGroup:group,
			vendor:vendor,
			k:k 			
		} );		
		e.setHtmlBody(html);
		
		App.sendMail(e);	
		#end
		
	}


}