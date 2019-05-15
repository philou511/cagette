package controller;
import db.UserContract;
import sugoi.form.Form;
import sugoi.form.elements.HourDropDowns;
import tink.core.Error;
import sugoi.form.elements.IntSelect;
import sugoi.form.elements.TextArea;
import Common;
import service.VolunteerService;
import service.DistributionService;
using tools.DateTool;


class Distribution extends Controller
{

	public function new(){
		super();
		view.category = "distribution";
	}

	@tpl('distribution/default.mtt')
	function doDefault(){

		if (!app.user.canManageAllContracts()) throw Error('/', t._('Forbidden action') );

		var n = Date.now();
		var now = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
		var in3Month = DateTools.delta(now, 1000.0 * 60 * 60 * 24 * 30 * 3);
		view.distribs = db.MultiDistrib.getFromTimeRange(app.user.amap,now,in3Month);
		checkToken();
	}

	/**
	 * Attendance sheet by user-product (single distrib)
	 */
	@tpl('distribution/list.mtt')
	function doList(d:db.Distribution) {
		view.distrib = d;
		view.place = d.place;
		view.contract = d.contract;
		view.orders = service.OrderService.prepare(d.getOrders());		
	}

	/**
	 * Attendance sheet by product-user (single distrib)
	 */
	@tpl('distribution/listByProductUser.mtt')
	function doListByProductUser(d:db.Distribution) {
		view.distrib = d;
		view.place = d.place;
		view.contract = d.contract;
		// view.orders = UserContract.prepare(d.getOrders());
		
		//make a 2 dimensons table :  data[userId][productId]
		//WARNING : BUGS WILL APPEAR if there is many Order line for the same product
		var data = new Map<Int,Map<Int,UserOrder>>();
		var products = [];
		var uo = d.getOrders();

		for(o in uo){
			products.push(o.product);
		}

		for ( o in service.OrderService.prepare(uo)) {

			var user = data[o.userId];
			if (user == null) user = new Map();
			user[o.productId] = o;
			data[o.userId] = user;

		}
		
		//products
		var products = tools.ObjectListTool.deduplicate(products);
		products.sort(function(b, a) {
			return (a.name < b.name)?1:-1;
		});
		view.products = products;

		//users
		var users = Lambda.array(d.getUsers());
		// var usersMap = tools.ObjectListTool.toIdMap(users);
		users.sort(function(b, a) {
			return (a.lastName < b.lastName)?1:-1;
		});
		view.users = users;
		// view.usersMap = usersMap;

		view.orders = data;

		//total to pay by user
		view.totalByUser = function(uid:Int){
			var total = 0.0;
			for( o in data[uid]) total+= o.total;
			return total;
		}

		//total qty of product
		view.totalByProduct = function(pid:Int){
			var total = 0.0;
			for( uid in data.keys()){
				var x = data[uid][pid];
				if(x!=null) total+= x.quantity;	
			} 
			return total;
		}

	}
	
	/**
	 * Attendance sheet to print ( mutidistrib )
	 */
	@tpl('distribution/listByDate.mtt')
	function doListByDate(date:Date,place:db.Place, ?type:String, ?fontSize:String) {
		
		if (!app.user.isContractManager()) throw Error('/', t._("Forbidden action"));
		
		view.place = place;		
		view.onTheSpotAllowedPaymentTypes = service.PaymentService.getOnTheSpotAllowedPaymentTypes(app.user.amap);
		
		if (type == null) {
		
			//display form			
			var f = new sugoi.form.Form("listBydate", null, sugoi.form.Form.FormMethod.GET);
			f.addElement(new sugoi.form.elements.RadioGroup("type", "Affichage", [
				{ value:"one", label:t._("One person per page") },
				{ value:"contract", label:t._("One person per page sorted by contract") },
				{ value:"all", label:t._("All") },
				{ value:"allshort", label:t._("All but without prices and totals") },
			],"all"));
			f.addElement(new sugoi.form.elements.RadioGroup("fontSize", "Taille de police", [
				{ value:"S" , label:"S"  },
				{ value:"M" , label:"M"  },
				{ value:"L" , label:"L"  },
				{ value:"XL", label:"XL" },
			], "S", "S", false));
			
			view.form = f;
			app.setTemplate("form.mtt");
			
			if (f.checkToken()) {
				var suburl = f.getValueOf("type")+"/"+f.getValueOf("fontSize");
				var url = '/distribution/listByDate/' + date.toString().substr(0, 10)+"/"+place.id+"/"+suburl;
				throw Redirect( url );
			}
			
			return;
			
		}else {
			
			view.date = date;
			view.fontRatio = switch(fontSize){
				case "M" : 1; //1em = 16px
				case "L" : 1.25;
				case "XL": 1.50;
				default : 0.75;
			};
			
			switch(type) {
				case "one":
					app.setTemplate("distribution/listByDateOnePage.mtt");
				case "allshort" :
					app.setTemplate("distribution/listByDateShort.mtt");
				case "contract" :
					app.setTemplate("distribution/listByDateOnePageContract.mtt");
			}
			
			var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
			var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
			var contracts = app.user.amap.getActiveContracts(true);
			//var cids = Lambda.map(contracts, function(c) return c.id);
			var cconst = [];
			var cvar = [];
			for ( c in contracts) {
				if (c.type == db.Contract.TYPE_CONSTORDERS) cconst.push(c.id);
				if (c.type == db.Contract.TYPE_VARORDER) cvar.push(c.id);
			}
			
			//commandes variables
			var distribs = db.Distribution.manager.search(($contractId in cvar) && $date >= d1 && $date <= d2 && $place==place, false);		
			var orders = db.UserContract.manager.search($distributionId in Lambda.map(distribs, function(d) return d.id)  , { orderBy:userId } );
			
			//commandes fixes
			var distribs = db.Distribution.manager.search(($contractId in cconst) && $date >= d1 && $date <= d2 && $place==place, false);
			var orders = Lambda.array(orders);
			for ( d in distribs) {
				var orders2 = db.UserContract.manager.search($productId in Lambda.map(d.contract.getProducts(), function(d) return d.id)  , { orderBy:userId } );
				orders = orders.concat(Lambda.array(orders2));
			}

			var orders3 = service.OrderService.prepare(Lambda.list(orders));
			view.orders = orders3;
			
			if (type == "csv") {
				var data = new Array<Dynamic>();
				
				for (o in orders3) {
					data.push( { 
						"name":o.userName,
						"productName":o.productName,
						"price":view.formatNum(o.productPrice),
						"quantity":o.quantity,
						"fees":view.formatNum(o.fees),
						"total":view.formatNum(o.total),
						"paid":o.paid
					});				
				}

				sugoi.tools.Csv.printCsvDataFromObjects(data, ["name",  "productName", "price", "quantity","fees","total", "paid"],"Export-commandes-"+date.toString().substr(0,10)+"-Cagette");
				return;	
			}
		}
	}
	
	/**
		Delete a distribution
	**/
	function doDelete(d:db.Distribution) {
		
		if (!app.user.isContractManager(d.contract)) throw Error('/', t._("Forbidden action"));
		
		var contractId = d.contract.id;
		try {
			service.DistributionService.delete(d);
		} catch(e:Error){
			throw Error("/contractAdmin/distributions/" + contractId, e.message);
		}
		
		throw Ok("/contractAdmin/distributions/" + contractId, t._("The distribution has been deleted"));
	}

	/**
		Delete a Multidistribution
	**/
	function doDeleteMd(md:db.MultiDistrib){
		
		if (!app.user.canManageAllContracts()) throw Error('/', t._('Forbidden action') );

		if(checkToken()){
			try{
				service.DistributionService.deleteMd(md);
			}catch(e:Error){
				throw Error("/distribution",e.message);
			}
			throw Ok("/distribution",t._("The distribution has been deleted"));
		}else{
			throw Error("/distribution",t._("Bad token"));
		}
	}
	
	/**
		Edit a distribution
	 */
	@tpl('form.mtt')
	function doEdit(d:db.Distribution) {
		if (!app.user.isContractManager(d.contract)) throw Error('/', t._('Forbidden action') );		
		var contract = d.contract;
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("end"));
		form.removeElement(form.getElement("distributionCycleId"));
		var x = new sugoi.form.elements.HourDropDowns("end", t._("End time") ,d.end,true);
		form.addElement(x, 3);
		
		if (d.contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", t._("Orders opening date"), d.orderStartDate));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", t._("Orders closing date"), d.orderEndDate));
		}		
		
		if (form.isValid()) {

			var orderStartDate = null;
			var orderEndDate = null;
			try{
				if (d.contract.type == db.Contract.TYPE_VARORDER ) {
					orderStartDate = form.getValueOf("orderStartDate");
					orderEndDate = form.getValueOf("orderEndDate");
				}

				d = service.DistributionService.edit(d,
				form.getValueOf("date"),
				form.getValueOf("end"),
				form.getValueOf("placeId"),				
				orderStartDate,
				orderEndDate);
			} catch(e:Error){
				throw Error('/contractAdmin/distributions/' + contract.id,e.message);
			}
			
			if (d.date == null) {
				var msg = t._("The distribution has been proposed to the supplier, please wait for its validation");
				throw Ok('/contractAdmin/distributions/'+contract.id, msg );
			} else {
				throw Ok('/contractAdmin/distributions/'+contract.id, t._("The distribution has been recorded") );
			}
			
		} else {
			app.event(PreEditDistrib(d));
		}
		
		view.form = form;
		view.title = t._("Edit a distribution");
	}
	
	@tpl('form.mtt')
	function doEditCycle(d:db.DistributionCycle) {
		
		if (!app.user.isContractManager(d.contract)) throw Error('/', 'Action interdite');
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			d.update();
			throw Ok('/contractAdmin/distributions/'+d.contract.id, t._("The delivery is now up to date"));
		}
		
		view.form = form;
		view.title = t._("Modify a delivery");
	}
	
	/**
		Insert a distribution
	**/
	@tpl("form.mtt")
	public function doInsert(contract:db.Contract) {
		
		if (!app.user.isContractManager(contract)) throw Error('/', t._('Forbidden action') );
		
		var d = new db.Distribution();
		d.place = contract.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("distributionCycleId"));
		form.removeElement(form.getElement("end"));
		var x = new sugoi.form.elements.HourDropDowns("end", t._("End time") );
		form.addElement(x, 3);
		
		//default values
		form.getElement("date").value = DateTool.now().deltaDays(30).setHourMinute(19, 0);
		form.getElement("end").value = DateTool.now().deltaDays(30).setHourMinute(20, 0);
			
		if (contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", t._("Orders opening date"),DateTool.now().deltaDays(10).setHourMinute(8, 0)));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", t._("Orders closing date"),DateTool.now().deltaDays(20).setHourMinute(23, 59)));
		}
		
		if (form.isValid()) {

			var createdDistrib = null;
			var orderStartDate = null;
			var orderEndDate = null;

			try {
				
				if (contract.type == db.Contract.TYPE_VARORDER ) {
					orderStartDate = form.getValueOf("orderStartDate");
					orderEndDate = form.getValueOf("orderEndDate");
				}

				createdDistrib = service.DistributionService.create(
				contract,
				form.getValueOf("date"),
				form.getValueOf("end"),
				form.getValueOf("placeId"),
				orderStartDate,
				orderEndDate);
			}
			catch(e:tink.core.Error){
				throw Error('/contractAdmin/distributions/' + contract.id,e.message);
			}
			
			if (createdDistrib.date == null) {
				var html = t._("Your request for a delivery has been sent to <b>::supplierName::</b>.<br/>Be patient, you will receive an e-mail indicating if the request has been validated or refused.", {supplierName:contract.vendor.name});
				var btn = "<a href='/contractAdmin/distributions/" + contract.id + "' class='btn btn-primary'>OK</a>";
				App.current.view.extraNotifBlock = App.current.processTemplate("block/modal.mtt",{html:html,title:t._("Distribution request sent"),btn:btn} );
			} else {
				throw Ok('/contractAdmin/distributions/'+ createdDistrib.contract.id , t._("The distribution has been recorded") );	
			}
			
		}else{
			//event
			app.event(PreNewDistrib(contract));
		
		}
	
		view.form = form;
		view.title = t._("Create a distribution");
	}

	/**
		Insert a multidistribution
	**/
	@tpl("form.mtt")
	public function doInsertMd() {
		
		if (!app.user.canManageAllContracts()) throw Error('/', t._('Forbidden action') );
		
		var md = new db.MultiDistrib();
		md.place = app.user.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(md);
		form.removeElementByName("distribEndDate");
		var x = new sugoi.form.elements.HourDropDowns("distribEndDate", t._("End time") );
		form.addElement(x, 3);
		//form.removeElementByName("type");
		
		//default values
		form.getElement("distribStartDate").value 	= DateTool.now().deltaDays(30).setHourMinute(19, 0);
		form.getElement("distribEndDate").value 	= DateTool.now().deltaDays(30).setHourMinute(20, 0);

		//orders opening/closing	
		/*if (type == db.Contract.TYPE_CONSTORDERS ) {
			form.removeElementByName("orderStartDate");
			form.removeElementByName("orderEndDate");			
		}else{*/
			form.getElement("orderStartDate").value = DateTool.now().deltaDays(10).setHourMinute(8, 0);	
			form.getElement("orderEndDate").value = DateTool.now().deltaDays(20).setHourMinute(23, 59);
		//}

		//vendors to add
		//var label = type==db.Contract.TYPE_CONSTORDERS ? "Contrats AMAP" : "Commandes variables";
		var datas = [];
		for( c in md.place.amap.getActiveContracts()){
			datas.push({label:c.name+" - "+c.vendor.name,value:c.id});
		}
		var el = new sugoi.form.elements.CheckboxGroup("contracts",t._("Contrats"),datas,null,true);
		form.addElement(el);
		
		if (form.isValid()) {

			try {

				var distribStartDate = form.getValueOf("distribStartDate");
				var endDate = form.getValueOf("distribEndDate");			
				var distribEndDate = DateTool.setHourMinute( distribStartDate, endDate.getHours(), endDate.getMinutes() );
				
				md = service.DistributionService.createMd(
					db.Place.manager.get(form.getValueOf("placeId"),false),
					distribStartDate,
					distribEndDate,
					form.getValueOf("orderStartDate"),
					form.getValueOf("orderEndDate")
				);

				var contractIds:Array<Int> = form.getValueOf("contracts");
				
				for( cid in contractIds){
					var contract = db.Contract.manager.get(cid,false);
					service.DistributionService.participate(md,contract);
				}
			}
			catch(e:tink.core.Error) {

				throw Error('/distribution/insertMd/' ,e.message);
			}
			
			throw Ok('/distribution/volunteerRoles/' + md.id, t._("The distribution has been recorded") );	
		}
	
		view.form = form;
		view.title = t._("Create a general distribution");
	}

	/**
		Insert a multidistribution
	**/
	@tpl("form.mtt")
	public function doEditMd(md:db.MultiDistrib) {
		
		if (!app.user.canManageAllContracts()) throw Error('/', t._('Forbidden action') );
		
		md.place = app.user.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(md);
		form.removeElementByName("distribEndDate");
		var x = new sugoi.form.elements.HourDropDowns("distribEndDate", t._("End time"), md.distribEndDate );
		form.addElement(x, 3);
		//form.removeElementByName("type");
		
		//orders opening/closing	
		/*if (md.type == db.Contract.TYPE_CONSTORDERS ) {
			form.removeElementByName("orderStartDate");
			form.removeElementByName("orderEndDate");			
		}*/

		//contracts
		var label = "Contrats";//md.type==db.Contract.TYPE_CONSTORDERS ? "Contrats AMAP" : "Commandes variables";
		var datas = [];
		var checked = [];
		for( c in md.place.amap.getActiveContracts()){
			/*if( c.type==md.type)*/ datas.push({label:c.name+" - "+c.vendor.name,value:Std.string(c.id)});
		}
		var distributions = md.getDistributions();
		for( d in distributions){
			checked.push(Std.string(d.contract.id));
		}
		var el = new sugoi.form.elements.CheckboxGroup("contracts",label,datas,checked,true);
		form.addElement(el);
		
		if (form.isValid()) {

			try {
				service.DistributionService.editMd(
					md,
					db.Place.manager.get(form.getValueOf("placeId"),false),
					form.getValueOf("distribStartDate"),
					form.getValueOf("distribEndDate"),
					form.getValueOf("orderStartDate"),
					form.getValueOf("orderEndDate")
				);

				var contractIds:Array<Int> = form.getValueOf("contracts").map(Std.parseInt);
				for( cid in contractIds){
					var d = Lambda.find(distributions, function(d) return d.contract.id==cid );
					if(d==null){
						//create it
						var contract = db.Contract.manager.get(cid,false);
						service.DistributionService.participate(md,contract);
					}else{
						//update it
						d.lock();
						d.date = md.distribStartDate;
						d.end = md.distribEndDate;
						d.orderStartDate = md.orderStartDate;
						d.orderEndDate = md.orderEndDate;
						d.place = md.place;
						d.update();
					}
				}

				// delete it
				for( d in distributions){
					if(!Lambda.has(contractIds,d.contract.id)){
						service.DistributionService.delete(d);
					}
				}

			} catch(e:Error){
				throw Error('/distribution/editMd/'  ,e.message);
			}
			
			throw Ok('/distribution' , t._("The distribution has been updated") );	
		}
	
		view.form = form;
		view.title = t._("Edit a general distribution");
	}
	
	/**
	 * create a distribution cycle for a contract
	 */
	@tpl("form.mtt")
	public function doInsertCycle(contract:db.Contract) {
		
		if (!app.user.isContractManager(contract)) throw Error('/', t._("Forbidden action"));
		
		var dc = new db.DistributionCycle();
		dc.place = contract.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(dc);
		form.removeElementByName("contractId");
		
		form.getElement("startDate").value = DateTool.now();
		form.getElement("endDate").value  = DateTool.now().deltaDays(30);
		
		//start hour
		form.removeElementByName("startHour");
		var x = new HourDropDowns("startHour", t._("Start time"), DateTool.now().setHourMinute( 19, 0) , true);
		form.addElement(x, 5);
		
		//end hour
		form.removeElement(form.getElement("endHour"));
		var x = new HourDropDowns("endHour", t._("End time"), DateTool.now().setHourMinute(20, 0), true);
		form.addElement(x, 6);
		
		if (contract.type == db.Contract.TYPE_VARORDER){
			
			form.getElement("daysBeforeOrderStart").value = 10;
			form.getElement("daysBeforeOrderStart").required = true;
			form.removeElementByName("openingHour");
			var x = new HourDropDowns("openingHour", t._("Opening time"), DateTool.now().setHourMinute(8, 0) , true);
			form.addElement(x, 8);
			
			form.getElement("daysBeforeOrderEnd").value = 2;
			form.getElement("daysBeforeOrderEnd").required = true;
			form.removeElementByName("closingHour");
			var x = new HourDropDowns("closingHour", t._("Closing time"), DateTool.now().setHourMinute(23, 0) , true);
			form.addElement(x, 10);
			
		}else{
			
			form.removeElementByName("daysBeforeOrderStart");
			form.removeElementByName("daysBeforeOrderEnd");	
			form.removeElementByName("openingHour");
			form.removeElementByName("closingHour");
		}
		
		if (form.isValid()) {

			var createdDistribCycle = null;
			var daysBeforeOrderStart = null;
			var daysBeforeOrderEnd = null;
			var openingHour = null;
			var closingHour = null;

			try{
				
				if (contract.type == db.Contract.TYPE_VARORDER) {
					daysBeforeOrderStart = form.getValueOf("daysBeforeOrderStart");
					daysBeforeOrderEnd = form.getValueOf("daysBeforeOrderEnd");
					openingHour = form.getValueOf("openingHour");
					closingHour = form.getValueOf("closingHour");
				}

				createdDistribCycle = service.DistributionService.createCycle(
				contract,
				form.getElement("cycleType").getValue(),
				form.getValueOf("startDate"),	
				form.getValueOf("endDate"),	
				form.getValueOf("startHour"),
				form.getValueOf("endHour"),											
				daysBeforeOrderStart,											
				daysBeforeOrderEnd,											
				openingHour,	
				closingHour,																	
				form.getValueOf("placeId"));
			}
			catch(e:tink.core.Error){
				throw Error('/contractAdmin/distributions/' + contract.id,e.message);
			}

			if (createdDistribCycle != null) {
				throw Ok('/contractAdmin/distributions/'+ contract.id, t._("The delivery has been saved"));
			}
			 
		}
		else{
			dc.contract = contract;
			app.event(PreNewDistribCycle(dc));
		}
		
		view.form = form;
		view.title = t._("Schedule a recurrent delivery");
	}
	
	/**
	 *  Delete a distribution cycle
	 */
	public function doDeleteCycle(cycle:db.DistributionCycle){
		
		if (!app.user.isContractManager(cycle.contract)) throw Error('/', t._("Forbidden action"));

		var contractId = cycle.contract.id;
		var messages = service.DistributionService.deleteCycleDistribs(cycle);
		if (messages.length > 0){			
			App.current.session.addMessage( messages.join("<br/>"),true);	
		}
		
		throw Ok("/contractAdmin/distributions/" + contractId, t._("Recurrent deliveries deleted"));
	}
	
	/**
	 * Doodle-like participation planning
	 */
	@tpl("distribution/planning.mtt")
	public function doPlanning(contract:db.Contract) {
	
		view.contract = contract;

		var doodle = new Map<Int,{user:db.User,planning:Map<Int,Bool>}>();
		var distribs = contract.getDistribs(true, 150);
		
		for ( d in distribs ) {
			for (u in [d.distributor1, d.distributor2, d.distributor3, d.distributor4]) {
				if (u != null) {
					
					var udoodle = doodle.get(u.id);
					
					if (udoodle == null) udoodle = { user:u, planning:new Map<Int,Bool>() };
					udoodle.planning.set(d.id, true);
					doodle.set(u.id, udoodle);
				}
			}
		}
		view.distribs = distribs;
		view.doodle = doodle;
		
	}
	
	/**
	 * Ajax service for doPlanning()
	 */
	public function doRegister(args: { register:Bool, distrib:db.Distribution } ) {
		
		if (args != null) {
			var d = args.distrib;
			d.lock();
			
			if (args.register) {
				
				if (d.distributor1 == null) d.distributor1 = app.user;
				else if (d.distributor2 == null) d.distributor2 = app.user;
				else if (d.distributor3 == null) d.distributor3 = app.user;
				else if (d.distributor4 == null) d.distributor4 = app.user;
				
			}else {
				if (d.distributor1 == app.user) d.distributor1 = null;
				else if (d.distributor2 == app.user) d.distributor2 = null;
				else if (d.distributor3 == app.user) d.distributor3 = null;
				else if (d.distributor4 == app.user) d.distributor4 = null;
			}
			
			d.update();
		}
		
	}
	
	/**
	 * Validate a multi-distrib
	 * @param	date
	 * @param	place
	 */
	@tpl('distribution/validate.mtt')
	public function doValidate(multiDistrib:db.MultiDistrib){
		
		if (!app.user.isAmapManager()) throw t._("Forbidden access");	
			
		view.confirmed = multiDistrib.checkConfirmed();
		view.users = multiDistrib.getUsers(db.Contract.TYPE_VARORDER);
		view.distribution = multiDistrib;

	}


	/**
	 * Admin can autovalidate a multidistrib
	 */
	@admin
	public function doAutovalidate(date:Date,place:db.Place){

		var md = db.MultiDistrib.get(date,place);
		for ( d in md.getDistributions(db.Contract.TYPE_VARORDER)){
			if(d.validated) continue;
			service.PaymentService.validateDistribution(d);
		}	
		throw Ok("/contractAdmin",t._("This distribution have been validated"));
	}

	@admin
	public function doUnvalidate(date:Date,place:db.Place){

		var md = db.MultiDistrib.get(date,place);
		for ( d in md.getDistributions(db.Contract.TYPE_VARORDER)){
			if(!d.validated) continue;
			service.PaymentService.unvalidateDistribution(d);
		}	
		throw Ok("/contractAdmin",t._("This distribution have been Unvalidated"));
	}

	/**
	migrate to multidistribs
	**/
	@admin 
	function doMigrate1(){

		//MIGRATE to the new multidistrib Db architecture
		for( d in db.Distribution.manager.search($multiDistrib==null,{orderBy:-date,limit:10000},true)){

			//look for an existing md 3 hours around
			var from = DateTools.delta(d.date,1000.0*60*60*-3);
			var end = DateTools.delta(d.date,1000.0*60*60*3);
			if(d.contract==null) {
				trace(d.id+" has no contract<br/>");
				if(App.config.DEBUG) d.delete();
				continue;
			}
			if(d.date==null) {
				trace(d.id+" has no date<br/>");
				if(App.config.DEBUG) d.delete();
				continue;
			}
			var mds = db.MultiDistrib.manager.search($distribStartDate>=from && $distribStartDate<end && $place==d.place,true);
			if(mds.length>1) trace('too many mds !'+mds.length);
			var md : db.MultiDistrib = null;
			if(mds.length==0){
				
				//Create it
				md = new db.MultiDistrib();
				md.place = d.place;
				md.group = d.place.amap;
				md.distribStartDate = d.date;
				md.distribEndDate = d.end;
				md.orderStartDate = d.orderStartDate;
				md.orderEndDate = d.orderEndDate;
				md.insert();

			}else{
				md = mds.first();
			}

			//null identical fields
			/*
			if(md.distribStartDate.getTime()==d.date.getTime()) d.date = null;
			if(md.distribEndDate.getTime()==d.end.getTime()) d.end = null;
			if(md.orderStartDate!=null && md.orderStartDate.getTime()==d.orderStartDate.getTime()) d.orderStartDate = null;
			if(md.orderEndDate!=null && md.orderEndDate.getTime()==d.orderEndDate.getTime()) d.orderEndDate = null;			
			*/

			//bind to it
			d.multiDistrib = md;
			d.update();

			trace(d.toString()+"<br/>");
		}


		



	}
	
	/**
		migrate to new duty period mgmt
	**/
	@admin 
	function doMigrate2(){
		
		//update group params
		Sys.print("update group params and create roles.");
		for ( g in db.Amap.manager.all(true)){

			g.volunteersMailContent = "Rappel : Vous êtes inscrit(e) à la permanence du [DATE_DEBUT],<br/>
		Lieu de distribution : [LIEU]<br/>
		<br/>
		Voici la liste des bénévoles inscrits :<br/>
		[LISTE_BENEVOLES]<br/>";
		
			g.volunteersMailDaysBeforeDutyPeriod = 4;
			g.vacantVolunteerRolesMailDaysBeforeDutyPeriod = 7;
			g.daysBeforeDutyPeriodsOpen = 60;
			g.update();

			//create volunteers rôles
			for( c in g.getActiveContracts()){
				service.VolunteerService.createRoleForContract(c,c.distributorNum);
			}
		}

		//check all rôles for each MD
		Sys.print("check roles for multidistribs.");
		for(md in db.MultiDistrib.manager.all(true)){
			var roles = [];
			var allRoles = VolunteerService.getRolesFromGroup(md.group);
			///general roles
			//var generalRoles = Lambda.filter(allRoles, function(role) return role.contract == null);		
			//for( cr in generalRoles) roles.push(cr);
			//contract roles
			for ( distrib in md.getDistributions() ) {
				var cid = distrib.contract.id;
				var contractRoles = Lambda.filter(allRoles, function(role) return role.contract!=null && role.contract.id == cid);
				for( cr in contractRoles) roles.push(cr);
			}

			md.lock();
			md.volunteerRolesIds = Lambda.map(roles,function(r) return r.id).join(",");
			md.update();
		}

		Sys.print("migrate volunteer assignements.");
		//migre les inscriptions aux distribs
		for ( g in db.Amap.manager.all()){
			for( c in g.getActiveContracts()){
				var roles = Lambda.array(db.VolunteerRole.manager.search($contract==c));
				for ( d in c.getDistribs(false)){

					for( i in 1...5){

						var uid = Reflect.field(d,'distributor'+i+'Id');
						if( uid!=null && roles[i-1]!=null ){
							var user = db.User.manager.get(uid,false);
							try{
								//may fail for same volunteer on same md
								service.VolunteerService.addUserToRole(user,d.multiDistrib,roles[i-1]);
							}catch(e:Dynamic){}
						}

					}

				}
			}

		}
	}	


	//  Manage volunteer roles for the specified multidistrib
	@tpl("form.mtt")
	function doVolunteerRoles(distrib: db.MultiDistrib) {
		
		var form = new sugoi.form.Form("volunteerroles");

		var roles = [];

		//Get all the volunteer roles for the group and for the selected contracts
		var allVolunteerRoles = db.VolunteerRole.manager.search($group == distrib.group);
		
		var generalRoles = Lambda.filter(allVolunteerRoles, function(role) return role.contract == null);
		var checkedRoles = [];
		var roleIds = distrib.volunteerRolesIds != null ? distrib.volunteerRolesIds.split(",") : null;
		for ( role in generalRoles ) {

			roles.push( { label: role.name, value: Std.string(role.id) } );
			if ( roleIds == null || Lambda.has(roleIds, Std.string(role.id) ) ) {
				checkedRoles.push(Std.string(role.id));
			}
			
		}	

		//display roles linked to active contracts in this distrib
		for ( distrib in distrib.getDistributions() ) {
			var cid = distrib.contract.id;
			var contractRoles = Lambda.filter(allVolunteerRoles, function(role) return role.contract!=null && role.contract.id == cid);
			for ( role in contractRoles ) {
				roles.push( { label: role.name + " - " + distrib.contract.vendor.name, value: Std.string(role.id) } );
				if ( roleIds == null || Lambda.has(roleIds, Std.string(role.id)) ) {
					checkedRoles.push(Std.string(role.id));
				}
			}
		}
		
		var volunteerRolesCheckboxes = new sugoi.form.elements.CheckboxGroup("roles", "", roles, checkedRoles, true);
		form.addElement(volunteerRolesCheckboxes);
	                                                
		if (form.isValid()) {

			try {
				service.VolunteerService.updateMultiDistribVolunteerRoles( distrib, form.getValueOf("roles").join(",") );
			}
			catch(e: tink.core.Error){
				throw Error("/distribution/volunteerRoles/" + distrib.id, e.message);
			}

			throw Ok("/distribution", t._("Volunteer Roles have been saved for this distribution"));
		}

		view.title = t._("Select volunteer roles for this multidistrib");
		view.form = form;

	}

	//  Assign volunteer to roles for the specified multidistrib
	@tpl("form.mtt")
	function doVolunteers(distrib: db.MultiDistrib) {
		
		var form = new sugoi.form.Form("volunteers");

		var volunteerRoles = distrib.getVolunteerRoles();
		if ( volunteerRoles == null ) {

			throw Error('/distribution/volunteerRoles/' + distrib.id, t._("You need to first select the volunteer roles for this distribution") );
		}

		var members = Lambda.array(Lambda.map(app.user.amap.getMembers(), function(user) return { label: user.getName(), value: user.id } ));
		for ( role in volunteerRoles ) {

			var selectedVolunteer = distrib.getVolunteerForRole(db.VolunteerRole.manager.get(role.id));
			var selectedUserId = selectedVolunteer != null ? selectedVolunteer.user.id : null;
			form.addElement( new IntSelect(Std.string(role.id), db.VolunteerRole.manager.get(role.id).name, members, selectedUserId, false, t._("No volunteer assigned")) );
		}

		if (form.isValid()) {

			try {

				service.VolunteerService.updateVolunteers(distrib, form.getData());
			}
			catch(e: tink.core.Error){

				throw Error("/distribution/volunteers/" + distrib.id, e.message);
			}
			
			throw Ok("/distribution", t._("Volunteers have been assigned to roles for this distribution"));
		}

		view.title = t._("Select a volunteer for each role for this multidistrib");
		view.form = form;

	}

	//View volunteers list for this distribution and you can sign up for a role
	@tpl('distribution/volunteersSummary.mtt')
	function doVolunteersSummary(distrib: db.MultiDistrib, ?args: { role: db.VolunteerRole }) {

		var volunteerRoles: Array<db.VolunteerRole> = distrib.getVolunteerRoles();
		if (volunteerRoles == null) {

			throw Error('/distribution/', t._("There are no volunteer roles defined for this distribution") );
		}	

		if (args != null && args.role != null) {

			try {

				service.VolunteerService.addUserToRole(app.user, distrib, args.role);
			}
			catch(e: tink.core.Error){

				throw Error("/distribution/volunteersSummary/" + distrib.id, e.message);
			}
		
			throw Ok("/distribution/volunteersSummary/" + distrib.id, t._("You have been successfully added to the selected role."));
		}
		
		view.multidistrib = distrib;
		view.roles = volunteerRoles;	
	}

	//Remove user from role for the specified multidistrib
	@tpl("form.mtt")
	function doUnsubscribeFromRole(distrib: db.MultiDistrib, role: db.VolunteerRole, ?args: { returnUrl: String, ?to: String } ) {
		
		if ( args != null && args.returnUrl != null ) {

			var toArg = args.to != null ? "&to=" + args.to : "";
			App.current.session.data.volunteersReturnUrl = args.returnUrl + toArg;						
		}		
		
		var form = new sugoi.form.Form("unsubscribe");

		var returnUrl = App.current.session.data.volunteersReturnUrl != null ? App.current.session.data.volunteersReturnUrl : '/distribution/unsubscribeFromRole/' + distrib.id + '/' + role.id;
		
		var volunteer = distrib.getVolunteerForRole(role);
		if (volunteer == null) {

			throw Error( returnUrl, t._("There is no volunteer to remove for this role!") );
		}
		else if (volunteer.user.id != app.user.id) {

			throw Error( returnUrl, t._("You can only remove yourself from a role.") );

		}

		form.addElement( new TextArea("unsubscriptionreason", t._("Reason for leaving the role") , null, true, null, "style='width:500px;height:350px;'") );
			
		if (form.isValid()) {

			try {
				service.VolunteerService.removeUserFromRole( app.user, distrib, role, form.getValueOf("unsubscriptionreason") );
			}
			catch(e: tink.core.Error){
				throw Error( returnUrl, e.message );
			}
			
			throw Ok( returnUrl, t._("You have been successfully removed from this role.") );
		}

		view.title = t._("Enter the reason why you are leaving this role.");
		view.form = form;
	}

	//View volunteers planning for each role and multidistrib date
	@tpl('distribution/volunteersCalendar.mtt')
	function doVolunteersCalendar(?args: { ?distrib: db.MultiDistrib, ?role: db.VolunteerRole, ?from: Date, ?to: Date } ) {
		
		var multidistribs : Array<db.MultiDistrib> = [];
		var from: Date = null;
		var to: Date = null;

		if ( args != null ) {

			if ( args.distrib != null && args.role != null ) {

				try {

					service.VolunteerService.addUserToRole( app.user, args.distrib, args.role );
				}
				catch(e: tink.core.Error) {

					throw Error("/distribution/volunteersCalendar", e.message);
				}
		
				if ( args.from == null || args.to == null ) {

					throw Ok("/distribution/volunteersCalendar", t._("You have been successfully assigned to the selected role."));
				}
				else {

					throw Ok("/distribution/volunteersCalendar?from=" + args.from + "&to=" + args.to, t._("You have been successfully assigned to the selected role."));
				}
			}
			
			if ( args.from != null && args.to != null ) {

				from = args.from;
				to = args.to;
			}
		}

		if ( from == null || to == null ) {

			from = Date.now();
			to = DateTools.delta(from, 1000.0 * 60 * 60 * 24 * app.user.amap.daysBeforeDutyPeriodsOpen );			
		}

		multidistribs = db.MultiDistrib.getFromTimeRange( app.user.amap, from, to );
		
		//Let's find all the unique volunteer roles for this set of multidistribs	
		var uniqueRoles = [];
		for ( multidistrib in multidistribs ) {

			if (multidistrib.volunteerRolesIds != null) {

				var multidistribVolunteerRoles = multidistrib.getVolunteerRoles();
				for ( role in multidistribVolunteerRoles ) {

					if ( !Lambda.has(uniqueRoles, role) ) {

						uniqueRoles.push(role);								
					}					
				}				
			}
		}		

		view.multidistribs = multidistribs;
		uniqueRoles.sort(function(b, a) { return a.name.toLowerCase() < b.name.toLowerCase() ? 1 : -1; });
		view.uniqueRoles = uniqueRoles;
		view.initialUrl = args != null && args.from != null && args.to != null ? "/distribution/volunteersCalendar?from=" + args.from + "&to=" + args.to : "/distribution/volunteersCalendar";		
		view.from = from.toString().substr(0,10);
		view.to = to.toString().substr(0,10);		
	}
}