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
using Lambda;


class Distribution extends Controller
{

	public function new(){
		super();
		view.category = "distribution";
	}

	function checkHasDistributionSectionAccess(){
		if (!app.user.canManageAllContracts()) throw Error('/', t._('Forbidden action') );
	}

	@tpl('distribution/default.mtt')
	function doDefault(){

		checkHasDistributionSectionAccess();

		var now = Date.now();
		var yesterday = new Date(now.getFullYear(), now.getMonth(), now.getDate()-1, 0, 0, 0);
		var distribs = [];
		//Multidistribs
		if( app.user.amap.hasPayments() ){

			//include unvalidated distribs
			var twoMonthAgo = tools.DateTool.deltaDays(now,-60);
			var intwoMonth = tools.DateTool.deltaDays(now,60);			
			distribs = db.MultiDistrib.getFromTimeRange(app.user.amap,twoMonthAgo,intwoMonth);
			for( md in distribs.copy()){
				if( md.getDate().getTime() < yesterday.getTime() && md.isValidated() ) distribs.remove(md);				
			}
			

		}else{
			//only next distribs			
			var in3Month = DateTools.delta(yesterday, 1000.0 * 60 * 60 * 24 * 30 * 3);
			distribs = db.MultiDistrib.getFromTimeRange(app.user.amap,yesterday,in3Month);
		}

		view.distribs = distribs;
		view.cycles = db.DistributionCycle.manager.search( $group==app.user.amap && $endDate > now && $startDate < now , false);

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
		//volunteers whose role is linked to this contract
		view.volunteers = Lambda.filter(d.multiDistrib.getVolunteers(),function(v) return v.volunteerRole.contract!=null && v.volunteerRole.contract.id==d.contract.id);		
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
			var md = db.MultiDistrib.get(date,place);
			view.volunteers = md.getVolunteers();
			
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
		form.removeElementByName("placeId");
		form.removeElementByName("date");
		form.removeElementByName("end");
		form.removeElement(form.getElement("contractId"));		
		form.removeElement(form.getElement("distributionCycleId"));

		//date
		var threeMonthAgo = DateTools.delta(d.multiDistrib.distribStartDate ,-1000.0*60*60*24*30.5*3); 
		var inThreeMonth  = DateTools.delta(d.multiDistrib.distribStartDate , 1000.0*60*60*24*30.5*3); 
		var mds = db.MultiDistrib.getFromTimeRange(d.contract.amap,threeMonthAgo,inThreeMonth);
		
		var mds = mds.filter(function(md) return !md.isValidated() ).map(function(md) return {label:view.hDate(md.getDate()), value:md.id});
		var e = new sugoi.form.elements.IntSelect("md",t._("Change distribution"), mds ,d.multiDistrib.id);			
		form.addElement(e, 1);

		
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

				var md = db.MultiDistrib.manager.get(form.getValueOf("md"));
				
				//do not launch event, avoid notifs for now
				d = DistributionService.editAttendance(
					d,
					md,
					/*form.getValueOf("startHour"),
					form.getValueOf("endHour"),*/
					orderStartDate,
					orderEndDate,
					false
				);							
				

			} catch(e:Error){
				throw Error('/contractAdmin/distributions/' + contract.id,e.message);
			}
			
			if (d.date == null) {
				var msg = t._("The distribution has been proposed to the supplier, please wait for its validation");
				throw Ok('/contractAdmin/distributions/'+contract.id, msg );
			} else {

				if(app.user.isGroupManager() || app.user.canManageAllContracts() ){
					throw Ok('/distribution', t._("The distribution has been recorded") );
				}else{
					throw Ok('/contractAdmin/distributions/'+contract.id, t._("The distribution has been recorded") );
				}
			}
			
		} else {
			app.event(PreEditDistrib(d));
		}
		
		view.form = form;
		view.title = t._("Attendance of ::farmer:: to the ::date:: distribution",{farmer:d.contract.vendor.name,date:view.dDate(d.date)});
	}
	
	@tpl('form.mtt')
	function doEditCycle(d:db.DistributionCycle) {
		
		/*checkHasDistributionSectionAccess();
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			d.update();
			throw Ok('/contractAdmin/distributions/'+d.contract.id, t._("The delivery is now up to date"));
		}
		
		view.form = form;
		view.title = t._("Modify a delivery");*/
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
		
		checkHasDistributionSectionAccess();
		
		var md = new db.MultiDistrib();
		md.place = app.user.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(md);

		//date
		var e = new sugoi.form.elements.DatePicker("date",t._("Distribution date"), null);	
		untyped e.format = "LL";
		form.addElement(e, 3);
		
		//start hour
		form.removeElementByName("distribStartDate");
		var x = new sugoi.form.elements.HourDropDowns("startHour", t._("Start time") );
		form.addElement(x, 3);
		
		//end hour
		form.removeElementByName("distribEndDate");
		var x = new sugoi.form.elements.HourDropDowns("endHour", t._("End time") );
		form.addElement(x, 4);		
		
		//default values		
		form.getElement("date").value 				= DateTool.now().deltaDays(30);
		form.getElement("startHour").value 			= DateTool.now().deltaDays(30).setHourMinute(19, 0);
		form.getElement("endHour").value 			= DateTool.now().deltaDays(30).setHourMinute(20, 0);
		form.getElement("orderStartDate").value 	= DateTool.now().deltaDays(10).setHourMinute(8, 0);	
		form.getElement("orderEndDate").value 		= DateTool.now().deltaDays(20).setHourMinute(23, 59);
		
		//vendors to add
		var datas = [];
		for( c in md.place.amap.getActiveContracts()){
			datas.push({label:c.name+" - "+c.vendor.name,value:c.id});
		}
		var el = new sugoi.form.elements.CheckboxGroup("contracts",t._("Catalogs"),datas,null,true);
		form.addElement(el);
		
		if (form.isValid()) {

			try {
				var date = form.getValueOf("date");
				var startHour = form.getValueOf("startHour");
				var endHour = form.getValueOf("endHour");
				var distribStartDate = 	DateTool.setHourMinute( date, startHour.getHours(), startHour.getMinutes() );
				var distribEndDate = 	DateTool.setHourMinute( date, endHour.getHours(), 	endHour.getMinutes() );
				var contractIds:Array<Int> = form.getValueOf("contracts");
				
				md = service.DistributionService.createMd(
					db.Place.manager.get(form.getValueOf("placeId"),false),
					distribStartDate,
					distribEndDate,
					form.getValueOf("orderStartDate"),
					form.getValueOf("orderEndDate"),
					contractIds
				);
				
			}
			catch(e:tink.core.Error) {

				throw Error('/distribution/insertMd/' ,e.message);
			}
			
			if(service.VolunteerService.getRolesFromGroup(app.user.amap).length>0){
				throw Ok('/distribution/volunteerRoles/' + md.id, t._("The distribution has been recorded, please define which roles are needed.") );	
			}else{
				throw Ok('/distribution/', t._("The distribution has been recorded") );	
			}
			
		}
	
		view.form = form;
		view.title = t._("Create a general distribution");
	}

	/**
		Insert a multidistribution
	**/
	@tpl("form.mtt")
	public function doEditMd(md:db.MultiDistrib) {
		
		checkHasDistributionSectionAccess();
		
		md.place = app.user.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(md);

		//date
		var e = new sugoi.form.elements.DatePicker("date",t._("Distribution date"), md.distribStartDate);	
		untyped e.format = "LL";
		form.addElement(e, 3);
		
		//start hour
		form.removeElementByName("distribStartDate");
		var x = new sugoi.form.elements.HourDropDowns("startHour", t._("Start time"), md.distribStartDate );
		form.addElement(x, 3);
		
		//end hour
		form.removeElementByName("distribEndDate");
		var x = new sugoi.form.elements.HourDropDowns("endHour", t._("End time"), md.distribEndDate );
		form.addElement(x, 4);

		//override dates
		var overrideDates = new sugoi.form.elements.Checkbox("override","Recaler tous les producteurs sur ces horaires",false);		
		form.addElement(overrideDates,7);
		
		//contracts
		var label = t._("Contracts");
		var datas = [];
		var checked = [];
		for( c in md.place.amap.getActiveContracts()){
			datas.push({label:c.name+" - "+c.vendor.name,value:Std.string(c.id)});
		}
		var distributions = md.getDistributions();
		for( d in distributions){
			checked.push(Std.string(d.contract.id));
		}
		var el = new sugoi.form.elements.CheckboxGroup("contracts",label,datas,checked,true);
		form.addElement(el);
		
		if (form.isValid()) {

			try {

				var date = form.getValueOf("date");
				var startHour = form.getValueOf("startHour");
				var endHour = form.getValueOf("endHour");
				var distribStartDate = 	DateTool.setHourMinute( date, startHour.getHours(), startHour.getMinutes() );
				var distribEndDate = 	DateTool.setHourMinute( date, endHour.getHours(), 	endHour.getMinutes() );

				service.DistributionService.editMd(
					md,
					db.Place.manager.get(form.getValueOf("placeId"),false),
					distribStartDate,
					distribEndDate,
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
					}else if(form.getValueOf("override")==true){
						//override dates
						d.lock();
						d.date = md.distribStartDate;
						d.end = md.distribEndDate;
						d.orderStartDate = md.orderStartDate;
						d.orderEndDate = md.orderEndDate;
						d.place = md.place;						
						d.update();
					}else{
						//sync only place
						d.lock();
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
				throw Error('/distribution/editMd/'+md.id  ,e.message);
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
		
		/*if (!app.user.isContractManager(contract)) throw Error('/', t._("Forbidden action"));
		
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
		*/
	}

	/**
	 * create a multidistribution cycle
	 */
	@tpl("form.mtt")
	public function doInsertMdCycle() {		

		checkHasDistributionSectionAccess();
		
		var dc = new db.DistributionCycle();
		dc.place = app.user.amap.getMainPlace();
		var form = sugoi.form.Form.fromSpod(dc);
		
		
		form.getElement("startDate").value = DateTool.now();
		form.getElement("endDate").value   = DateTool.now().deltaDays(30);
		
		//start hour
		form.removeElementByName("startHour");
		var x = new HourDropDowns("startHour", t._("Distributions start time"), DateTool.now().setHourMinute( 19, 0) , true);
		form.addElement(x, 5);
		
		//end hour
		form.removeElement(form.getElement("endHour"));
		var x = new HourDropDowns("endHour", t._("Distributions end time"), DateTool.now().setHourMinute(20, 0), true);
		form.addElement(x, 6);
			
		form.getElement("daysBeforeOrderStart").value = 10;
		form.getElement("daysBeforeOrderStart").required = true;
		form.removeElementByName("openingHour");
		var x = new HourDropDowns("openingHour", t._("Opening time"), DateTool.now().setHourMinute(8, 0) , true);
		form.addElement(x, 8);
		
		form.getElement("daysBeforeOrderEnd").value = 2;
		form.getElement("daysBeforeOrderEnd").required = true;
		form.removeElementByName("closingHour");
		var x = new HourDropDowns("closingHour", t._("Closing time"), DateTool.now().setHourMinute(23, 55) , true);
		form.addElement(x, 10);

		//vendors to add
		var datas = [];
		for( c in app.user.amap.getActiveContracts()){
			datas.push({label:c.name+" - "+c.vendor.name,value:c.id});
		}
		var el = new sugoi.form.elements.CheckboxGroup("contracts",t._("Catalogs"),datas,null,true);
		form.addElement(el);
		
		
		if (form.isValid()) {

			var createdDistribCycle = null;
			var daysBeforeOrderStart = null;
			var daysBeforeOrderEnd = null;
			var openingHour = null;
			var closingHour = null;

			try{
				daysBeforeOrderStart = form.getValueOf("daysBeforeOrderStart");
				daysBeforeOrderEnd = form.getValueOf("daysBeforeOrderEnd");
				openingHour = form.getValueOf("openingHour");
				closingHour = form.getValueOf("closingHour");

				createdDistribCycle = service.DistributionService.createCycle(
					app.user.amap,
					form.getElement("cycleType").getValue(),
					form.getValueOf("startDate"),	
					form.getValueOf("endDate"),	
					form.getValueOf("startHour"),
					form.getValueOf("endHour"),											
					daysBeforeOrderStart,											
					daysBeforeOrderEnd,											
					openingHour,	
					closingHour,																	
					form.getValueOf("placeId"),
					form.getValueOf("contracts")

				);
			} catch(e:tink.core.Error){
				throw Error('/distribution/' , e.message);
			}

			if (createdDistribCycle != null) {
				throw Ok('/distribution/' , t._("The delivery has been saved"));
			}
			 
		}
		
		view.form = form;
		view.title = t._("Schedule a recurrent delivery");
	}
	
	/**
	 *  Delete a distribution cycle
	 */
	public function doDeleteCycle(cycle:db.DistributionCycle){
		
		checkHasDistributionSectionAccess();
		
		var messages = service.DistributionService.deleteDistribCycle(cycle);
		if (messages.length > 0){			
			App.current.session.addMessage( messages.join("<br/>"),true);	
		}
		
		throw Ok("/distribution/" , t._("Recurrent deliveries deleted"));
	}
	
	
	/**
	 * Validate a multiDistrib (main page)
	 * @param	date
	 * @param	place
	 */
	@tpl('distribution/validate.mtt')
	public function doValidate(multiDistrib:db.MultiDistrib){
		
		checkHasDistributionSectionAccess();
			
		view.confirmed = multiDistrib.checkConfirmed();
		view.users = multiDistrib.getUsers(db.Contract.TYPE_VARORDER);
		view.distribution = multiDistrib;

	}


	/**
	 * validate a multidistrib
	 */
	public function doAutovalidate(md:db.MultiDistrib){

		checkHasDistributionSectionAccess();

		for ( d in md.getDistributions()){
			if(d.validated) continue;
			try{
				service.PaymentService.validateDistribution(d);
			}catch(e:tink.core.Error){
				throw Error("/distribution/validate/"+md.id, e.message);
			}
			
		}	
		throw Ok( "/distribution/validate/"+md.id , t._("This distribution have been validated") );
	}

	@admin
	public function doUnvalidate(md:db.MultiDistrib){

		for ( d in md.getDistributions(db.Contract.TYPE_VARORDER)){
			if(!d.validated) continue;
			service.PaymentService.unvalidateDistribution(d);
		}	
		throw Ok("/contractAdmin",t._("This distribution have been Unvalidated"));
	}

	/**
		Manage volunteer roles for the specified multidistrib
	**/ 
	@tpl("form.mtt")
	function doVolunteerRoles(distrib: db.MultiDistrib) {
		
		var form = new sugoi.form.Form("volunteerroles");

		var roles = [];

		//Get all the volunteer roles for the group and for the selected contracts
		var allRoles = VolunteerService.getRolesFromGroup(distrib.getGroup());
		var generalRoles = Lambda.filter(allRoles, function(role) return role.contract == null);
		var checkedRoles = new Array<String>();
		var roleIds : Array<Int> = distrib.volunteerRolesIds != null ? distrib.volunteerRolesIds.split(",").map(Std.parseInt) : [];
		
		//general roles
		for ( role in generalRoles ) {
			roles.push( { label: role.name, value: Std.string(role.id) } );
			if ( Lambda.has(roleIds, role.id) ) {
				checkedRoles.push(Std.string(role.id));
			}			
		}	

		//display roles linked to active contracts in this distrib
		for ( distrib in distrib.getDistributions() ) {
			var cid = distrib.contract.id;
			var contractRoles = Lambda.filter(allRoles, function(role) return role.contract!=null && role.contract.id == cid);
			for ( role in contractRoles ) {
				roles.push( { label: role.name + " - " + distrib.contract.vendor.name, value: Std.string(role.id) } );
				if ( roleIds == null || Lambda.has(roleIds, role.id) ) {
					checkedRoles.push(Std.string(role.id));
				}
			}
		}
		
		var volunteerRolesCheckboxes = new sugoi.form.elements.CheckboxGroup("roles", "", roles, checkedRoles, true);
		form.addElement(volunteerRolesCheckboxes);
	                                                
		if (form.isValid()) {

			try {
				var roleIds : Array<Int> = form.getValueOf("roles").map(Std.parseInt);
				service.VolunteerService.updateMultiDistribVolunteerRoles( distrib, roleIds );
			}
			catch(e: tink.core.Error){
				throw Error("/distribution/volunteerRoles/" + distrib.id, e.message);
			}

			throw Ok("/distribution", t._("Volunteer Roles have been saved for this distribution"));
		}

		view.title = t._("Select volunteer roles for this multidistrib");
		view.form = form;

	}

	/**
		Assign volunteer to roles for the specified multidistrib
	**/  
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
				var roleIdsToUserIds = new Map<Int,Int>();
				var datas = form.getData();
				for( k in datas.keys() ) roleIdsToUserIds[Std.parseInt(k)] = datas[k];  
				service.VolunteerService.updateVolunteers(distrib, roleIdsToUserIds );
			} catch(e: tink.core.Error){
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
		
			throw Ok("/home/", t._("You have been successfully added to the selected role."));
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
		} else if (volunteer.user.id != app.user.id) {
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

	/**
		Members can view volunteers planning for each role and multidistrib date
	**/
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
				} else {
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
		uniqueRoles.sort(function(b, a) { 
			var a_str = (a.contract == null ? "null" : Std.string(a.contract.id)) + a.name.toLowerCase();
			var b_str = (b.contract == null ? "null" : Std.string(b.contract.id)) + b.name.toLowerCase();
			return  a_str < b_str ? 1 : -1;
		});
		view.uniqueRoles = uniqueRoles;
		view.initialUrl = args != null && args.from != null && args.to != null ? "/distribution/volunteersCalendar?from=" + args.from + "&to=" + args.to : "/distribution/volunteersCalendar";		
		view.from = from.toString().substr(0,10);
		view.to = to.toString().substr(0,10);

		//duty periods user's participation	
		var me = app.user;
		var timeframe = me.amap.getMembershipTimeframe(Date.now());
		view.timeframe = timeframe;	

		var multiDistribs = db.MultiDistrib.getFromTimeRange( me.amap, timeframe.from, timeframe.to );
		var members = me.amap.getMembers();
		var genericRolesDone = 0;
		var genericRolesToBeDone = 0;
		var contractRolesDone = 0;
		var contractRolesToBeDone = 0;
		var contractRolesToBeDoneByContractId = new Map<Int,Int>();
		var membersNumByContractId = new Map<Int,Int>();
		var membersListByContractId = new Map<Int,Array<db.User>>();
		for( md in multiDistribs ){
			var roles = md.getVolunteerRoles();
			for( role in roles){
				if(role.isGenericRole()){
					genericRolesToBeDone++;
				}else{
					if(contractRolesToBeDoneByContractId[role.contract.id]==null){
						contractRolesToBeDoneByContractId[role.contract.id]=1; 
					} else {
						contractRolesToBeDoneByContractId[role.contract.id]++;
					}
				}
			}
		}

		//contract roles
		for( cid in contractRolesToBeDoneByContractId.keys()) membersListByContractId[cid] = [];

		for(md in multiDistribs){

			//populate member list by contract id
			for( d in md.getDistributions()){
				if(membersListByContractId[d.contract.id]==null){
					//this contract has no roles
					continue;
				}
				for( u in members){
					if(d.hasUserOrders(u)){
						membersListByContractId[d.contract.id].push(u);
					} 
				}
			}

			//volunteers			
			for( v in md.getVolunteers()){
				if(v.user.id!=me.id) continue;
				if(v.volunteerRole.isGenericRole()){
					genericRolesDone++;
				}else{
					contractRolesDone++;
				}
			}
		}

		//roles to be done spread over members
		genericRolesToBeDone = Math.ceil(genericRolesToBeDone / members.length);
		for( cid in membersListByContractId.keys()){
			membersListByContractId[cid] = tools.ObjectListTool.deduplicate(membersListByContractId[cid]);
			membersNumByContractId[cid] = membersListByContractId[cid].length;
		}

		
		for( cid in membersListByContractId.keys()){
			//if this user is involved in this contract
			if(Lambda.find(membersListByContractId[cid],function(u)return u.id==me.id)!=null){
				//role to be done for this user = contract roles to be done for this contract / members num involved in this contract
				contractRolesToBeDone +=  Math.ceil( contractRolesToBeDoneByContractId[cid] / membersNumByContractId[cid] );
			}
		}

		view.toBeDone = genericRolesToBeDone + contractRolesToBeDone;
		view.done = genericRolesDone + contractRolesDone;
		
	}


	/**
		Members can view volunteers planning for each role and multidistrib date
	**/
	@tpl('distribution/volunteersParticipation.mtt')
	function doVolunteersParticipation(?args: { ?from: Date, ?to: Date } ) {
				
		var from: Date = null;
		var to: Date = null;

		if ( args != null ) {
			if ( args.from != null && args.to != null ) {
				from = args.from;
				to = args.to;
			}
		}

		if ( from == null || to == null ) {
			var timeframe = app.user.amap.getMembershipTimeframe(Date.now());
			from = timeframe.from;
			to = timeframe.to;
		}

		var multiDistribs = db.MultiDistrib.getFromTimeRange( app.user.amap, from, to );
		var members = app.user.amap.getMembers();

		//init + generic roles
		var totalRolesToBeDone = 0;	
		var totalRolesDone = 0;
		var genericRolesToBeDone = 0;
		var genericRolesDoneByMemberId = new Map<Int,Int>();
		var contractRolesDoneByMemberId = new Map<Int,Int>();
		var contractRolesToBeDoneByMemberId = new Map<Int,Int>();
		var contractRolesToBeDoneByContractId = new Map<Int,Int>();
		var membersNumByContractId = new Map<Int,Int>();
		var membersListByContractId = new Map<Int,Array<db.User>>();
		for( u in members ){
			genericRolesDoneByMemberId[u.id] = 0;
			contractRolesDoneByMemberId[u.id] = 0;
			contractRolesToBeDoneByMemberId[u.id] = 0;
		}
		for( md in multiDistribs ){
			var roles = md.getVolunteerRoles();
			for( role in roles){
				totalRolesToBeDone ++;
				if(role.isGenericRole()){
					genericRolesToBeDone++;
				}else{
					if(contractRolesToBeDoneByContractId[role.contract.id]==null){
						contractRolesToBeDoneByContractId[role.contract.id]=1; 
					} else {
						contractRolesToBeDoneByContractId[role.contract.id]++;
					}
				}
			}
		}

		//contract roles
		for( cid in contractRolesToBeDoneByContractId.keys()) membersListByContractId[cid] = [];

		for(md in multiDistribs){

			//populate member list by contract id
			for( d in md.getDistributions()){
				if(membersListByContractId[d.contract.id]==null){
					//this contract has no roles
					continue;
				}
				for( u in members){
					if(d.hasUserOrders(u)){
					//if(d.getUserOrders(u).length>0){
						membersListByContractId[d.contract.id].push(u);
					} 
				}
			}

			//volunteers			
			for( v in md.getVolunteers()){
				totalRolesDone++;
				if(v.volunteerRole.isGenericRole()){
					genericRolesDoneByMemberId[v.user.id]++;
				}else{
					contractRolesDoneByMemberId[v.user.id]++;
				}
			}
			

		}

		//roles to be done spread over members
		genericRolesToBeDone = Math.ceil(genericRolesToBeDone / members.length);
		for( cid in membersListByContractId.keys()){
			membersListByContractId[cid] = tools.ObjectListTool.deduplicate(membersListByContractId[cid]);
			membersNumByContractId[cid] = membersListByContractId[cid].length;
		}

		for( m in members){
			for( cid in membersListByContractId.keys()){
				//if this user is involved in this contract
				if(Lambda.find(membersListByContractId[cid],function(u)return u.id==m.id)!=null){
					//role to be done for this user = contract roles to be done for this contract / members num involved in this contract
					contractRolesToBeDoneByMemberId[m.id] +=  Math.ceil( contractRolesToBeDoneByContractId[cid] / membersNumByContractId[cid] );
				}
			}
		}

		view.members = members;
		view.multiDistribs = multiDistribs;
		view.genericRolesToBeDone = genericRolesToBeDone;
		view.genericRolesDoneByMemberId = genericRolesDoneByMemberId;
		view.contractRolesDoneByMemberId = contractRolesDoneByMemberId;
		view.contractRolesToBeDoneByMemberId = contractRolesToBeDoneByMemberId;
		view.totalRolesToBeDone = totalRolesToBeDone;
		view.totalRolesDone = totalRolesDone;
		
		view.initialUrl = args != null && args.from != null && args.to != null ? "/distribution/volunteersCalendar?from=" + args.from + "&to=" + args.to : "/distribution/volunteersCalendar";		
		view.from = from.toString().substr(0,10);
		view.to = to.toString().substr(0,10);		
	}
}