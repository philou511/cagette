package service;
import Common;
import tink.core.Error;
using tools.DateTool;

/**
 * Distribution Service
 * @author web-wizard
 */
class DistributionService
{
	/**
	 *  It will update the name of the operation with the new number of distributions
	 *  as well as the total amount
	 *  @param contract - 
	 */
	public static function updateAmapContractOperations(contract:db.Catalog) {

		//Update all operations for this amap contract when payments are enabled
		if (contract.type == db.Catalog.TYPE_CONSTORDERS && contract.group.hasPayments()) {
			//Get all the users who have orders for this contract
			var users = contract.getUsers();
			for ( user in users ){

				//Get the one operation for this amap contract and user
				var operation = db.Operation.findCOrderOperation(contract, user);

				if (operation != null)
				{
					//Get all the orders for this contract and user
					var orders = contract.getUserOrders(user);
					//Update this operation with the new number of distributions, this will affect the name of the operation
					//as well as the total amount to pay
					db.Operation.updateOrderOperation(operation, orders);
				}

			}
		}
	}


	public static function checkMultiDistrib(md:db.MultiDistrib){

		var t = sugoi.i18n.Locale.texts;

		if (md.distribStartDate==null) {
			throw new Error(t._("This distribution has no date."));
		}else{		
			//fix end date
			md.distribEndDate = new Date(md.distribStartDate.getFullYear(), md.distribStartDate.getMonth(), md.distribStartDate.getDate(), md.distribEndDate.getHours(), md.distribEndDate.getMinutes(), 0);
			md.update();
		}
	}
	
	/**
	 * checks if dates are correct and if that there is no other distribution in the same time range
	 *  and for the same contract and place
	 * @param d
	 */
	public static function checkDistrib(d:db.Distribution) {

		var t = sugoi.i18n.Locale.texts;
		var view = App.current.view;
		var c = d.catalog;

		if (d.date==null) {
			throw new Error(t._("This distribution has no date."));
		}
		if (c.type == db.Catalog.TYPE_VARORDER && (d.orderStartDate==null||d.orderEndDate==null)) {
			throw new Error(t._("This distribution should have an order opening date and an order closing date."));
		}	

		/*var distribs1;
		var distribs2;	
		var distribs3;	
		//We are checking that there is no existing distribution with an overlapping time frame for the same place and contract
		if (d.id == null) { //We need to check there the id as $id != null doesn't work in the manager.search
			//Looking for existing distributions with a time range overlapping the start of the about to be created distribution
			distribs1 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.date && $end >= d.date, false);
			//Looking for existing distributions with a time range overlapping the end of the about to be created distribution
			distribs2 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.end && $end >= d.end, false);	
			//Looking for existing distributions with a time range included in the time range of the about to be created distribution		
			distribs3 = db.Distribution.manager.search($contract == c && $place == d.place && $date >= d.date && $end <= d.end, false);	
		}
		else {
			//Looking for existing distributions with a time range overlapping the start of the about to be created distribution
			distribs1 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.date && $end >= d.date && $id != d.id, false);
			//Looking for existing distributions with a time range overlapping the end of the about to be created distribution
			distribs2 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.end && $end >= d.end && $id != d.id, false);	
			//Looking for existing distributions with a time range included in the time range of the about to be created distribution		
			distribs3 = db.Distribution.manager.search($contract == c && $place == d.place && $date >= d.date && $end <= d.end && $id != d.id, false);	
		}
			
		if (distribs1.length != 0 || distribs2.length != 0 || distribs3.length != 0) {
			throw new Error(t._("There is already a distribution at this place overlapping with the time range you've selected."));
		}*/
 
		if (d.date.getTime() > c.endDate.getTime()) throw new Error(t._("The date of the delivery must be prior to the end of the catalog (::contractEndDate::)", {contractEndDate:view.hDate(c.endDate)}));
		if (d.date.getTime() < c.startDate.getTime()) throw new Error(t._("The date of the delivery must be after the begining of the catalog (::contractBeginDate::)", {contractBeginDate:view.hDate(c.startDate)}));
		
		if (c.type == db.Catalog.TYPE_VARORDER ) {
			if (d.date.getTime() < d.orderEndDate.getTime() ) throw new Error(t._("The distribution start date must be set after the orders end date."));
			if (d.orderStartDate.getTime() > d.orderEndDate.getTime() ) throw new Error(t._("The orders end date must be set after the orders start date !"));
		}

	}

	 /**
	  *  Creates a new distribution and prevents distribution overlapping and other checks

	  *  @return db.Distribution
	  */
	 public static function create(contract:db.Catalog,date:Date,end:Date,placeId:Int,?orderStartDate:Date,?orderEndDate:Date,?distributionCycle:db.DistributionCycle,?dispatchEvent=true,?md:db.MultiDistrib):db.Distribution {

		var d = new db.Distribution();
		d.catalog = contract;
		d.date = date;
		d.place = db.Place.manager.get(placeId);
		//d.distributionCycle = distributionCycle;

		if(contract.type==db.Catalog.TYPE_VARORDER){
			d.orderStartDate = orderStartDate;
			d.orderEndDate = orderEndDate;
		}

		//end date cleaning			
		if (end == null) {
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 60);
		} else {
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), end.getHours(), end.getMinutes(), 0);
		} 
		
		//link to a multiDistrib
		if(md==null){
			md = db.MultiDistrib.get(d.date, d.place, true);
		}
		if(md==null){
			md = createMd(d.place, d.date, d.end, d.orderStartDate, d.orderEndDate,[] );
		}
		d.multiDistrib = md;

		//check role if needed
		var roles = service.VolunteerService.getRolesFromContract(contract);
		if(roles.length>0){			
			var roleIds = md.getVolunteerRoleIds();
			roleIds = roleIds.concat(roles.map( function(r) return r.id ));
			md.volunteerRolesIds = roleIds.join(",");
		}
		
		md.update();
		

		DistributionService.checkDistrib(d);
		
		if(distributionCycle == null && dispatchEvent) {
			var e :Event = NewDistrib(d);
			App.current.event(e);
		}
		
		if (d.date == null){
			return d;
		} else {
			d.insert();

			//In case this is a distrib for an amap contract with payments enabled, it will update all the operations
			//names and amounts with the new number of distribs
			updateAmapContractOperations(d.catalog);

			return d;
		}
	}

	public static function createMd(place:db.Place,distribStartDate:Date,distribEndDate:Date,orderStartDate:Date,orderEndDate:Date,contractIds:Array<Int>,?cycle:db.DistributionCycle):db.MultiDistrib{

		var md = db.MultiDistrib.get(distribStartDate,place,true);
		if(md==null){
			md = new db.MultiDistrib();
			md.group = place.group;
			md.place = place;
		}
		
		md.distribStartDate = distribStartDate;
		md.distribEndDate 	= distribEndDate;
		md.orderStartDate 	= orderStartDate;
		md.orderEndDate 	= orderEndDate;
		if(cycle!=null) md.distributionCycle = cycle;
		md.place = place;
		

		if(md.id!=null){

			//do not touch existing volunteerRolesIds

			md.update();

		} else {

			//add default general roles
			var roles = service.VolunteerService.getRolesFromGroup(place.group);
			var generalRoles = Lambda.array(Lambda.filter(roles,function(r) return r.catalog==null));
			md.volunteerRolesIds = generalRoles.map( function(r) return Std.string(r.id) ).join(",");

			md.insert();
		}
			

		checkMultiDistrib(md);

		for( cid in contractIds){
			var contract = db.Catalog.manager.get(cid,false);
			service.DistributionService.participate(md,contract);
		}

		return md;
	}

	/**
		Edit a multidistrib.		
	**/
	public static function editMd(md:db.MultiDistrib, place:db.Place,distribStartDate:Date,distribEndDate:Date,orderStartDate:Date,orderEndDate:Date):db.MultiDistrib{
		
		md.lock();
		md.distribStartDate = distribStartDate;
		md.distribEndDate 	= distribEndDate;
		md.orderStartDate 	= orderStartDate;
		md.orderEndDate 	= orderEndDate;
		md.place = place;
		md.update();

		checkMultiDistrib(md);

		//update related distributions
		for( d in md.getDistributions()){
			//sync distrib date
			d.lock();
			d.date =  d.date.setDateMonth(distribStartDate.getDate(),distribStartDate.getMonth()).setYear(distribStartDate.getFullYear());
			d.end = d.end.setDateMonth(distribStartDate.getDate(),distribStartDate.getMonth()).setYear(distribStartDate.getFullYear());
			d.update();

			//let opening/closing date untouched
		}

		return md;
	}

	/**
		Delete a multidistribution
	**/
	public static function deleteMd(md:db.MultiDistrib){
		var t = sugoi.i18n.Locale.texts;
		md.lock();
		for(d in md.getDistributions()){
			cancelParticipation(d,false);
		}
		md.delete();
	}

	/**
		Participate to a multidistrib.
	**/
	public static function participate(md:db.MultiDistrib,contract:db.Catalog){
		var t = sugoi.i18n.Locale.texts;
		md.lock();

		for( d in md.getDistributions()){
			if(d.catalog.id==contract.id){
				throw new Error(t._("This vendor is already participating to this distribution"));
			}
		}

		if( contract.type == db.Catalog.TYPE_VARORDER){
			if(md.orderStartDate==null || md.orderEndDate==null){
				var url = "/distribution/editMd/" + md.id;
				throw new Error(t._("You can't participate to this distribution because no order start date has been defined. <a href='::url::' target='_blank'>Please update the general distribution first</a>.",{url:url}));
			}
		}

		md.deleteProductsExcerpt();
		
		return create(contract,md.distribStartDate,md.distribEndDate,md.place.id,md.orderStartDate,md.orderEndDate,null,true,md);

	}

	 /**
	  *  Modifies an existing distribution and prevents distribution overlapping and other checks
	  	@deprecated !
	 */
	 public static function edit(d:db.Distribution,date:Date,end:Date,placeId:Int,orderStartDate:Date,orderEndDate:Date,?dispatchEvent=true):db.Distribution {

		//We prevent others from modifying it
		d.lock();
		var t = sugoi.i18n.Locale.texts;

		if(d.multiDistrib.validated) {
			throw new Error(t._("You cannot edit a distribution which has been already validated."));
		}

		//cannot change to a different date than the multidistrib
		if(date.toString().substr(0,10) != d.multiDistrib.distribStartDate.toString().substr(0,10) ){
			if(d.multiDistrib.getDistributions().length==1){
				//can change if its the only one
				d.multiDistrib.lock();
				d.multiDistrib.distribStartDate = date;
				d.multiDistrib.distribEndDate = end; 
				if(d.catalog.type==db.Catalog.TYPE_VARORDER){
					d.multiDistrib.orderStartDate = orderStartDate;
					d.multiDistrib.orderEndDate = orderEndDate;
				}
				d.multiDistrib.update();
			}else{
				throw new Error(t._("The distribution date is different from the date of the general distribution."));
			}
			
		}

		//cannot change the place
		if(placeId != d.multiDistrib.place.id ){
			if(d.multiDistrib.getDistributions().length==1){
				//can change if its the only one
				d.multiDistrib.lock();
				d.multiDistrib.place = db.Place.manager.get(placeId);
				d.multiDistrib.update();
			}else{
				throw new Error(t._("The distribution place is different from the place of the general distribution."));
			}			
		}

		d.date = date;
		d.place = db.Place.manager.get(placeId);
		if(d.catalog.type==db.Catalog.TYPE_VARORDER){
			d.orderStartDate = orderStartDate;
			d.orderEndDate = orderEndDate;
		}
					
		if (end == null) {
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 60);
		} else {
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), end.getHours(), end.getMinutes(), 0);
		} 
		
		checkDistrib(d);

		if(dispatchEvent) App.current.event(EditDistrib(d));
		
		if (d.date == null){
			return d;
		} else {
			d.update();
			return d;
		}
	}

	/**
		Edit attendance of a farmer to a distribution(md)
	**/
	public static function editAttendance(d:db.Distribution,md:db.MultiDistrib,/*distribStartHour:Date,distribEndHour:Date,*/orderStartDate:Date,orderEndDate:Date,?dispatchEvent=true):db.Distribution {

		//We prevent others from modifying it
		d.lock();
		var t = sugoi.i18n.Locale.texts;

		if(d.multiDistrib.validated) {
			throw new Error(t._("You cannot edit a distribution which has been already validated."));
		}

		if(md.id!=d.multiDistrib.id){
			/* 
			FORBID THIS WITH CREDIT CARD PAYMENTS 
			because it would make the order and payment ops out of sync
			*/
			var orders = d.getOrders();
			if(d.catalog.group.hasPayments() && orders.length>0){
				throw new Error(t._("Sorry, you can't move the distribution of this farmer to a different date when payments management is enabled in your group."));
			}

			//different multidistrib id ! should change the basket					
			for ( o in orders ){
				o.lock();
				//find new basket
				o.basket = db.Basket.getOrCreate(o.user, md);
				o.update();
			}
		}

		d.multiDistrib = md;
		//do not allow to customize distribution date anymore
		d.date = md.distribStartDate;
		d.end = md.distribEndDate;
		
		if(d.catalog.type==db.Catalog.TYPE_VARORDER){
			d.orderStartDate = orderStartDate;
			d.orderEndDate = orderEndDate;
		}
		
		checkDistrib(d);

		if(dispatchEvent) App.current.event(EditDistrib(d));
		
		if (d.date == null){
			return d;
		} else {
			d.update();
			return d;
		}
	}


	/**
	 *  Checks whether there are orders with non zero quantity for non amap contract
	 *  @param d - 
	 *  @return Bool
	 */
	public static function canDelete(d:db.Distribution):Bool{

		if (d.catalog.type == db.Catalog.TYPE_CONSTORDERS) return true;
		
		var quantity = 0.0;
		for ( order in d.getOrders() ){
			quantity += order.quantity;
		}
		return quantity == 0.0;
		
	}


	/**
	 *  Cancel participation of a farmer to a multidistrib
	 */
	public static function cancelParticipation(d:db.Distribution,?dispatchEvent=true) {
		var t = sugoi.i18n.Locale.texts;
		if ( !canDelete(d) ) {
			throw new Error(t._("Deletion not possible: orders are recorded for ::vendorName:: on ::date::.",{vendorName:d.catalog.vendor.name,date:Formatting.hDate(d.date)}));
		}

		var contract = d.catalog;
		d.lock();
		if (dispatchEvent) {
			App.current.event(DeleteDistrib(d));
		}

		//erase zero qt orders
		for ( order in d.getOrders() ){
			if(order.quantity==0.0 || order.quantity==0) {
				order.lock();
				order.delete();
			}
		}

		//uncheck volunteers roles
		var roles = service.VolunteerService.getRolesFromContract(d.catalog);
		if(roles.length>0){			
			var roleIds = d.multiDistrib.getVolunteerRoleIds();
			for( roleId in roleIds.copy()){
				
				if(Lambda.find(roles, function(r) return r.id==roleId)!=null){
					roleIds.remove(roleId);
				} 
			}
			d.multiDistrib.lock();
			d.multiDistrib.volunteerRolesIds = roleIds.join(",");
			d.multiDistrib.update();
		}

		d.multiDistrib.deleteProductsExcerpt();

		d.delete();

		//In case this is a distrib for an amap contract with payments enabled, it will update all the operations
		//names and amounts with the new number of distribs
		updateAmapContractOperations(contract);

		//delete multidistrib if needed
		/*if(d.multiDistrib!=null){
			if(d.multiDistrib.getDistributions().length == 0){
				deleteMd(d.multiDistrib);
			}
		}*/

	}

	/**
	 *  Computes the correct start and end dates
	 *  @param dc - 
	 *  @param datePointer - 
	 */
	public static function getDates(dc:db.DistributionCycle, datePointer:Date) {

		//Generic variables 
		var t = sugoi.i18n.Locale.texts;

		var startDate = new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.startHour.getHours(),dc.startHour.getMinutes(),0);
		var orderStartDate = null;
		var orderEndDate = null;
		//if (dc.contract.type == db.Catalog.TYPE_VARORDER){
			
			if (dc.daysBeforeOrderEnd == null || dc.daysBeforeOrderStart == null) throw new Error(t._("daysBeforeOrderEnd or daysBeforeOrderStart is null"));
			
			var a = DateTools.delta(startDate, -1.0 * dc.daysBeforeOrderStart * 1000 * 60 * 60 * 24);
			var h : Date = dc.openingHour;
			orderStartDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);
			
			var a = DateTools.delta(startDate, -1.0 * dc.daysBeforeOrderEnd * 1000 * 60 * 60 * 24);
			var h : Date = dc.closingHour;
			orderEndDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);			
		//}
		return { date: startDate, orderStartDate: orderStartDate, orderEndDate: orderEndDate };
	}

	/**
	 *  Creates all the distributions from the first date
	 *  @param dc - 
	 */
	static function createCycleDistribs(dc:db.DistributionCycle,contractIds:Array<Int>) {

		//Generic variables 
		var t = sugoi.i18n.Locale.texts;

		//switch end date to 23:59 to avoid the last distribution to be skipped
		dc.endDate = tools.DateTool.setHourMinute(dc.endDate,23,59);
		
		if (dc.id == null) throw new Error(t._("this distributionCycle has not been recorded"));
		
		//iterations
		//For first distrib
		var datePointer = new Date(dc.startDate.getFullYear(), dc.startDate.getMonth(), dc.startDate.getDate(), 12, 0, 0);
		//why hour=12 ? because if we set hour to 0, it switch to 23 (-1) or 1 (+1) on daylight saving time switch dates, thus changing the day!!
		var firstDistribDate = new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.startHour.getHours(),dc.startHour.getMinutes(),0);
		for(i in 0...100) {

			if(i != 0){ //All distribs except the first one
				var oneDay = 1000 * 60 * 60 * 24.0;
				switch(dc.cycleType) {
					case Weekly :
						datePointer = DateTools.delta(datePointer, oneDay * 7.0);
						//App.log("on ajoute "+(oneDay * 7.0)+"millisec pour ajouter 7 jours");
						//App.log('pointer : $datePointer');
						
					case BiWeekly : 	
						datePointer = DateTools.delta(datePointer, oneDay * 14.0);
						
					case TriWeekly : 	
						datePointer = DateTools.delta(datePointer, oneDay * 21.0);
						
					case Monthly :
						var n = tools.DateTool.getWhichNthDayOfMonth(firstDistribDate);
						var dayOfWeek = firstDistribDate.getDay();
						var nextMonth = new Date(datePointer.getFullYear(), datePointer.getMonth() + 1, 1, 0, 0, 0);
						datePointer = tools.DateTool.getNthDayOfMonth(nextMonth.getFullYear(), nextMonth.getMonth(), dayOfWeek, n);
						if (datePointer.getMonth() != nextMonth.getMonth()) {
							datePointer = tools.DateTool.getNthDayOfMonth(nextMonth.getFullYear(), nextMonth.getMonth(), dayOfWeek, n - 1);
						}
				}
			}
					
			//stop if cycle end is reached
			if (datePointer.getTime() > dc.endDate.getTime()) {				
				break;
			}
			
			var dates = getDates(dc, datePointer);
			
			createMd(
				dc.place,
				dates.date,
				new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.endHour.getHours(),dc.endHour.getMinutes(),0),
				dates.orderStartDate,
				dates.orderEndDate,
				contractIds,
				dc
			);

		}
	}
	
	/**
	 *   Deletes all distributions which are part of this cycle
	 *  @param cycle - 
	 */
	public static function deleteDistribCycle(cycle:db.DistributionCycle):Array<String>{

		cycle.lock();
		var messages = [];
		
		var children = db.MultiDistrib.manager.search($distributionCycle == cycle, true);
				
		for ( d in children ){			
			try{
				deleteMd(d);
			}catch(e:tink.core.Error){
				messages.push(e.message);
			}
		}

		cycle.delete();
		return messages;
	}

	 /**
	  *  Creates a new distribution cycle
	  */
	 public static function createCycle(group:db.Group,cycleType:db.DistributionCycle.CycleType,startDate:Date,endDate:Date,
	 startHour:Date,endHour:Date,daysBeforeOrderStart:Null<Int>,daysBeforeOrderEnd:Null<Int>,openingHour:Null<Date>,closingHour:Null<Date>,
	 placeId:Int,contractIds:Array<Int>):db.DistributionCycle {

		 //Generic variables 
		var t = sugoi.i18n.Locale.texts;
		var view = App.current.view;
		
		var dc = new db.DistributionCycle();
		dc.group = group;
		dc.cycleType = cycleType;
		dc.startDate = startDate;
		dc.endDate = endDate;
		dc.startHour = startHour;
		dc.endHour = endHour;
		dc.place = db.Place.manager.get(placeId);
		dc.daysBeforeOrderStart = daysBeforeOrderStart;
		dc.daysBeforeOrderEnd = daysBeforeOrderEnd;
		dc.openingHour = openingHour;
		dc.closingHour = closingHour;			
		
				
		/*if (dc.endDate.getTime() > contract.endDate.getTime()) {
			throw new Error(t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(contract.endDate)}));
		}
		if (dc.startDate.getTime() < contract.startDate.getTime()) {
			throw new Error(t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(contract.startDate)}));
		}*/

		/*if(dispatchEvent){
			App.current.event(NewDistribCycle(dc));
		}*/
		
		dc.insert();
		createCycleDistribs(dc,contractIds);

		return dc;

	}


}