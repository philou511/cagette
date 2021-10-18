package pro.controller;

import crm.CrmService;
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

	/**
		need to login as a standard user
	**/
	@tpl("plugin/pro/signup/default.mtt")
	public function doDefault(/*key:String*/){
		/*if(key!="cak2j6d6e8i9u7q45p6o54iden") {
			throw Error("/","Lien invalide");
		}*/
			
		if(app.user!=null){
			// TODO : pass groupId if there is one
			throw Redirect("/p/pro/signup/discovery");
		}
	}

	@logged
	@tpl('plugin/pro/signup/discovery.mtt')
	public function doDiscovery(?group:db.Group){
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
		if (group!=null) {
			view.groupName = group.name;
			view.groupId = group.id;
		}

		// TODO :
		// view.invitationSenderId = 
	}

	/*@admin
	function doTest(){
		var vendor = db.Vendor.manager.get(4997,false);

		CrmService.syncToHubspot(vendor);
		CrmService.syncToSiB(app.user,true,"vendor_register");
	}*/
	
	
}