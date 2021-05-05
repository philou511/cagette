package controller;
import db.MultiDistrib;
import db.Distribution;
import db.UserOrder;
import haxe.Json;
import haxe.web.Dispatch;
import sugoi.form.elements.StringInput;
import sugoi.tools.ResultsBrowser;
import Common;
import tools.ArrayTool;

class Main extends Controller {

	public function new(){
		super();

		//init group breadcrumb
		var group = App.current.getCurrentGroup();
		if(group!=null)
			addBc("g"+group.id, "Groupe Cagette : "+group.name, "/home");

	}

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

	@tpl("home.mtt")
	function doHome() {

		addBc("home","Commandes","/home");

		var group = app.getCurrentGroup();		
		if ( app.user!=null && group == null) {			
			throw Redirect("/user/choose");
		}else if (app.user == null && (group==null || group.regOption!=db.Group.RegOption.Open) ) {
			throw Redirect("/user/login");
		}

		group.checkIsolate();

		// if(app.user!=null && app.user.isGroupManager() && group.hasShopMode()  && !group.betaFlags.has(db.Group.BetaFlags.ShopV2) ){
		// 	app.session.addMessage("Attention, l'ancienne boutique et les catégories personnalisées disparaîtront le lundi 3 Mai 2021, pensez à vous préparer avant le jour J.<br/><a href='https://wiki.cagette.net/admin:5april' target='_blank'>Cliquez-ici pour plus d'informations</a>",true);
		// }

		view.amap = group;
		
		//has unconfirmed basket ?
		service.OrderService.checkTmpBasket(app.user,app.getCurrentGroup());

		//contract not ended with UserCanOrder flag
		if(!group.hasShopMode()){
			view.openContracts = group.getActiveContracts().filter( (c)-> c.hasOpenOrders() );
		}
		
		//freshly created group
		view.newGroup = app.session.data.newGroup == true;
		
		var n = Date.now();
		var now = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
		var in1Month = DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30);
		var timeframe = new tools.Timeframe(now,in1Month);

		var distribs = db.MultiDistrib.getFromTimeRange(group,timeframe.from,timeframe.to);

		//special case : only one distrib , far in future.
		if(distribs.length==0) {
			timeframe = new tools.Timeframe(now,DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30 * 12));
			distribs = db.MultiDistrib.getFromTimeRange(group,timeframe.from,timeframe.to);
		}

		view.timeframe = timeframe;
		view.distribs = distribs;

		//view functions
		view.getWhosTurn = function(orderId:Int, distrib:Distribution) {
			return db.UserOrder.manager.get(orderId, false).getWhosTurn(distrib);
		}
		
		//register to group without ordering block
		var isMemberOfGroup = app.user==null ? false : app.user.isMemberOf(group);
		var registerWithoutOrdering = ( !isMemberOfGroup && group.regOption==db.Group.RegOption.Open );
		view.registerWithoutOrdering = registerWithoutOrdering;
		if(registerWithoutOrdering) service.UserService.prepareLoginBoxOptions(view,group);		

		//event for additionnal blocks on home page
		var e = Blocks([], "home");
		app.event(e);
		view.blocks = e.getParameters()[0];

		//message if phone is required
		if(app.user!=null && group.flags.has(db.Group.GroupFlags.PhoneRequired) && app.user.phone==null){
			app.session.addMessage(t._("Members of this group should provide a phone number. <a href='/account/edit'>Please click here to update your account</a>."),true);
		}
		//message if address is required
		if(app.user!=null && group.flags.has(db.Group.GroupFlags.AddressRequired) && app.user.city==null){
			app.session.addMessage(t._("Members of this group should provide an address. <a href='/account/edit'>Please click here to update your account</a>."),true);
		}

		//Delete demo contracts
		if(checkToken() && app.params.get('action')=='deleteDemoContracts'){
			var contracts = app.getCurrentGroup().deleteDemoContracts();
			if(contracts.length>0 ) throw Ok("/","Contrats suivants effacés : "+contracts.map(function(c) return c.name).join(", "));
		}
		
		view.timeSlotService = function(d:db.MultiDistrib){
			return new service.TimeSlotsService(d);
		}

		view.visibleDocuments = group.getVisibleDocuments( isMemberOfGroup );

	}
	
	//login and stuff
	function doUser(d:Dispatch) {
		// addBc("user","Membres","/user");
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
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			App.current.logError(e, stack);
			Sys.print(Json.stringify( {error:{code:500,message : Std.string(e), stack: stack }} ));
		}
		
	}
	
	@tpl("cssDemo.mtt")
	function doCssdemo() {
		//debug stringmap haxe4
		var users = new Map<String,String>();
		users["bob"] = "is a nice fellow";
		view.users = users;
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
		addBc("member","Membres","/member");
		d.dispatch(new controller.Member());
	}
	
	function doAccount(d:Dispatch) {
		addBc("account","Mon compte","/account");
		d.dispatch(new controller.Account());
	}

	@logged
	function doVendor(d:Dispatch) {
		addBc("contractAdmin","Producteur","/contractAdmin");
		d.dispatch(new controller.Vendor());
	}

	/**
		update without auth
	**/
	@tpl('form.mtt')
	function doVendorNoAuthEdit(vendor:db.Vendor,key:String) {
		
	
		if(key!=haxe.crypto.Md5.encode(App.config.KEY+"_updateWithoutAuth_"+vendor.id)){
			throw Error("/","URL invalide");
		}
		

		var form = service.VendorService.getForm(vendor);
		
		if (form.isValid()){
			vendor.lock();
			try{
				vendor = service.VendorService.update(vendor,form.getDatasAsObject());
			}catch(e:tink.core.Error){
				throw Error(sugoi.Web.getURI(),e.message);
			}			
			vendor.update();		
			throw Ok(sugoi.Web.getURI(), "Merci, votre compte producteur a été mis à jour.");
		}
		view.title = "Mettre à jour \""+vendor.name+"\"";
		view.form = form;
	}
	
	@logged
	function doPlace(d:Dispatch) {
		d.dispatch(new controller.Place());
	}
	
	function doTransaction(d:Dispatch) {
		addBc("shop","Boutique","/shop");
		d.dispatch(new controller.Transaction());
	}
	
	@logged
	function doDistribution(d:Dispatch) {
		addBc("distribution","Distributions","/distribution");
		d.dispatch(new controller.Distribution());
	}
	
	function doShop(d:Dispatch) {
		addBc("shop","Boutique","/shop");
		d.dispatch(new controller.Shop());
	}

	@tpl('shop/default.mtt')
	function doShop2(md:db.MultiDistrib,?args:{continueShopping:Bool}) {
		throw  Redirect("/shop/"+md.id+"?continueShopping="+(args!=null?args.continueShopping:false));

		// if( app.getCurrentGroup()==null || app.getCurrentGroup().id!=md.getGroup().id){
		// 	throw  Redirect("/group/"+md.getGroup().id);
		// }
		// if(args!=null){
		// 	if(!args.continueShopping){
		// 		service.OrderService.checkTmpBasket(app.user,app.getCurrentGroup());
		// 	}
		// }
		// view.category = 'shop';
		// view.md = md;
		// view.tmpBasketId = app.session.data.tmpBasketId;
	}
	
	@logged
	function doProduct(d:Dispatch) {
		d.dispatch(new controller.Product());
	}
	
	@logged
	function doAmap(d:Dispatch) {
		addBc("amap","Producteurs","/amap");
		d.dispatch(new controller.Amap());
	}
	
	
	function doContract(d:Dispatch) {
		addBc("contract","Catalogues","/contractAdmin");
		d.dispatch(new Contract());
	}
	
	@logged
	function doContractAdmin(d:Dispatch) {
		addBc("contract","Catalogues","/contractAdmin");
		d.dispatch(new ContractAdmin());
	}

	@logged
	function doDocuments( dispatch : Dispatch ) {

		dispatch.dispatch( new Documents() );
	}

	@logged
	function doSubscriptions( dispatch : Dispatch ) {

		dispatch.dispatch( new Subscriptions() );
	}
	 
	@logged
	function doMessages(d:Dispatch) {
		addBc("messages","Messagerie","/messages");
		d.dispatch(new Messages());
	}
	
	@logged
	function doAmapadmin(d:Dispatch) {
		addBc("amapadmin","Paramètres","/amapadmin");
		d.dispatch(new AmapAdmin());
	}
	
	@logged
	function doValidate(multiDistrib:db.MultiDistrib,user:db.User,d:haxe.web.Dispatch){
		
		var v = new controller.Validate();
		v.multiDistrib = multiDistrib;
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
		sys.db.admin.Admin.handler();
	}

	@admin
	function doDebug(d:Dispatch) {
		d.dispatch(new controller.Debug());
	}
	
	//CGU
	public function doCgu() {
		throw Redirect("https://www.cagette.net/wp-content/uploads/2020/11/cgu-.pdf");
	}

	//CGV
	public function doCgv() {
		throw Redirect("https://www.cagette.net/wp-content/uploads/2020/11/cgv.pdf");
	}

	//CGU MGP
	public function doMgp() {
		throw Redirect("https://www.cagette.net/wp-content/uploads/2019/03/psp_mangopay_fr.pdf");
	}

	//charte
	public function doCharte() {
		throw Redirect("https://www.cagette.net/charte-producteurs/");
	}


	public function doPing() {
		Sys.print(haxe.Json.stringify({version:App.VERSION.toString()}));
	}

	public function doHealth() {
		var vars = sugoi.db.Variable.manager.search(true);
		var json = {version:App.VERSION.toString()};
		for(v in vars){
			Reflect.setField(json,v.name,v.value);
		}
		Sys.print(haxe.Json.stringify(json));
	}


}
