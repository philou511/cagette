package hosted.controller;
import Common;
import db.Operation;
import hosted.HostedPlugIn;
import hosted.db.GroupStats;
import pro.db.VendorStats;
import service.BridgeService;
import sugoi.form.elements.StringInput;
import tools.Timeframe;

/**
 * Main controller of HOSTED plugin
 */
class Main extends controller.Controller
{

	public function new() 
	{
		super();
		view.category = "admin";

		//trigger a "Nav" event
		var nav = new Array<Link>();
		var e = Nav(nav,"admin");
		app.event(e);
		view.nav = e.getParameters()[0];
	}
	
	@admin @tpl("plugin/pro/hosted/group.mtt")
	public function doGroup(group:db.Group) {
		
		view.group = group;
		var mgpConf = mangopay.MangopayPlugin.getGroupConfig(group);
		if(mgpConf!=null){
			view.debugLegalUserModule = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(haxe.Json.stringify({moduleName:"mangopay-legal-user-module",props:{"mangopayUserId":mgpConf.legalUser.mangopayUserId}})));
		}
		view.mangopay = mgpConf;

		if( app.params.get("roleIds")=="1" ){
			for( md in db.MultiDistrib.manager.search($distribStartDate > Date.now() && $group==group,true) ){
				var rids = [];
				for( d in md.getDistributions() ){
					for( role in service.VolunteerService.getRolesFromContract(d.catalog) ){
						rids.push(role.id);
					}
				}
				md.lock();
				md.volunteerRolesIds = rids.join(",");
				md.update();
			}
		}

		view.vendors = group.getActiveVendors();
		var gs = GroupStats.getOrCreate(group.id,true);
		gs.updateStats();
		view.groupStats = gs; 
		view.getVendorStats = function(v:db.Vendor){
			return VendorStats.getOrCreate(v);
		}
		
		checkToken();
	}

	/*@admin
	public function doDebugOps(group:db.Group) {

		//essaye de trouver les ops de commande en double (faille dans findVOrderOperation )
		var basketIds = [];
		for( m in group.getMembers()){
			for (op in db.Operation.getOperations(m, group) ){

				if(op.type == VOrder){
					trace(op);
					var i : VOrderInfos = op.getOrderInfos();
					trace(i.basketId);

					if(Lambda.has(basketIds,i.basketId)) trace("DOUBLE BASKET ID "+i.basketId);

					basketIds.push(i.basketId);
				}

			}
		} 

	}*/	

	@admin
	function doResetBalances(g:db.Group){
		for ( m in g.getMembers()){

			var ua = db.UserGroup.get(m, g);
			var balance = ua.balance;
			if(balance<0 || balance>0){
				Sys.print('update ${m.getName()} : balance : $balance, fix : ${0-balance}<br/>');
				var op = service.PaymentService.makePaymentOperation(m,g,payment.Cash.TYPE,0-balance,"Correction de solde");
				//fix op
				op.pending = false;
				op.amount = 0-balance;
				op.update();
				Sys.print(op+"<br>");
				service.PaymentService.updateUserBalance(m,g);
			}
		}
		// throw Ok("/p/hosted/group/"+g.id,"Soldes corrigés");
	}

	public function doSyncToHubspot(group:db.Group) {

		for( vendor in group.getActiveVendors()){
			BridgeService.syncVendorToHubspot(vendor);
		}
		
		throw Ok("/p/hosted/group/"+group.id,"Synchronisation hubspot faite");
	}

	function doDeleteDemoContracts(a:db.Group){
		var contracts = a.deleteDemoContracts();
		throw Ok("/p/hosted/group/"+a.id,"Contrats suivants effacés : "+contracts.map(function(c) return c.name).join(", "));
	}
	
	function doDisableNotifs(g:db.Group){
		for ( m in g.getMembers()){
			m.lock();
			m.flags.unset(db.User.UserFlags.HasEmailNotif24h);
			m.flags.unset(db.User.UserFlags.HasEmailNotif4h);
			m.update();
		}
		throw Ok("/p/hosted/group/"+g.id, "Notifications désactivées pour tous les membres de ce groupe");
	}

	function doEnableNotifs(g:db.Group){
		for ( m in g.getMembers()){
			m.lock();
			m.flags.set(db.User.UserFlags.HasEmailNotif24h);
			// m.flags.unset(db.User.UserFlags.HasEmailNotif4h);
			m.flags.set(db.User.UserFlags.HasEmailNotifOuverture);
			m.update();
		}
		throw Ok("/p/hosted/group/"+g.id, "Notifications activées pour tous les membres de ce groupe");
	}
	
	public function doCacheDebug(){
		Sys.println("<h2>pending carts</h2>");
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'lwec-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		Sys.println("<h2>finalize card</h2>");
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'debug-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		for ( c in sugoi.db.Cache.manager.unsafeObjects("select * from Cache where name LIKE 'finalizeCard-%' ", false)){
			Sys.println("<b>"+c.name+"</b>");
			Sys.println("<pre>"+haxe.Unserializer.run(c.value)+"</pre>");
		}
		
		
	}
	
	/**
	 * view a transaction detail in a pop-in window 
	 * @param	t
	 */
	@tpl("transaction/view.mtt")
	public function doOperation(op:db.Operation){
		view.op = op ;
	}
	
	@admin public function doAddMe(g:db.Group){
		
		var ua = app.user.makeMemberOf(g);
		throw Ok("/user/choose?group="+g.id, "Vous faites maintenant partie de " + ua.group.name);
	}
	
	@admin public function doDeleteGroup(a:db.Group) {
	
		if (checkToken()) {
			a.lock();
			a.delete();
			throw Ok("/p/hosted/","Groupe effacé");
		}
	}
	
	
	@admin
	function doGeocode(group:db.Group){		
		/*var coords = hosted.HostedPlugIn.geocodeGroup(group);		
		throw Ok("/p/hosted/group/"+group.id,"Geocoding OK "+coords);*/
	}
	
	@admin
	function doRefresh(group:db.Group){
		
		var h = hosted.db.GroupStats.getOrCreate(group.id, true);
		var o = h.updateStats();		
		var str = "ACTIF : " + o.active+", VISIBLE : " + o.visible+" ( CagetteNetwork : " + o.cagetteNetwork + ", distributions : " + o.distributions + ", geoloc : " + o.geoloc + ", MembersNum : " + o.members+" )";		
		throw Ok("/p/hosted/group/"+group.id,"Visible sur la carte : "+str);
	}
	
	function doUser(d:haxe.web.Dispatch) {
		d.dispatch(new hosted.controller.User());
	}

	/**
	 * infos sur le membre d'un groupe
	 */
	@admin @tpl("plugin/pro/hosted/usergroup.mtt")
	public function doUserGroup(u:db.User, g:db.Group){
		var ua = db.UserGroup.get(u, g, false);
		
		view.member = ua.user;
		view.ua = ua;
		view.operations = db.Operation.getLastOperations(u, g);

		var timeframe = new Timeframe( DateTools.delta(Date.now() ,-1000.0*60*60*24*30.5*3) , DateTools.delta(Date.now() , 1000.0*60*60*24*30.5*3) );
		var mds = db.MultiDistrib.getFromTimeRange(g,timeframe.from,timeframe.to);
		view.mds = mds;
		view.timeframe = timeframe;
	}

	/**
	 * Stats sur les producteurs 
	 */
	@admin
	public function doVendors(){
		Sys.print("<pre>");
		Sys.println("id\tname\tcount\tstatus\tactive");


		for( v in sys.db.Manager.cnx.request("SELECT MAX(v.id) as id, count(v.id) as cnt,v.name
			FROM Vendor v
			group by name
			order by cnt desc"))	{

				var from = DateTools.delta(Date.now(), 1000.0*60*60*24*-30.5);
				var to = DateTools.delta(Date.now(), 1000.0*60*60*24*30.5*6);

				//cpro, invité ou gratuit ?
				var status = null;			
				var vendor = db.Vendor.manager.get(v.id);
				var cids = Lambda.map(vendor.getActiveContracts(),function(x) return x.id);
				var active = db.Distribution.manager.count(($catalogId in cids) && $date >= from && $date <= to) > 0;
				var contracts = db.Catalog.manager.search($vendor==vendor,false);
				for( c in contracts){
					var rc = connector.db.RemoteCatalog.getFromContract(c);
					if(rc!=null){
						status = "cpro";
						active = false;
						var company = rc.getCatalog().company;
						for( cata in company.getCatalogs()){
							if(active) break;
							for( rc in connector.db.RemoteCatalog.getFromCatalog(cata)){
								var c = rc.getContract();
								active = db.Distribution.manager.count($catalogId==c.id && $date >= from && $date <= to) > 0;
								//Sys.println("------ catalogue "+cata.name+": "+c.name+" de "+c.amap.name+" = "+active);
								if(active) break;
							}
						}
						break;
					} else if(vendor.email==c.contact.email){
						status = "gratuit";
						break;
					} else if(c.group.groupType==db.Group.GroupType.FarmShop || c.group.groupType==db.Group.GroupType.ProducerDrive){
						status = "gratuit";
						break;
					}
				}

				if(status==null) status = "invité";

				Sys.println(""+v.id+"\t"+v.name+"\t"+v.cnt+"\t"+status+"\t"+(active?"1":"0"));
		}
		Sys.print("</pre>");

	}

	@admin
	function doCourse(d:haxe.web.Dispatch){
		if (App.current.getSettings().noCourse!=true) {
			d.dispatch(new hosted.controller.Course());
		}
	}

	@admin
	function doSeo(d:haxe.web.Dispatch){
		d.dispatch(new hosted.controller.Seo());
	}
	
}