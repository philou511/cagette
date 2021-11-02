package pro.controller;

import db.Vendor;
import form.CagetteForm;
import haxe.Json;
import pro.db.PUserCompany;
import pro.db.VendorStats;
import service.VendorService;
import sugoi.Web;
import sugoi.apis.linux.Curl;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.CheckboxGroup;
import sugoi.form.elements.Html;
import sugoi.form.elements.StringInput;
import sugoi.form.elements.StringSelect;
import sugoi.tools.TransactionWrappedTask;

class Signup extends controller.Controller
{

	@tpl('plugin/pro/signup/discovery.mtt')
	public function doDiscovery(?group:db.Group, ?invitationSender:db.User){
		if (group!=null) {
			view.groupName = group.name;
			view.groupId = group.id;
		}
		
		if(app.user==null) {
			view.userName = "";
			view.sid = App.current.session.sid;
			return;
		}
		
		//checks
		//has access to a cpro
		var uc = PUserCompany.manager.search($user ==app.user);
		if( uc.length>0){
			throw Error("/","Vous avez déjà accès à un compte Cagette Pro : "+uc.map(c -> return c.company.vendor.name).join(', '));
		}

		//has same mail than a vendor
		var vendor : db.Vendor = Vendor.manager.select($email != null && ($email == app.user.email || $email == app.user.email2),true);
		if( vendor!=null ){

			//is this vendor cpro
			if(vendor.getCpro()!=null){
				throw Error("/","Vous avez déjà accès à un compte Cagette Pro");
			}

			view.vendorId = vendor.id;
		}
		
		view.userName = app.user.getName();
		
		if (invitationSender!=null) {
			view.invitationSenderId = invitationSender.id;
		}
	}

	/*@admin
	function doTest(){
		var vendor = db.Vendor.manager.get(4997,false);

		CrmService.syncToHubspot(vendor);
		CrmService.syncToSiB(app.user,true,"vendor_register");
	}*/
	
	
}