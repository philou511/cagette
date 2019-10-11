package controller;
import db.UserContract;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import sugoi.form.elements.StringInput;
import Common;
import datetime.DateTime;
using tools.ObjectListTool;
using tools.DateTool;
import service.OrderService;

class ContractAdmin extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.isContractManager()) throw Error("/", t._("You don't have the authorization to manage contracts"));
		view.nav = ["contractadmin"];
		
	}
	
	public function sendNav(c){
		var navbar = new Array<Link>();
		var e = Nav(navbar,"contractAdmin",c.id);
		app.event(e);
		view.navbar = e.getParameters()[0];
	}
	
	/**
	 * Contract admin main page
	 */
	@tpl("contractadmin/default.mtt")
	function doDefault(?args:{old:Bool}) {
		
		view.nav.push("default");
		
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
		view.vendors = app.user.amap.getActiveVendors();
		view.places = app.user.amap.getPlaces();
		checkToken();

		//Multidistribs to validate
		if( (app.user.canManageAllContracts()||app.user.isAmapManager() )  && app.user.amap.hasPayments()){
			var twoMonthAgo = tools.DateTool.deltaDays(now,-60);
			var multidistribs = [];
			for( md in db.MultiDistrib.getFromTimeRange(app.user.amap,twoMonthAgo,now)){
				if( !md.isValidated() ) multidistribs.push(md);				
			}
			view.multidistribs = multidistribs; 

		}else{
			view.multidistribs = [];
		}
	}

	/**
	 * Manage products
	 */
	@tpl("contractadmin/products.mtt")
	function doProducts(contract:db.Contract,?args:{?enable:String,?disable:String}) {
		view.nav.push("products");
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("Access forbidden") );
		view.c = contract;
		
		//checks
		if (app.user.amap.hasShopMode() && !app.user.amap.hasTaxonomy() ) {		
			for ( p in contract.getProducts(false)) {
				if (p.getCategories().length == 0) {
					app.session.addMessage(t._("Warning, at least one product does not have any category. <a href='/product/categorize/::contractid::'>Click here to add categories</a>", {contractid:contract.id}), true);
					break;
				}
			}			
		}
		
		//batch enable / disable products
		if (args != null){
			
			if (args.disable != null){
				var pids = Lambda.array(Lambda.map(args.disable.split("|"), function(x) return Std.parseInt(x)));				
				service.ProductService.batchDisableProducts(pids);
			}
			
			if (args.enable != null){
				var pids = Lambda.array(Lambda.map(args.enable.split("|"), function(x) return Std.parseInt(x)));
				service.ProductService.batchEnableProducts(pids);
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
		view.title = t._("Copy products in: ")+contract.name;
		var form = new Form("copy");
		var contracts = app.user.amap.getActiveContracts();
		var contracts  = Lambda.map(contracts, function(c) return {key:Std.string(c.id),value:Std.string(c.name) } );
		form.addElement(new sugoi.form.elements.Selectbox("source", t._("Copy products from: "),Lambda.array(contracts)));
		form.addElement(new sugoi.form.elements.Checkbox("delete", t._("Delete existing products (all orders will be deleted!)")));
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
				//p.type = source_p.type;
				p.contract = contract;
				p.insert();
			}
			
			throw Ok("/contractAdmin/products/" + contract.id, t._("Products copied from ") + source.name);
			
			
		}
		
		
		view.form = form;
	}
	
	/**
	 * global view on orders within a timeframe
	 */
	@tpl('contractadmin/ordersByTimeFrame.mtt')
	function doOrdersByTimeFrame(?from:Date, ?to:Date/*, ?place:db.Place*/){
		
		if (from == null) {
		
			var f = new sugoi.form.Form("listBydate", null, sugoi.form.Form.FormMethod.GET);
			
			var now = DateTime.now();	
			var from = now.snap(Month(Down)).getDate();			
			var to = now.snap(Month(Up)).add(Day(-1)).getDate();
			
			
			var el = new sugoi.form.elements.DatePicker("from", t._("Start date"), from,true);			
			el.format = 'LL';
			f.addElement(el);
			
			var el = new sugoi.form.elements.DatePicker("to", t._("End date"), to,true);
			el.format = 'LL';
			f.addElement(el);
			
			//var places = Lambda.map(app.user.amap.getPlaces(), function(p) return {label:p.name,value:p.id} );
			//f.addElement(new sugoi.form.elements.IntSelect("placeId", "Lieu", Lambda.array(places),app.user.amap.getMainPlace().id,true));
			
			view.form = f;
			view.title = t._("Global view of orders");
			app.setTemplate("form.mtt");
			
			if (f.checkToken()) {
				
				var url = '/contractAdmin/ordersByTimeFrame/' + f.getValueOf("from").toString().substr(0, 10) +"/"+f.getValueOf("to").toString().substr(0, 10);
				//var p = f.getValueOf("placeId");
				//if (p != null) url += "/"+p;
				throw Redirect( url );
			}
			
			return;
			
		}else {
			
			var d1 = tools.DateTool.setHourMinute(from,0,0);
			var d2 = tools.DateTool.setHourMinute(to,23,59);
			var contracts = app.user.amap.getActiveContracts(true);
			var cconst = [];
			var cvar = [];
			for ( c in contracts) {
				if (c.type == db.Contract.TYPE_CONSTORDERS) cconst.push(c.id);
				if (c.type == db.Contract.TYPE_VARORDER) 	cvar.push(c.id);				
			}
			
			//distribs
			var vdistribs = db.Distribution.manager.search(($contractId in cvar)   && $date >= d1 && $date <= d2 /*&& place.id==$placeId*/, false);		
			var cdistribs = db.Distribution.manager.search(($contractId in cconst) && $date >= d1 && $date <= d2 /*&& place.id==$placeId*/, false);	
			
			if (vdistribs.length == 0 && cdistribs.length == 0) throw Error("/contractAdmin/ordersByDate", t._("There is no delivery at this date"));
			
			//varying orders
			var varorders = db.UserContract.manager.search($distributionId in vdistribs.getIds()  , { orderBy:userId } );
			
			//constant orders
			var constorders = [];
			for ( d in cdistribs) {
				var orders2 = db.UserContract.manager.search($productId in d.contract.getProducts().getIds(), { orderBy:userId } );
				constorders = constorders.concat(Lambda.array(orders2));
			}
			
			//merge 2 lists
			var orders = Lambda.array(varorders).concat(Lambda.array(constorders));
			var orders = service.OrderService.prepare(Lambda.list(orders));
			
			view.orders = orders;
			view.from = from;
			view.to = to;
			view.ctotal = app.params.exists("ctotal");
			
		}
		
		
		
	}
	
	/**
	 * Global view on orders in one day
	 * 
	 * @param	date
	 */
	@tpl('contractadmin/ordersByDate.mtt')
	function doOrdersByDate(?date:Date,?place:db.Place){
		if (date == null) {
		
			var f = new sugoi.form.Form("listBydate", null, sugoi.form.Form.FormMethod.GET);
			var el = new sugoi.form.elements.DatePicker("date", t._("Delivery date"), true);
			el.format = 'LL';
			f.addElement(el);
			
			var places = Lambda.map(app.user.amap.getPlaces(), function(p) return {label:p.name,value:p.id} );
			f.addElement(new sugoi.form.elements.IntSelect("placeId", "Lieu", Lambda.array(places),app.user.amap.getMainPlace().id,true));
			
			view.form = f;
			view.title = t._("Global view of orders");
			view.text = t._("This page allows you to have a global view on orders of all catalogs");
			view.text += t._("<br/>Select a delivery date:");
			app.setTemplate("form.mtt");
			
			if (f.checkToken()) {
				
				var url = '/contractAdmin/ordersByDate/' + f.getValueOf("date").toString().substr(0, 10);
				var p = f.getValueOf("placeId");
				if (p != null) url += "/"+p;
				throw Redirect( url );
			}
			
			return;
			
		}else {
			
			var d1 = date.setHourMinute(0, 0);
			var d2 = date.setHourMinute(23,59);
			var contracts = app.user.amap.getActiveContracts(true);
			var cconst = [];
			var cvar = [];
			for ( c in contracts) {
				if (c.type == db.Contract.TYPE_CONSTORDERS) cconst.push(c.id);
				if (c.type == db.Contract.TYPE_VARORDER) 	cvar.push(c.id);				
			}
			
			//distribs
			var vdistribs = db.Distribution.manager.search(($contractId in cvar)   && $date >= d1 && $date <= d2 && place.id==$placeId, false);		
			var cdistribs = db.Distribution.manager.search(($contractId in cconst) && $date >= d1 && $date <= d2 && place.id==$placeId, false);	
			
			if (vdistribs.length == 0 && cdistribs.length == 0) throw Error("/contractAdmin/ordersByDate", t._("There is no delivery at this date"));
			
			//varying orders
			var varorders = db.UserContract.manager.search($distributionId in vdistribs.getIds()  , { orderBy:userId } );
			
			//constant orders
			var constorders = [];
			for ( d in cdistribs) {
				var orders2 = db.UserContract.manager.search($productId in d.contract.getProducts().getIds(), { orderBy:userId } );
				constorders = constorders.concat(Lambda.array(orders2));
			}
			
			//merge 2 lists
			var orders = Lambda.array(varorders).concat(Lambda.array(constorders));
			var orders = service.OrderService.prepare(Lambda.list(orders));
			
			view.orders = orders;
			view.date = date;
			view.place = place;
			view.ctotal = app.params.exists("ctotal");

			view.distrib = db.MultiDistrib.get(date,place);
		}
	}
	
	
	/**
	 * Global view on orders, producer view
	 */
	@tpl('contractadmin/vendorsByDate.mtt')
	function doVendorsByDate(date:Date,place:db.Place){

		//if ( distribs.length == 0 ) throw Error("/contractAdmin/ordersByDate", t._("There is no delivery at this date"));

	    var vendorDataByVendorId = new Map<Int,Dynamic>();//key : vendor id
		try {
			vendorDataByVendorId = service.ReportService.getMultiDistribVendorOrdersByProduct(date, place);
		} catch(e:tink.core.Error) {
			throw Error("/contractAdmin/ordersByDate", e.message);
		}
		
		
		
		/*var out = new Map<Int,Dynamic>();//key : vendor id
		
		for (d in distribs){
			var vid = d.contract.vendor.id;
			var o = out.get(vid);
			
			if (o == null){
				out.set( vid, {contract:d.contract,distrib:d,orders:service.ReportService.getOrdersByProduct( d )});	
			}else{
				
				//add orders with existing ones
				for ( x in  service.ReportService.getOrdersByProduct( d ) ){
					
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
		}*/
		
		view.orders = Lambda.array(vendorDataByVendorId);
		view.date = date;
	}
	
	/**
	 * Global view on orders, producer view
	 */
	@tpl('contractadmin/vendorsByTimeFrame.mtt')
	function doVendorsByTimeFrame(from:Date,to:Date){
			
		var d1 = tools.DateTool.setHourMinute(from,0,0);
		var d2 = tools.DateTool.setHourMinute(to,23,59);
		var contracts = app.user.amap.getActiveContracts(true);
		var cids = contracts.getIds();
		
		//distribs for both types in active contracts
		var distribs = db.Distribution.manager.search(($contractId in cids) && $date >= d1 && $date <= d2 /*&& $place==place*/, false);		
		if ( distribs.length == 0 ) throw Error("/contractAdmin/", t._("There is no delivery during this period"));
		
		var out = new Map<Int,{contract:db.Contract,distrib:db.Distribution,orders:Array<OrderByProduct>}>();//key : vendor id
		
		for (d in distribs){
			var vid = d.contract.vendor.id;
			var o = out.get(vid);
			
			if (o == null){
				out.set( vid, {contract:d.contract,distrib:d,orders:service.ReportService.getOrdersByProduct(d) });	
			}else{
				
				//add orders with existing ones
				for ( x in service.ReportService.getOrdersByProduct(d) ){
					
					//find record in existing orders
					var f : OrderByProduct = Lambda.find(o.orders, function(a:OrderByProduct) return a.pid == x.pid);
					if (f == null){
						//new product order
						o.orders.push(x);						
					}else{
						//increment existing
						f.quantity += x.quantity;
						f.totalHT += x.totalHT;
						f.totalTTC += x.totalTTC;
					}
				}
				out.set(vid, o);
			}
		}
		
		view.orders = Lambda.array(out);
		
		if ( app.params.exists("csv") ){
			var totalHT = 0.0;
			var totalTTC = 0.0;
			
			var orders = [];
			for ( x in out){
				//empty line
				orders.push({"quantity":null, 					"pname":null, "ref":null, "priceHT":null, "priceTTC":null, "totalHT":null, "totalTTC":null});				
				orders.push({"quantity":null, "pname":x.contract.vendor.name, "ref":null, "priceHT":null, "priceTTC":null, "totalHT":null, "totalTTC":null});				
				
				for (o in x.orders){
					if(o.vat==null) o.vat = 0;
					orders.push({
						"quantity":view.formatNum(o.quantity),
						"pname":o.pname,
						"ref":o.ref,
						"priceHT":view.formatNum(o.priceTTC / (1 + o.vat / 100) ),
						"priceTTC":view.formatNum(o.priceTTC),
						"totalHT":view.formatNum(o.totalHT),					
						"totalTTC":view.formatNum(o.totalTTC)					
					});
					totalTTC += o.totalTTC;
					totalHT += o.totalHT;
				}
				
				//total line
				orders.push({
					"quantity":null,
					"pname":null,
					"ref":null,
					"priceHT":null,
					"priceTTC":null,
					"totalHT":view.formatNum(totalHT) + "",
					"totalTTC":view.formatNum(totalTTC)+""					
				});								
				totalTTC = 0;
				totalHT = 0;
				
			}			
			var fileName = t._("Orders from the ::fromDate:: to the ::toDate:: per supplier.csv", {fromDate:from.toString().substr(0, 10), toDate:to.toString().substr(0, 10)});
			sugoi.tools.Csv.printCsvDataFromObjects(orders, ["quantity", "pname", "ref", "priceHT", "priceTTC", "totalHT","totalTTC"], fileName);
			return;
		}
		
		view.from = from;
		view.to = to;
	}
	
	
	/**
	 * Overview of orders for this contract in backoffice
	 */
	@tpl("contractadmin/orders.mtt")
	function doOrders(contract:db.Contract, args:{?d:db.Distribution,?delete:db.UserContract}) {
		view.nav.push("orders");
		sendNav(contract);
		
		//Checking permissions
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));
		if (contract.type == db.Contract.TYPE_VARORDER && args != null && args.d == null ) { 
			throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		}

		//Delete specified order with quantity of zero
		if (checkToken() && args != null && args.delete != null ) { 
			try {
				service.OrderService.delete(args.delete);
			} catch(e:tink.core.Error){
				throw Error("/contractAdmin/orders/" + contract.id, e.message);
			}
			if(args.d!=null){
				throw Ok("/contractAdmin/orders/" + contract.id + "?d="+args.d.id, t._("The order has been deleted."));
			}else{
				throw Ok("/contractAdmin/orders/" + contract.id, t._("The order has been deleted."));
			}
			
		}

		var d = null;
		if (contract.type == db.Contract.TYPE_VARORDER ){
			view.distribution = args.d;
			view.multiDistribId = args.d.multiDistrib.id;
			d = args.d;
		}
		view.c = contract;
		var orders = service.OrderService.getOrders(contract, d, app.params.exists("csv"));
		
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
		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));
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
		throw Ok("/contractAdmin/orders/"+contract.id+"?d="+args.d.id, t._("Prices are now up to date."));
	}
	
	/**
	 *  Duplicate a contract
	 */
	@tpl("form.mtt")
	function doDuplicate(contract:db.Contract) {

		sendNav(contract);
		if (!app.user.isAmapManager()) throw Error("/", t._("You do not have the authorization to manage this contract"));
		
		view.title = "Dupliquer le contrat '"+contract.name+"'";
		var form = new Form("duplicate");
		
		form.addElement(new StringInput("name", t._("Name of the new catalog"), contract.name.substr(0,50)  + " - copy"));		
		form.addElement(new Checkbox("copyProducts", t._("Copy products"),true));
		form.addElement(new Checkbox("copyDeliveries", t._("Copy deliveries"),true));
		
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
					p.contract = nc;
					p.image = source_p.image;
					p.desc = source_p.desc;
					p.ref = source_p.ref;
					p.stock = source_p.stock;
					p.vat = source_p.vat;
					p.organic = source_p.organic;
					p.txpProduct = source_p.txpProduct;
					p.unitType = source_p.unitType;
					p.multiWeight = source_p.multiWeight;
					p.variablePrice = source_p.variablePrice;
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
					d.multiDistrib = ds.multiDistrib;
					d.orderStartDate = ds.orderStartDate;
					d.orderEndDate = ds.orderEndDate;
					d.end = ds.end;
					d.place = ds.place;
					d.insert();
				}
			}
			
			app.event(DuplicateContract(contract));
			
			throw Ok("/contractAdmin/view/" + nc.id, t._("The catalog has been duplicated"));
		}
		
		view.form = form;
	}
	
	
	
	/**
	 * Orders grouped by product
	 */
	@tpl("contractadmin/ordersByProduct.mtt")
	function doOrdersByProduct(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		
		var d = args != null ? args.d : null;
		if (d == null) d = contract.getDistribs(false).first();
		if (d == null) throw Error("/contractAdmin/orders/"+contract.id,t._("There is no delivery in this catalog, please create at least one distribution."));

		var orders = service.ReportService.getOrdersByProduct(d,app.params.exists("csv"));
		view.orders = orders;
		view.distribution = d; 
		view.c = contract;
		
	}
	
	/**
	 * Purchase order to print
	 */
	@tpl("contractadmin/ordersByProductList.mtt")
	function doOrdersByProductList(contract:db.Contract, args:{?d:db.Distribution}) {
		
		sendNav(contract);		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("Forbidden access"));
		if (contract.type == db.Contract.TYPE_VARORDER && args.d == null ) throw Redirect("/contractAdmin/selectDistrib/" + contract.id); 
		
		if (contract.type == db.Contract.TYPE_VARORDER ) view.distribution = args.d;
		view.c = contract;
		view.group = contract.amap;
		var d = args != null ? args.d : null;
		if (d == null) d = contract.getDistribs(false).first();
		if (d == null) throw t._("No delivery in this catalog");
		
		var orders = service.ReportService.getOrdersByProduct(d,false);
		view.orders = orders;
	}
	
	/**
	 * Lists deliveries for this contract
	 */
	@tpl("contractadmin/distributions.mtt")
	function doDistributions(contract:db.Contract, ?args: { ?old:Bool,?participateToAllDistributions:Bool } ) {

		view.nav.push("distributions");
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));

		var multidistribs = [];
		var now = Date.now();

		if (args != null && args.old) {
			//display also old deliveries
			//distributions = Lambda.array(contract.getDistribs(false));	

			multidistribs = db.MultiDistrib.getFromTimeRange(contract.amap, DateTools.delta(now,1000.0*60*60*24*-365) , now);

		}else {
			//distributions = Lambda.array(db.Distribution.manager.search($end > DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30) && $contract == contract, { orderBy:date} ));
			multidistribs = db.MultiDistrib.getFromTimeRange(contract.amap, now , DateTools.delta(now,1000.0*60*60*24*365) );			
		}

		if(args!=null && args.participateToAllDistributions){
			for( d in multidistribs){
				if( d.getDistributionForContract(contract)==null ){
					service.DistributionService.participate(d,contract);
				}				
			}
			app.session.addMessage(contract.vendor.name+" participe maintenant à toutes les distributions");
		}
		
		view.multidistribs = multidistribs;
		view.c = contract;
		view.contract = contract;

				
	}

	function doParticipate(md:db.MultiDistrib,contract:db.Contract){
		try{
			service.DistributionService.participate(md,contract);
		}catch(e:tink.core.Error){
			throw Error("/contractAdmin/distributions/"+contract.id,e.message);
		}
		
		throw Ok("/contractAdmin/distributions/"+contract.id,t._("Distribution date added"));
	}
	
	@tpl("contractadmin/view.mtt")
	function doView(contract:db.Contract) {
		view.nav.push("view");
		sendNav(contract);
		
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));
		view.c = view.contract = contract;
	}
	
	
	@tpl("contractadmin/stats.mtt")
	function doStats(contract:db.Contract, ?args: { stat:Int } ) {
		sendNav(contract);
		if (!app.user.canManageContract(contract)) throw Error("/", t._("You do not have the authorization to manage this contract"));
		view.c = contract;
		
		if (args == null) args = { stat:0 };
		view.stat = args.stat;
		var pids = contract.getProducts().map(function(x) return x.id);
		switch(args.stat) {
			case 0 : 
				//ancienneté des amapiens
				
				if(pids.length==0){
					view.anciennete = new List();
				}else{
					view.anciennete = sys.db.Manager.cnx.request("select YEAR(u.cdate) as uyear ,count(DISTINCT u.id) as cnt from User u, UserContract up where up.userId=u.id and up.productId IN (" + pids.join(",") + ") group by uyear;").results();
				}
				
			case 1 : 
				//repartition des commandes
				var repartition = new List();
				var total = 0;
				var totalPrice = 0;
				if(pids.length!=0){	
					var repartition = sys.db.Manager.cnx.request("select sum(quantity) as quantity,productId,p.name,p.price from UserContract up, Product p where up.productId IN (" + contract.getProducts().map(function(x) return x.id).join(",") + ") and up.productId=p.id group by productId").results();
					for ( r in repartition) {
						total += r.quantity;
						totalPrice += r.price*r.quantity; 
					}
					for (r in repartition) {
						Reflect.setField(r, "percent", Math.round((r.quantity/total)*100)  );
					}
					
					if ( app.params.exists("csv") ){					
						sugoi.tools.Csv.printCsvDataFromObjects(Lambda.array(repartition), ["quantity","productId","name","price","percent"], "stats-" + contract.name+".csv");
					}
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
		if (!app.user.canManageContract(uc.product.contract)) throw Error("/", t._("Forbidden access"));
		uc.lock();
		uc.delete();
		throw Ok('/contractAdmin/orders/'+uc.product.contract.id, t._("The catalog has been canceled"));
	}
	

	@tpl("contractadmin/selectDistrib.mtt")
	function doSelectDistrib(c:db.Contract, ?args:{old:Bool}) {
		view.nav.push("orders");
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
	/*@tpl("contractadmin/edit.mtt")
	function doEdit(c:db.Contract, ?user:db.User, args:{?d:db.Distribution}) {
		view.nav.push("orders");
		sendNav(c);
		
		if (!app.user.canManageContract(c)) throw Error("/", t._("You do not have the authorization to manage this contract"));
		if (args.d != null && args.d.multiDistrib.validated) throw Error("/contractAdmin/orders/" + c.id + "?d=" + args.d.id, t._("This delivery has been already validated"));
		
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
				
				//it's a new order, the user has been defined in the form.
				if (user == null) {
					user = db.User.manager.get(Std.parseInt(app.params.get("user")));
					if (user == null){
						var user = app.params.get("user");
						throw t._("Unable to find user #::num::",{num:user});
					}
					if (!user.isMemberOf(app.user.amap)) throw user + " is not member of this group";
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
						if (uo == null) throw t._("Unable to find product ::pid::", {pid:pid});
						
						//user2 ?
						var user2 : db.User = null;
						var invert = false;
						if (app.params.get("user2" + pid) != null && app.params.get("user2" + pid) != "0") {
							user2 = db.User.manager.get(Std.parseInt(app.params.get("user2"+pid)));
							if (user2 == null) {
								var user = app.params.get("user2");
								throw t._("Unable to find user #::num::",{num:user});
							}
							if (!user2.isMemberOf(app.user.amap)) throw t._("::user:: is not part of this group",{user:user2});
							if (user.id == user2.id) throw t._("Both selected accounts must be different ones");
							
							invert = app.params.get("invert" + pid) == "1";
						}
						
						//filter quantity
						var q = 0.0;
						if (uo.product.hasFloatQt ) {
							param = StringTools.replace(param, ",", ".");
							q = Std.parseFloat(param);
						}else {
							q = Std.parseInt(param);
						}
						if(q==null)	continue; //ignore bad qt input
						
						//record order
						if (uo.order != null) {
							//existing record
							var o = OrderService.edit(uo.order, q, (app.params.get("paid" + pid) == "1"), user2, invert);
							if (o != null) orders.push(o);
						}else {
							//new record
							var o =  OrderService.make(user, q, uo.product, distrib == null ? null : distrib.id, (app.params.get("paid" + pid) == "1"), user2, invert);
							if (o != null) orders.push(o);
						}
					}
				}
				
				app.event(MakeOrder(orders));
				db.Operation.onOrderConfirm(orders);
				
				if (distrib != null) {
					throw Ok("/contractAdmin/orders/" + c.id +"?d="+distrib.id, t._("The order has been updated"));
				}else {
					throw Ok("/contractAdmin/orders/" + c.id, t._("The order has been updated"));						
				}
			}
			view.userOrders = userOrders;
		}
	}*/
	
}
