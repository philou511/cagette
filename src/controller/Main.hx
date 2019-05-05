package controller;
import db.Distribution;
import db.UserContract;
import haxe.Json;
import haxe.web.Dispatch;
import sugoi.form.elements.StringInput;
import sugoi.tools.ResultsBrowser;
import Common;
import tools.ArrayTool;

class Main extends Controller {
	
	function doDefault(?permalink:String){

		if(permalink==null || permalink=="") throw Redirect("/home");
		//if permalink is an ID , could use it for group selection ? app.cagette.net/1/contractAdmin ...
		var p = sugoi.db.Permalink.get(permalink);
		if(p==null) throw Error("/home",t._("The link \"::link::\" does not exists.",{link:permalink}));

		app.event(Permalink({link:p.link,entityType:p.entityType,entityId:p.entityId}));
	}
	
	/**
	 * public pages 
	 */
	function doGroup(d:haxe.web.Dispatch){
		d.dispatch(new controller.Group());
	}

	/**
	Group homepage
	**/
	@tpl("home.mtt")
	function doHome() {
		view.category = 'home';
		
		var group = app.getCurrentGroup();		
		if ( app.user!=null && group == null) {			
			throw Redirect("/user/choose");
		}else if (app.user == null && (group==null || group.regOption!=db.Amap.RegOption.Open) ) {
			throw Redirect("/user/login");
		}

		view.amap = group;
		
		//contract with open orders
		if(!group.hasShopMode()){
			var openContracts = Lambda.filter(group.getActiveContracts(), function(c) return c.isUserOrderAvailable());
			view.openContracts = openContracts;
		}
		
		//register to become "distributor"
		//view.contractsWithDistributors = app.user==null ? [] : Lambda.filter(app.user.amap.getActiveContracts(), function(c) return c.distributorNum > 0);
		
		//freshly created group
		view.newGroup = app.session.data.newGroup == true;

		var n = Date.now();
		var now = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
		var in3Month = DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30 * 3);

		var distribs = db.MultiDistrib.getFromTimeRange(group,now,in3Month);
		//special case for farmers with one distrib , far in future.
		if(distribs.length==0) distribs = db.MultiDistrib.getFromTimeRange(group,now,DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30 * 12));
		view.distribs = distribs;

		//Map for each multidistrib the volunteer role the current user is assigned to
		var userRoleByMultidistribId = new Map<Int, db.VolunteerRole>();
		for ( multidistrib in distribs ) {

			if (multidistrib.volunteerRolesIds != null) {

				var existingVolunteer = db.Volunteer.manager.search( $user == app.user && $multiDistrib == multidistrib ).first();
				if ( existingVolunteer != null ) {
					
					userRoleByMultidistribId[multidistrib.id] = existingVolunteer.volunteerRole;
				}								
			}
		}
		view.userRoleByMultidistribId = userRoleByMultidistribId;

		//Map for each multidistrib the Volunteer Roles needed to be filled by volunteer
		var unfilledRolesByMultidistribId = new Map<Int, Array<db.VolunteerRole>>();
		for ( multidistrib in distribs ) {

			if (multidistrib.volunteerRolesIds != null) {

				var multidistribRoleIds = multidistrib.volunteerRolesIds.split(",");

				for ( roleId in multidistribRoleIds ) {

					var volunteerRole: db.VolunteerRole = db.VolunteerRole.manager.get(Std.parseInt(roleId));
					var existingVolunteer = db.Volunteer.manager.search( $multiDistrib == multidistrib && $volunteerRole == volunteerRole ).first();

					if ( existingVolunteer == null ) {

						if ( unfilledRolesByMultidistribId[multidistrib.id] == null ) {

							unfilledRolesByMultidistribId[multidistrib.id] = new Array<db.VolunteerRole>();							
						}				
						
						unfilledRolesByMultidistribId[multidistrib.id].push(volunteerRole);
					}
				}				
			}
		}
		view.unfilledRolesByMultidistribId = unfilledRolesByMultidistribId;
		
		//view functions
		view.getWhosTurn = function(orderId:Int, distrib:Distribution) {
			return db.UserContract.manager.get(orderId, false).getWhosTurn(distrib);
		}
		
		//register to group without ordering block
		var hasOneOpenDistrib = false;
		for( md in distribs){
			if(md.isActive()) {
				hasOneOpenDistrib = true;
				break;
			}
		}

		var isMember = app.user==null ? false : app.user.isMemberOf(group);
		var registerWithoutOrdering = ( !isMember && group.regOption==db.Amap.RegOption.Open && !hasOneOpenDistrib );
		view.registerWithoutOrdering = registerWithoutOrdering;
		if(registerWithoutOrdering) service.UserService.prepareLoginBoxOptions(view,group);		

		//event for additionnal blocks on home page
		var e = Blocks([], "home");
		app.event(e);
		view.blocks = e.getParameters()[0];

		//message if phone is required
		if(app.user!=null && group.flags.has(db.Amap.AmapFlags.PhoneRequired) && app.user.phone==null){
			app.session.addMessage(t._("Members of this group should provide a phone number. <a href='/account/edit'>Please click here to update your account</a>."),true);
		}
		//message if address is required
		if(app.user!=null && group.flags.has(db.Amap.AmapFlags.AddressRequired) && app.user.city==null){
			app.session.addMessage(t._("Members of this group should provide an address. <a href='/account/edit'>Please click here to update your account</a>."),true);
		}

		//Delete demo contracts
		if(checkToken() && app.params.get('action')=='deleteDemoContracts'){
			var contracts = app.getCurrentGroup().deleteDemoContracts();
			if(contracts.length>0 ) throw Ok("/","Contrats suivants effacés : "+contracts.map(function(c) return c.name).join(", "));
		}
	}
	
	//login and stuff
	function doUser(d:Dispatch) {
		d.dispatch(new controller.User());
	}
	
	function doCron(d:Dispatch) {
		d.dispatch(new controller.Cron());
	}
	
	/**
	 *  JSON REST API Entry point
	 */
	function doApi(d:Dispatch) {
		sugoi.Web.setHeader("Content-Type","application/json");
		try {

			d.dispatch(new controller.Api());

		}catch (e:tink.core.Error){

			//manage tink Errors (service errors)
			sugoi.Web.setReturnCode(e.code);
			Sys.print(Json.stringify( {error:{code:e.code,message:e.message,stack:e.exceptionStack}} ));
			
		}catch (e:Dynamic){

			//manage other errors			
			sugoi.Web.setReturnCode(500);			
			var stack = if ( App.config.DEBUG ) haxe.CallStack.toString(haxe.CallStack.exceptionStack()) else "";
			App.current.logError(e, stack);
			Sys.print(Json.stringify( {error:{code:500,message : Std.string(e), stack:stack }} ));
		}
		
	}
	
	@tpl("cssDemo.mtt")
	function doCssdemo() {
		view.category = 'home';
	}

	@tpl("css.mtt")
	function doCssdemo2(){


	}
	
	@tpl("form.mtt")
	function doInstall(d:Dispatch) {
		d.dispatch(new controller.Install());
	}
	

	function doP(d:Dispatch) {
		
		/*
		 * Invalid array access
Stack (ADMIN|DEBUG)

Called from C:\HaxeToolkit\haxe\std/haxe/web/Dispatch.hx line 463
Called from controller/Main.hx line 117
		 * 
		var plugin = d.parts.shift();
		for ( p in App.plugins) {
			var n = Type.getClassName(Type.getClass(p)).toLowerCase();
			n = n.split(".").pop();
			if (plugin == n) {
				d.dispatch( p.getController() );
				return;
			}
		}
		
		throw Error("/","Plugin '"+plugin+"' introuvable.");
		*/
		
		d.dispatch(new controller.Plugin());
	}
	

	@logged
	function doMember(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Member());
	}
	
	@logged
	function doStats(d:Dispatch) {
		view.category = 'stats';
		d.dispatch(new Stats());
	}
	
	@logged
	function doAccount(d:Dispatch) {
		view.category = 'account';
		d.dispatch(new controller.Account());
	}

	@logged
	function doVendor(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Vendor());
	}
	
	@logged
	function doPlace(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Place());
	}
	
	@logged
	function doTransaction(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Transaction());
	}
	
	@logged
	function doDistribution(d:Dispatch) {
		view.category = 'distribution';
		d.dispatch(new controller.Distribution());
	}
	
	@logged
	function doMembership(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Membership());
	}
	
	function doShop(d:Dispatch) {
		view.category = 'shop';
		d.dispatch(new controller.Shop());
	}

	@tpl('shop/default2.mtt')
	function doShop2(place:db.Place, date:String) {
		view.category = 'shop';
		view.place = place;
		view.date = date;
		view.rights = app.user!=null ? haxe.Serializer.run(app.user.getRights()) : null;
	}
	
	@logged
	function doProduct(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Product());
	}
	
	@logged
	function doAmap(d:Dispatch) {
		view.category = 'amap';
		d.dispatch(new controller.Amap());
	}
	
	@logged
	function doContract(d:Dispatch) {
		view.category = 'contract';
		d.dispatch(new Contract());
	}
	
	@logged
	function doContractAdmin(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new ContractAdmin());
	}
	
	@logged
	function doMessages(d:Dispatch) {
		view.category = 'messages';
		d.dispatch(new Messages());
	}
	
	@logged
	function doAmapadmin(d:Dispatch) {
		view.category = 'amapadmin';
		d.dispatch(new AmapAdmin());
	}
	
	@logged
	function doValidate(date:Date, place:db.Place, user:db.User, d:haxe.web.Dispatch){
		
		var v = new controller.Validate();
		v.date = date;
		v.place = place;
		v.user = user;		
		d.dispatch(v);
	}
	
	@admin
	function doAdmin(d:Dispatch) {
		d.dispatch(new controller.admin.Admin());
	}
	
	@admin
	function doDb(d:Dispatch) {
		d.parts = []; //disable haxe.web.Dispatch
		sys.db.Admin.handler();
	}
	
	
}
