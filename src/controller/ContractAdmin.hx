package controller;
import db.UserContract;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import sugoi.form.elements.StringInput;
import Common;
using tools.ObjectListTool;

class ContractAdmin extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.isContractManager()) throw Error("/", "Vous n'avez pas accès à la gestion des contrats");
		
		
	}
	
	function sendNav(c){
		var nav = new Array<Link>();
		var e = Nav(nav,"contractAdmin",c.id);
		app.event(e);
		view.nav = e.getParameters()[0];
	}
	
	/**
	 * Contract admin main page
	 */
	@tpl("contractadmin/default.mtt")
	function doDefault(?args:{old:Bool}) {
		
		var now = Date.now();
		
		var contracts;
		if (args != null && args.old) {
			contracts = db.Contract.manager.search($amap == app.user.amap && $endDate < Date.now() ,{orderBy:-startDate},false);	
		}else {
			contracts = db.Contract.getActiveContracts(app.user.amap, true, false);	
		}

		//filter if current user is not manager
		if (!app.user.isAmapManager()) {
			for ( c in Lambda.array(contracts).copy()) {				
				if(!app.user.canManageContract(c)) contracts.remove(c);				
			}
		}
		
		view.contracts = contracts;		
		view.vendors = app.user.amap.getVendors();
		view.places = app.user.amap.getPlaces();
		checkToken();
		

		//multidistribs to validate
		if(app.user.isAmapManager() && app.user.amap.hasPayments()){
			var cids = db.Contract.manager.search($amap == app.user.amap && $endDate > Date.now() && $type == db.Contract.TYPE_VARORDER,false).getIds();
			var oneMonth = tools.DateTool.deltaDays(now, -10);
			var ds = db.Distribution.manager.search( !$validated && ($date > oneMonth) && ($date < now) && ($contractId in cids), {orderBy:date}, false);
			view.distribs = tools.ObjectListTool.deduplicateDistribsByKey( ds );
		}
		
		
	}

	/**
	 * Manage products
	 */
	@tpl("contractadmin/products.mtt")
	function doProducts(contract:db.Contract,?args:{?enable:String,?disable:String}) {
		
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		//checks
		if (app.user.amap.hasShopMode()) {
		
			for ( p in contract.getProducts(false)) {
				if (p.getCategories().length == 0) {
					app.session.addMessage("Attention, un ou plusieurs produits n'ont pas de catégories, <a href='/product/categorize/"+contract.id+"'>cliquez ici pour en ajouter</a>", true);
					break;
				}
			}
			
		}
		
		//batch enable / disable products
		if (args != null){
			
			var products = contract.getProducts(false);
			
			if (args.disable != null){
				
				var pids = Lambda.array(Lambda.map(args.disable.split("|"), function(x) return Std.parseInt(x)));
				app.event(BatchEnableProducts(pids, false));
				
				for ( pid in pids){
					if ( Lambda.find(products,function(p) return p.id==pid)==null ) throw 'product $pid is not in this contract !';
					var p = db.Product.manager.get(pid, true);
					p.active = false;
					p.update();
				}
			}
			
			if (args.enable != null){
				
				var pids = Lambda.array(Lambda.map(args.enable.split("|"), function(x) return Std.parseInt(x)));
				app.event(BatchEnableProducts(pids, true));
				
				for ( pid in pids){
					if ( Lambda.find(products,function(p) return p.id==pid)==null ) throw 'product $pid is not in this contract !';
					var p = db.Product.manager.get(pid, true);
					p.active = true;
					p.update();
				}
			}
			
		}
		
		//generate a token
		checkToken();
	}
	
	
	/**
	 *  - hidden page -
	 * copy products from a contract to an other
	 */
	@admin @tpl("form.mtt")
	function doCopyProducts(contract:db.Contract) {
		view.title = "Copier des produits dans : "+contract.name;
		var form = new Form("copy");
		var contracts = app.user.amap.getActiveContracts();
		var contracts  = Lambda.map(contracts, function(c) return {key:Std.string(c.id),value:Std.string(c.name) } );
		form.addElement(new sugoi.form.elements.Selectbox("source","Copier les produits depuis : ",Lambda.array(contracts)));
		form.addElement(new sugoi.form.elements.Checkbox("delete", "Effacer les produits existants (supprime toutes les commandes !)", false));
		if (form.checkToken()) {
			
			if (form.getValueOf("delete") == "1") {
				for ( p in contract.getProducts()) {
					p.lock();
					p.delete();
				}
			}
			
			var source = db.Contract.manager.get(Std.parseInt(form.getValueOf("source")), false);
			var prods = source.getProducts();
			for ( source_p in prods) {
				var p = new db.Product();
				p.name = source_p.name;
				p.price = source_p.price;
				p.type = source_p.type;
				p.contract = contract;
				p.insert();
			}
			
			throw Ok("/contractAdmin/products/" + contract.id, "Produits copiés depuis " + source.name);
			
			
		}
		
		
		view.form = form;
	}
	
	/**
	 * displays a calendar of the current month 
	 * with all events ( contracts start and end, deliveries... )
	 */
	@tpl('contractadmin/calendar.mtt')
	public function doCalendar() {
		
		var contracts = db.Contract.getActiveContracts(app.user.amap, true, false);	
		
		//Events of the month in a calendar
		var cal = Calendar.getMonthViewMap();
		
		for ( c in contracts) {
			var start = c.startDate.toString().substr(0,10);
			var end = c.endDate.toString().substr(0,10);
			if (cal.exists( start )) {
				var v = cal.get(start);
				v.push( { name: "Début contrat " + c.name,  color:Calendar.COLOR_CONTRACT } );
				cal.set( start, v );
			}
			if (cal.exists( end )) {
				var v = cal.get(end);
				v.push(		{ name: "Fin contrat "  +c.name,  color:Calendar.COLOR_CONTRACT } );
				cal.set( end, v );
			}
			
			//deliveries
			for ( d in c.getDistribs(false)) {
				var start = d.date.toString().substr(0,10);
				
				if (cal.exists( start )) {
					var v = cal.get( start );
					v.push(		{ name: "Distribution "  +d.contract.name,  color:Calendar.COLOR_DELIVERY } );
					cal.set( start, v );
				}
				
				if ( d.orderStartDate != null && d.orderStartDate != null ) {
					var k = d.orderStartDate.toString().substr(0,10);
					if (cal.exists( k )) {
						var v = cal.get( k );
						v.push(		{ name: "Ouverture commandes "  +d.contract.name,  color:Calendar.COLOR_ORDER } );
						cal.set( k , v );
					}
					
					var k = d.orderEndDate.toString().substr(0,10);
					if (cal.exists( k )) {
						var v = cal.get( k );
						v.push(		{ name: "Fin commandes "  +d.contract.name,  color:Calendar.COLOR_ORDER } );
						cal.set( k , v );
					}
					
				}
				
			}
			
		}
		
		var n = Date.now();
		view.now = new Date(n.getFullYear(),n.getMonth(),n.getDate(),0,0,0).getTime();
		view.calendar = Calendar.mapToArray( cal );
		
		
	}
	
	/**
	 * Global view on orders
	 * 
	 * @param	date
	 */
	@tpl('contractadmin/ordersByDate.mtt')
	function doOrdersByDate(?date:Date,?place:db.Place){
		if (date == null) {
		
			
			var f = new sugoi.form.Form("listBydate", null, sugoi.form.Form.FormMethod.GET);
			var el = new sugoi.form.elements.DatePicker("date", "Date de distribution", true);
			el.format = 'LL';
			f.addElement(el);
			
			var places = Lambda.map(app.user.amap.getPlaces(), function(p) return {label:p.name,value:p.id} );
			f.addElement(new sugoi.form.elements.IntSelect("placeId", "Lieu", Lambda.array(places),app.user.amap.getMainPlace().id,true));
			
			view.form = f;
			view.title = "Vue globale des commandes";
			view.text = "Cette page vous permet d'avoir une vision d'ensemble des commandes tout contrats confondus.";
			view.text += "<br/>Sélectionnez la date de distribution qui vous interesse :";
			app.setTemplate("form.mtt");
			
			if (f.checkToken()) {
				
				var url = '/contractAdmin/ordersByDate/' + f.getValueOf("date").toString().substr(0, 10);
				var p = f.getValueOf("placeId");
				if (p != null) url += "/"+p;
				throw Redirect( url );
			}
			
			return;
			
		}else {
			
			var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
			var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
			var contracts = app.user.amap.getActiveContracts(true);
			var cids = Lambda.map(contracts, function(c) return c.id);
			var cconst = [];
			var cvar = [];
			for ( c in contracts) {
				if (c.type == db.Contract.TYPE_CONSTORDERS) cconst.push(c.id);
				if (c.type == db.Contract.TYPE_VARORDER) 	cvar.push(c.id);				
			}
			
			//distribs
			var vdistribs = db.Distribution.manager.search(($contractId in cvar)   && $date >= d1 && $date <= d2 && place.id==$placeId, false);		
			var cdistribs = db.Distribution.manager.search(($contractId in cconst) && $date >= d1 && $date <= d2 && place.id==$placeId, false);	
			
			if (vdistribs.length == 0 && cdistribs.length == 0) throw Error("/contractAdmin/ordersByDate", "Il n'y a aucune distribution à cette date");
			
			
			//varying orders
			var varorders = db.UserContract.manager.search($distributionId in Lambda.map(vdistribs, function(d) return d.id)  , { orderBy:userId } );
			
			//constant orders
			var constorders = [];
			for ( d in cdistribs) {
				var orders2 = db.UserContract.manager.search($productId in Lambda.map(d.contract.getProducts(), function(d) return d.id), { orderBy:userId } );
				constorders = constorders.concat(Lambda.array(orders2));
			}
			
			//merge 2 lists
			var orders = Lambda.array(varorders).concat(Lambda.array(constorders));
			var orders = db.UserContract.prepare(Lambda.list(orders));
			
			view.orders = orders;
			view.date = date;
			view.place = place;
			view.ctotal = app.params.exists("ctotal");
		}
	}
	
	
	/**
	 * Global view on orders, producer view
	 */
	@tpl('contractadmin/vendorsByDate.mtt')
	function doVendorsByDate(date:Date,place:db.Place){
			
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
		var contracts = app.user.amap.getActiveContracts(true);
		var cids = Lambda.map(contracts, function(c) return c.id);
		
		//distribs for both types in active contracts
		var distribs = db.Distribution.manager.search(($contractId in cids) && $date >= d1 && $date <= d2 && $place==place , false);		

		
		if ( distribs.length == 0 ) throw Error("/contractAdmin/ordersByDate", "Il n'y a aucune distribution à cette date");
		
		var out = new Map<Int,Dynamic>();//key : vendor id
		
		for (d in distribs){
			var vid = d.contract.vendor.id;
			var o = out.get(vid);
			
			if (o == null){
				out.set( vid, {contract:d.contract,distrib:d,orders:db.UserContract.getOrdersByProduct( {distribution:d} )});	
			}else{
				
				//add orders with existing ones
				for ( x in db.UserContract.getOrdersByProduct( {distribution:d} )){
					
					//find record in existing orders
					var f  : Dynamic = Lambda.find(o.orders, function(a) return a.pid == x.pid);
					if (f == null){
						//new product order
						o.orders.push(x);						
					}else{
						//increment existing
						f.quantity += untyped x.quantity;
						f.total += untyped x.total;
					}
				}
				out.set(vid, o);
			}
		}
		
		view.orders = Lambda.array(out);
		view.date = date;
	}

	/**
	 * Overview of orders for this contract in backoffice
	 */
	@tpl("contractadmin/orders.mtt")
	function doOrders(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) { 
			throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		}
		var d = null;
		if (contract.type == db.Contract.TYPE_VARORDER ){
			view.distribution = args.d;
			d = args.d;
		}
		view.c = contract;
		var orders = db.UserContract.getOrders(contract, d, app.params.exists("csv"));
		
		if ( !app.params.exists("csv") ){
			
			//show orders on disabled products
			var disabledProducts = 0;
			for ( o in orders ){
				if ( !db.Product.manager.get(o.productId, false).active ) {
					disabledProducts++;
					Reflect.setField(o, "disabled", true);
				}
			}
		
			view.disabledProducts = disabledProducts;
			view.orders = orders;	
		}
		
	}
	
	
	/**
	 * hidden feature : updates orders by setting current product price.
	 */
	function doUpdatePrices(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) { 
			throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		}
		var d = null;
		if (contract.type == db.Contract.TYPE_VARORDER ){
			view.distribution = args.d;
			d = args.d;
		}
		
		for ( o in contract.getOrders(d)){
			o.lock();
			o.productPrice = o.product.price;
			if (contract.hasPercentageOnOrders()){
				o.feesRate = contract.percentageValue;
			}
			o.update();
			
		}
		throw Ok("/contractAdmin/orders/"+contract.id+"?d="+args.d.id, "Prix mis à jours à leur valeur actuelle.");
	}
	
	/**
	 *  Duplicate a contract
	 */
	@tpl("form.mtt")
	function doDuplicate(contract:db.Contract) {
		sendNav(contract);
		if (!app.user.isAmapManager()) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		
		view.title = "Dupliquer le contrat '"+contract.name+"'";
		var form = new Form("duplicate");
		
		form.addElement(new StringInput("name","Nom du nouveau contrat : ",contract.name+" - copie "));
		form.addElement(new Checkbox("copyProducts","Copier les produits",true));
		form.addElement(new Checkbox("copyDeliveries","Copier les distributions",true));
		
		if (form.checkToken()) {
			
			var nc = new db.Contract();
			nc.name = form.getValueOf("name");
			nc.startDate = contract.startDate;
			nc.endDate = contract.endDate;
			nc.amap = contract.amap;
			nc.contact = contract.contact;
			nc.description = contract.description;
			nc.distributorNum = contract.distributorNum;
			nc.flags = contract.flags;
			nc.type = contract.type;
			nc.vendor = contract.vendor;
			nc.percentageName = contract.percentageName;
			nc.percentageValue = contract.percentageValue;
			nc.insert();
			
			//give right to this contract
			if(contract.contact!=null){
				var ua = db.UserAmap.get(contract.contact, contract.amap);
				ua.giveRight(ContractAdmin(nc.id));
			}
			
			
			if (form.getValueOf("copyProducts") == true) {
				var prods = contract.getProducts();
				for ( source_p in prods) {
					var p = new db.Product();
					p.name = source_p.name;
					p.price = source_p.price;
					p.type = source_p.type;
					p.contract = nc;
					p.image = source_p.image;
					p.desc = source_p.desc;
					p.ref = source_p.ref;
					p.stock = source_p.stock;
					p.vat = source_p.vat;
					p.organic = source_p.organic;
					p.txpProduct = source_p.txpProduct;
					p.insert();
					
					for (source_cat in source_p.getCategories()){
						
						var cat = new db.ProductCategory();
						cat.product = p;
						cat.category = source_cat;
						cat.insert();
						
					}
					
				}
			}
			
			if (form.getValueOf("copyDeliveries") == true) {
				for ( ds in contract.getDistribs()) {
					var d = new db.Distribution();
					d.contract = nc;
					d.date = ds.date;
					d.distributor1Id = ds.distributor1Id;
					d.distributor2Id = ds.distributor2Id;
					d.distributor3Id = ds.distributor3Id;
					d.distributor4Id = ds.distributor4Id;
					d.orderStartDate = ds.orderStartDate;
					d.orderEndDate = ds.orderEndDate;
					d.end = ds.end;
					d.place = ds.place;
					d.text = ds.text;
					d.insert();
				}
			}
			
			throw Ok("/contractAdmin/view/" + nc.id, "Contrat dupliqué");
		}
		
		view.form = form;
	}
	
	
	
	/**
	 * Commandes groupées par produit.
	 */
	@tpl("contractadmin/ordersByProduct.mtt")
	function doOrdersByProduct(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);		
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		
		if (contract.type == db.Contract.TYPE_VARORDER ) view.distribution = args.d;
		view.c = contract;
		var d = args != null ? args.d : null;
		if (d == null) d = contract.getDistribs(false).first();
		if (d == null) throw "Aucune distribution dans ce contrat";
		
		var orders = db.UserContract.getOrdersByProduct({distribution:d},app.params.exists("csv"));
		view.orders = orders;
	}
	
	@tpl("contractadmin/ordersByProductList.mtt")
	function doOrdersByProductList(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);		
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		
		if (contract.type == db.Contract.TYPE_VARORDER ) view.distribution = args.d;
		view.c = contract;
		view.u = app.user;
		var d = args != null ? args.d : null;
		if (d == null) d = contract.getDistribs(false).first();
		if (d == null) throw "Aucune distribution dans ce contrat";
		
		var orders = db.UserContract.getOrdersByProduct({distribution:d},false);
		view.orders = orders;
	}
	
	/**
	 * Lists deliveries for this contract
	 */
	@tpl("contractadmin/deliveries.mtt")
	function doDistributions(contract:db.Contract, ?args: { old:Bool } ) {
		sendNav(contract);
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		if (args != null && args.old) {
			//display also old deliveries
			view.deliveries = contract.getDistribs(false);			
		}else {
			view.deliveries = db.Distribution.manager.search($end > DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30) && $contract == contract, { orderBy:date} );			
		}
		
		view.cycles = db.DistributionCycle.manager.search($contract==contract,false);
		
	}
	
	/**
	 * Participation aux distributions
	 */
	@tpl("contractadmin/distributionp.mtt")
	function doDistributionp(contract:db.Contract) {
		sendNav(contract);
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		
		var out = new Array<{user:db.User,count:Int}>();
		
		var distribs = contract.getDistribs(false);
		var users = contract.getUsers();
		
		var num =  (distribs.length*contract.distributorNum) / users.length;
		
		view.num = Std.string(num).substr(0,4);
		view.numRounded = Math.round(num);
		view.users = users.length;
		view.distributorNum = contract.distributorNum;
		view.distribs = distribs.length;
		
		for (user in users) {
			App.log(user);
			var count = 0;
			for ( d in distribs) {
				if (d.distributor1Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor2Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor3Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor4Id == user.id) {
					count++;
					continue;
				}
			}
			
			
			out.push( { user:user, count:count } );
		}
		
		view.c = contract;
		view.participations = out;
	}
	
	@tpl("contractadmin/view.mtt")
	function doView(contract:db.Contract) {
		sendNav(contract);
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = view.contract = contract;
	}
	
	
	@tpl("contractadmin/stats.mtt")
	function doStats(contract:db.Contract, ?args: { stat:Int } ) {
		sendNav(contract);
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		if (args == null) args = { stat:0 };
		view.stat = args.stat;
		
		switch(args.stat) {
			case 0 : 
				//ancienneté des amapiens
				view.anciennete = sys.db.Manager.cnx.request("select YEAR(u.cdate) as uyear ,count(DISTINCT u.id) as cnt from User u, UserContract up where up.userId=u.id and up.productId IN (" + contract.getProducts().map(function(x) return x.id).join(",") + ") group by uyear;").results();
			case 1 : 
				//repartition des commandes
				var pids = db.Product.manager.search($contract == contract, false);
				var pids = Lambda.map(pids, function(x) return x.id);
		
				//view.contracts = sys.db.Manager.cnx.request("select u.firstName , u.lastName as uname, u.id as uid, p.name as pname , up.* from User u, UserContract up, Product p where up.userId=u.id and up.productId=p.id and p.contractId="+contract.id+" order by uname asc;").results();
				
				var repartition = sys.db.Manager.cnx.request("select sum(quantity) as quantity,productId,p.name,p.price from UserContract up, Product p where up.productId IN (" + contract.getProducts().map(function(x) return x.id).join(",") + ") and up.productId=p.id group by productId").results();
				var total = 0;
				var totalPrice = 0;
				for ( r in repartition) {
					total += r.quantity;
					totalPrice += r.price*r.quantity; 
				}
				for (r in repartition) {
					Reflect.setField(r, "percent", Math.round((r.quantity/total)*100)  );
				}
				
				
				if ( app.params.exists("csv") ){
					
					sugoi.tools.Csv.printCsvData(Lambda.array(repartition), ["quantity","productId","name","price","percent"], "stats-" + contract.name+".csv");
				}
				
				view.repartition = repartition;
				view.totalQuantity = total;
				view.totalPrice = totalPrice;
				
		}
		
	}
	
	
	
	/**
	 * Efface une commande
	 * @param	uc
	 */
	function doDelete(uc:UserContract) {
		if (!app.user.canManageContract(uc.product.contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		uc.lock();
		uc.delete();
		throw Ok('/contractAdmin/orders/'+uc.product.contract.id,'Le contrat a bien été annulé');
	}
	

	@tpl("contractadmin/selectDistrib.mtt")
	function doSelectDistrib(c:db.Contract, ?args:{old:Bool}) {
		sendNav(c);
		view.c = c;
		if (args != null && args.old){
			view.distributions = c.getDistribs(false);	
		}else{
			view.distributions = c.getDistribs(true);
		}
		
	}
	
	/**
	 * Edit a user's orders
	 */
	@tpl("contractadmin/edit.mtt")
	function doEdit(c:db.Contract, ?user:db.User, args:{?d:db.Distribution}) {
		sendNav(c);
		if (!app.user.canManageContract(c)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		if (args.d != null && args.d.validated) throw Error("/contractAdmin/orders/" + c.id + "?d=" + args.d.id, "Cette distribution a déjà été validée");
		
		view.c = view.contract = c;
		view.u = user;
		view.distribution = args.d;
			
		//need to select a distribution for varying orders contracts
		if (c.type == db.Contract.TYPE_VARORDER && args.d == null ) {
			
			throw Redirect("/contractAdmin/orders/" + c.id);
			
		}else {
			
			//members of the group
			view.users = app.user.amap.getMembersFormElementData();
			
			
			var userOrders = new Array<{order:db.UserContract,product:db.Product}>();
			var products = c.getProducts(false);
			
			for ( p in products) {
				var ua = { order:null, product:p };
				
				var order : db.UserContract = null;
				if (c.type == db.Contract.TYPE_VARORDER) {
					order = db.UserContract.manager.select($user == user && $productId == p.id && $distributionId==args.d.id, true);	
				}else {
					order = db.UserContract.manager.select($user == user && $productId == p.id, true);
				}
				
				if (order != null) ua.order = order;
				userOrders.push(ua);
			}
			
			//form check
			if (checkToken()) {
				
				//c'est une nouvelle commande, le user a été défini dans le formulaire
				if (user == null) {
					user = db.User.manager.get(Std.parseInt(app.params.get("user")));
					if (user == null) throw "user #"+app.params.get("user")+" introuvable";
					if (!user.isMemberOf(app.user.amap)) throw user + " ne fait pas partie de ce groupe";
				}
				
				
				//get distrib if needed
				var distrib : db.Distribution = null;
				if (c.type == db.Contract.TYPE_VARORDER) {
					distrib = db.Distribution.manager.get(Std.parseInt(app.params.get("distribution")), false);
				}
				
				var orders = [];
				
				for (k in app.params.keys()) {
					var param = app.params.get(k);
					if (k.substr(0, "product".length) == "product") {
						
						//trouve le produit dans userOrders
						var pid = Std.parseInt(k.substr("product".length));
						var uo = Lambda.find(userOrders, function(uo) return uo.product.id == pid);
						if (uo == null) throw "Impossible de retrouver le produit " + pid;
						
						//user2 ?
						var user2 : db.User = null;
						var invert = false;
						if (app.params.get("user2" + pid) != null && app.params.get("user2" + pid) != "0") {
							//trace("user2" + pid + " : " + app.params.get("user2" + pid));
							user2 = db.User.manager.get(Std.parseInt(app.params.get("user2"+pid)));
							if (user2 == null) throw "user #"+app.params.get("user2")+" introuvable";
							if (!user2.isMemberOf(app.user.amap)) throw user2 + " ne fait pas partie de ce groupe";
							if (user.id == user2.id) throw "Les deux comptes sélectionnés doivent être différents";
							
							invert = app.params.get("invert" + pid) == "1";
							
						}
						
						//quantity
						var q = 0.0;
						if (uo.product.hasFloatQt ) {
							param = StringTools.replace(param, ",", ".");
							q = Std.parseFloat(param);
						}else {
							q = Std.parseInt(param);
						}						
						
						//record order
						if (uo.order != null) {
							//existing record
							var o = db.UserContract.edit(uo.order, q, (app.params.get("paid" + pid) == "1"), user2, invert);
							if (o != null) orders.push(o);
						}else {
							//new record
							var o =  db.UserContract.make(user, q, uo.product, distrib == null ? null : distrib.id, (app.params.get("paid" + pid) == "1"), user2, invert);
							if (o != null) orders.push(o);
						}
					}
				}
				
				app.event(MakeOrder(orders));
				
				if (distrib != null) {
					throw Ok("/contractAdmin/orders/" + c.id +"?d="+distrib.id, "La commande a été mise à jour");
				}else {
					throw Ok("/contractAdmin/orders/" + c.id, "La commande a été mise à jour");						
				}
				
			}
			view.userOrders = userOrders;
		}
	}
	
}
