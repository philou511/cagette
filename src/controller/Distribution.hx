package controller;
import db.UserContract;
import sugoi.form.Form;
import sugoi.form.elements.HourDropDowns;
using tools.DateTool;
import Common;

class Distribution extends Controller
{


	/**
	 * List to print (single distrib)
	 */
	@tpl('distribution/list.mtt')
	function doList(d:db.Distribution) {
		view.distrib = d;
		view.place = d.place;
		view.contract = d.contract;
		view.orders = UserContract.prepare(d.getOrders());
		
	}
	
	/**
	 * List to print ( mutidistrib )
	 */
	@tpl('distribution/listByDate.mtt')
	function doListByDate(date:Date,place:db.Place, ?type:String, ?fontSize:String) {
		
		if (!app.user.isContractManager()) throw Error('/', t._("Forbidden action"));
		
		view.place = place;
		
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
				case "M" : 125; //100x1.25
				case "L" : 156; //125x1.25
				case "XL": 195; //156x1.25
				default : 100;
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

			var orders3 = db.UserContract.prepare(Lambda.list(orders));
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
	
	function doDelete(d:db.Distribution) {
		
		if (!app.user.isContractManager(d.contract)) throw Error('/', t._("Forbidden action"));
		if ( !d.canDelete() ) throw Error("/contractAdmin/distributions/" + d.contract.id, t._("Deletion non possible: some orders are saved for this delivery."));
		
		d.lock();
		var cid = d.contract.id;
		app.event(DeleteDistrib(d));
		d.delete();
		
		throw Ok("/contractAdmin/distributions/" + cid, t._("the delivery has been deleted"));
	}
	
	/**
	 * Edit a distribution
	 */
	@tpl('form.mtt')
	function doEdit(d:db.Distribution) {
		if (!app.user.isContractManager(d.contract)) throw Error('/', t._('Forbidden action') );		
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("end"));
		form.removeElement(form.getElement("distributionCycleId"));
		var x = new sugoi.form.elements.HourDropDowns("end", t._("End time") ,d.end,true);
		form.addElement(x, 4);
		
		if (d.contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", t._("Orders opening date"), d.orderStartDate));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", t._("Orders closing date"), d.orderEndDate));
		}		
		
		if (form.isValid()) {

			try{
				d = service.DistributionService.edit(d,
				form.getValueOf("text"),
				form.getValueOf("date"),
				form.getValueOf("end"),
				form.getValueOf("placeId"),
				form.getValueOf("distributor1Id"),
				form.getValueOf("distributor2Id"),
				form.getValueOf("distributor3Id"),
				form.getValueOf("distributor4Id"),
				form.getValueOf("orderStartDate"),
				form.getValueOf("orderEndDate"));
			}
			catch(e:String){
				throw Error('/contractAdmin/distributions/' + d.contract.id,e);
			}
			
			if (d == null) {
				var msg = t._('The distribution has been proposed to the supplier, please wait for its validation');
				throw Ok('/contractAdmin/distributions/'+d.contract.id, msg );
			}
			else {
				throw Ok('/contractAdmin/distributions/'+d.contract.id, t._('The distribution has been recorded') );
			}
			
		}
		else {
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
	
	@tpl("form.mtt")
	public function doInsert(contract:db.Contract) {
		
		if (!app.user.isContractManager(contract)) throw Error('/', t._('Forbidden action') );
		
		var d = new db.Distribution();
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("distributionCycleId"));
		form.removeElement(form.getElement("end"));
		var x = new sugoi.form.elements.HourDropDowns("end", t._("End time") );
		form.addElement(x, 4);
		
		//default values
		form.getElement("date").value = DateTool.now().deltaDays(30).setHourMinute(19, 0);
		form.getElement("end").value = DateTool.now().deltaDays(30).setHourMinute(20, 0);
		
		if (contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", t._("Orders opening date"),DateTool.now().deltaDays(10).setHourMinute(8, 0)));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", t._("Orders closing date"),DateTool.now().deltaDays(20).setHourMinute(23, 59)));
		}
		
		if (form.isValid()) {

			var createdDistrib = null;

			try{
				createdDistrib = service.DistributionService.create(
				contract,
				form.getValueOf("text"),
				form.getValueOf("date"),
				form.getValueOf("end"),
				form.getValueOf("placeId"),
				form.getValueOf("distributor1Id"),
				form.getValueOf("distributor2Id"),
				form.getValueOf("distributor3Id"),
				form.getValueOf("distributor4Id"),
				form.getValueOf("orderStartDate"),
				form.getValueOf("orderEndDate"));
			}
			catch(e:String){
				throw Error('/contractAdmin/distributions/' + contract.id,e);
			}
			
			if (createdDistrib == null) {
				var html = t._("Your request for a delivery has been sent to <b>::supplierName::</b>.<br/>Be patient, you will receive an e-mail indicating if the request has been validated or refused.", {supplierName:contract.vendor.name});
				var btn = "<a href='/contractAdmin/distributions/" + contract.id + "' class='btn btn-primary'>OK</a>";
				App.current.view.extraNotifBlock = App.current.processTemplate("block/modal.mtt",{html:html,title:t._("Distribution request sent"),btn:btn} );
			}
			else {
				//throw Ok('/contractAdmin/distributions/'+ createdDistrib.contract.id , t._("The distribution has been recorded") );	
			}
			
		}else{
			//event
			app.event(PreNewDistrib(contract));
		
		}
	
		view.form = form;
		view.title = t._("Create a distribution");
	}
	
	/**
	 * create a distribution cycle for a contract
	 */
	@tpl("form.mtt")
	public function doInsertCycle(contract:db.Contract) {
		
		if (!app.user.isContractManager(contract)) throw Error('/', t._("Forbidden action"));
		
		var d = new db.DistributionCycle();
		var form = sugoi.form.Form.fromSpod(d);
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
			
			form.toSpod(d); //update model			
			d.contract = contract;
			
			app.event(NewDistribCycle(d));
			
			d.insert();
			
			var c = contract;

			if (d.endDate.getTime() > c.endDate.getTime()) throw Error('/contractAdmin/distributions/' + c.id, t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(c.endDate)}));
			if (d.startDate.getTime() < c.startDate.getTime()) throw Error('/contractAdmin/distributions/' + c.id, t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(c.startDate)}));

			db.DistributionCycle.updateChilds(d);
			
			throw Ok('/contractAdmin/distributions/'+d.contract.id, t._("The delivery has been saved"));
		}else{
			d.contract = contract;
			app.event(PreNewDistribCycle(d));
		}
		
		view.form = form;
		view.title = t._("Schedule a recurrent delivery");
	}
	
	/**
	 *  Delete a distribution cycle
	 */
	public function doDeleteCycle(cycle:db.DistributionCycle){
		
		if (!app.user.isContractManager(cycle.contract)) throw Error('/', t._("Forbidden action"));
		
		cycle.lock();
		var msgs = cycle.deleteChilds();
		if (msgs.length > 0){			
			throw Error("/contractAdmin/distributions/" + cycle.contract.id, msgs.join("<br/>"));	
		}else{			
			cycle.delete();
			throw Ok("/contractAdmin/distributions/" + cycle.contract.id, t._("Recurrent deliveries deleted"));
		}
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
	public function doValidate(date:Date, place:db.Place){
		
		if (!app.user.isAmapManager()) throw t._("Forbidden access");
		
		var md = MultiDistrib.get(date, place);
		
		view.confirmed = md.checkConfirmed();
		view.users = md.getUsers();
		view.date = date;
		view.place = place;
	}
	
	
	
}
