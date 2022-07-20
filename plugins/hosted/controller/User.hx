package hosted.controller;

import db.Operation.COrderInfos;
import pro.db.PUserCompany;
import tools.ObjectListTool;

class User extends sugoi.BaseController
{
    @admin @tpl("plugin/pro/hosted/user/default.mtt")
	public function doDefault(){

    }
	
	/**
	 *  search fo a user in the whole database
	 */
	@admin @tpl("plugin/pro/hosted/user/search.mtt")
	public function doSearch(args:{search:String}){
		
		var search = "%"+StringTools.trim(args.search)+"%";
		var users = db.User.manager.search( 
					($lastName.like(search) ||
					$lastName2.like(search) || 
					$email.like(search) ||
					$email2.like(search) ||
					$firstName.like(search) ||
					$firstName2.like(search)					
					), { orderBy:-id }, false);
		view.users = users;

	}

    /**
	 *  Display infos about a user
	 */
	@admin @tpl("plugin/pro/hosted/user/view.mtt")
	public function doView(u:db.User,?args:{?delete:Bool}){
		view.member = u;
		view.orders = db.UserOrder.manager.count($user==u || $user2==u);
		view.mangopayUserId = mangopay.db.MangopayUser.get(u);

		//vendors
		var vendors = [];
		for( uv in PUserCompany.manager.search($user ==u,false)){
			vendors.push(uv.company.vendor);
		}
		view.vendors = ObjectListTool.deduplicate(vendors);
	}
	
    /**
		extract group admins and coordinators
	**/
	@admin @tpl("plugin/pro/hosted/people.mtt")
	function doPeople(?type:String,?includeContractManagers:Bool) {

		var users = [];
		for ( g in db.Group.manager.all()) {
		
			var h = hosted.db.GroupStats.getOrCreate(g.id);
			if(!h.active) continue;

			if(type=="AMAP"){
				if(g.hasShopMode()) continue;
			}

			if (g.contact != null) {
				users.push(g.contact);
			}
			
			if(includeContractManagers){
				for ( c in g.getActiveContracts()) {
					if(c.contact!=null) users.push( c.contact );
				}
			}
			
		}
		view.users = users;
		
		if (app.params.exists("csv")) {
			sugoi.tools.Csv.printCsvDataFromObjects(users, ["email", "firstName", "lastName",/* "CLIENT",*/"zipCode","city"], "Clients-cagette");
		}
	}

	@admin
	function doDelete(user:db.User) {
		if (!app.user.isAdmin()){
			return;
		}

		try {
			service.BridgeService.call('/auth/delete-user/${user.id}');
		} catch (e: Dynamic) {
			Sys.println(e);
		}
	
		throw Redirect('/p/hosted/user');
	}
}