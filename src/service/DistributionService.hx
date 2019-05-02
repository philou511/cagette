package service;
import Common;
import tink.core.Error;

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
	public static function updateAmapContractOperations(contract:db.Contract) {

		//Update all operations for this amap contract when payments are enabled
		if (contract.type == db.Contract.TYPE_CONSTORDERS && contract.amap.hasPayments()) {
			//Get all the users who have orders for this contract
			var users = contract.getUsers();
			for ( user in users ){

				//Get the one operation for this amap contract and user
				var operation = db.Operation.findCOrderTransactionFor(contract, user);

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

	
	/**
	 * checks if dates are correct and if that there is no other distribution in the same time range
	 *  and for the same contract and place
	 * @param d
	 */
	public static function checkDistrib(d:db.Distribution) {

		var t = sugoi.i18n.Locale.texts;
		var view = App.current.view;
		var c = d.contract;

		if (d.date==null) {
			throw new Error(t._("This distribution has no date."));
		}
		if (c.type == db.Contract.TYPE_VARORDER && (d.orderStartDate==null||d.orderEndDate==null)) {
			throw new Error(t._("This distribution should have an order opening date and an order closing date."));
		}	

		var distribs1;
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
		}
 
		if (d.date.getTime() > c.endDate.getTime()) throw new Error(t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(c.endDate)}));
		if (d.date.getTime() < c.startDate.getTime()) throw new Error(t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(c.startDate)}));
		
		if (c.type == db.Contract.TYPE_VARORDER ) {
			if (d.date.getTime() < d.orderEndDate.getTime() ) throw new Error(t._("The distribution start date must be set after the orders end date."));
			if (d.orderStartDate.getTime() > d.orderEndDate.getTime() ) throw new Error(t._("The orders end date must be set after the orders start date !"));
		}

	}

	 /**
	  *  Creates a new distribution and prevents distribution overlapping and other checks
	  *  @param contract - 
	  *  @param date - 
	  *  @param end - 
	  *  @param placeId - 
	  *  @param distributor1Id - 
	  *  @param distributor2Id - 
	  *  @param distributor3Id - 
	  *  @param distributor4Id - 
	  *  @param orderStartDate - 
	  *  @param orderEndDate - 
	  *  @param distributionCycle - 
	  *  @param dispatchEvent=true - 
	  *  @return db.Distribution
	  */
	 public static function create(contract:db.Contract,date:Date,end:Date,placeId:Int,
	 	?distributor1Id:Int,?distributor2Id:Int,?distributor3Id:Int,?distributor4Id:Int,
		?orderStartDate:Date,?orderEndDate:Date,?distributionCycle:db.DistributionCycle,?dispatchEvent=true,?md:db.MultiDistrib):db.Distribution {

		var d = new db.Distribution();
		d.contract = contract;
		d.date = date;
		d.place = db.Place.manager.get(placeId);
		d.distributionCycle = distributionCycle;
		if(distributor1Id != null) d.distributor1 = db.User.manager.get(distributor1Id);
		if(distributor2Id != null) d.distributor2 = db.User.manager.get(distributor2Id);
		if(distributor3Id != null) d.distributor3 = db.User.manager.get(distributor3Id);
		if(distributor4Id != null) d.distributor4 = db.User.manager.get(distributor4Id);
		if(contract.type==db.Contract.TYPE_VARORDER){
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
			md = db.MultiDistrib.get(d.date, d.place, d.contract.type);
		}
		if(md==null){
			md = createMd(d.place,d.contract.type, d.date, d.end, d.orderStartDate, d.orderEndDate );
		}
		d.multiDistrib = md;

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
			updateAmapContractOperations(d.contract);

			return d;
		}
	}

	public static function createMd(place:db.Place,type:Int,distribStartDate:Date,distribEndDate:Date,orderStartDate:Date,orderEndDate:Date):db.MultiDistrib{

		var md = new db.MultiDistrib();
		md.distribStartDate = distribStartDate;
		md.distribEndDate 	= distribEndDate;
		if(type==db.Contract.TYPE_VARORDER){
			md.orderStartDate 	= orderStartDate;
			md.orderEndDate 	= orderEndDate;
		}		
		md.place 			= place;
		md.type 			= type;
		md.insert();
		return md;
	}

	public static function deleteMd(md:db.MultiDistrib){
		var t = sugoi.i18n.Locale.texts;
		md.lock();
		for(d in md.getDistributions()){
			if(!canDelete(d)) {
				throw new Error(t._("Deletion non possible: some orders are saved for this delivery."));
			}else{
				d.lock();
				d.delete();
			}
		}

		md.delete();
	}

	public static function participate(md:db.MultiDistrib,contract:db.Contract){
		
		return create(contract,md.distribStartDate,md.distribEndDate,md.place.id,
			null,null,null,null,md.orderStartDate,md.orderEndDate,null,false,md
		);

	}

	 /**
	  *  Modifies an existing distribution and prevents distribution overlapping and other checks
	  *  @param d - 
	  *  @param date - 
	  *  @param end - 
	  *  @param placeId - 
	  *  @param distributor1Id - 
	  *  @param distributor2Id - 
	  *  @param distributor3Id - 
	  *  @param distributor4Id - 
	  *  @param orderStartDate - 
	  *  @param orderEndDate - 
	  *  @return db.Distribution
	  */
	 public static function edit(d:db.Distribution,date:Date,end:Date,placeId:Int,
	 	distributor1Id:Int,distributor2Id:Int,distributor3Id:Int,distributor4Id:Int,
		orderStartDate:Date,orderEndDate:Date,?dispatchEvent=true):db.Distribution {

		//We prevent others from modifying it
		d.lock();
		var t = sugoi.i18n.Locale.texts;

		if(d.validated) {
			throw new Error(t._("You cannot edit a distribution which has been already validated."));
		}

		//cannot change to a different date than the multidistrib
		if(date.toString().substr(0,10) != d.multiDistrib.distribStartDate.toString().substr(0,10) ){
			throw new Error(t._("The distribution date is different from the date of the general distribution."));
		}
		//cannot change the place
		if(placeId != d.multiDistrib.place.id ){
			throw new Error(t._("The distribution place is different from the place of the general distribution."));
		}

		d.date = date;
		d.place = db.Place.manager.get(placeId);
		d.distributor1 = db.User.manager.get(distributor1Id);
		d.distributor2 = db.User.manager.get(distributor2Id);
		d.distributor3 = db.User.manager.get(distributor3Id);
		d.distributor4 = db.User.manager.get(distributor4Id);
		if(d.contract.type==db.Contract.TYPE_VARORDER){
			d.orderStartDate = orderStartDate;
			d.orderEndDate = orderEndDate;
		}
					
		if (end == null) {
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 60);
		}
		else {
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
	 *  Checks whether there are orders with non zero quantity for non amap contract
	 *  @param d - 
	 *  @return Bool
	 */
	public static function canDelete(d:db.Distribution):Bool{

		if (d.contract.type == db.Contract.TYPE_CONSTORDERS) return true;
		
		var quantity = 0.0;
		for ( order in d.getOrders() ){
			quantity += order.quantity;
		}
		return quantity == 0.0;
		
	}


	/**
	 *  Deletes a distribution
	 *  @param d - 
	 *  @param dispatchEvent=true - 
	 */
	public static function delete(d:db.Distribution,?dispatchEvent=true) {
		var t = sugoi.i18n.Locale.texts;
		if ( !canDelete(d) ) {
			throw new Error(t._("Deletion non possible: some orders are saved for this delivery."));
		}

		var contract = d.contract;
		d.lock();
		if (dispatchEvent) {
			App.current.event(DeleteDistrib(d));
		}
		d.delete();

		//In case this is a distrib for an amap contract with payments enabled, it will update all the operations
		//names and amounts with the new number of distribs
		updateAmapContractOperations(contract);

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
		if (dc.contract.type == db.Contract.TYPE_VARORDER){
			
			if (dc.daysBeforeOrderEnd == null || dc.daysBeforeOrderStart == null) throw new Error(t._("daysBeforeOrderEnd or daysBeforeOrderStart is null"));
			
			var a = DateTools.delta(startDate, -1.0 * dc.daysBeforeOrderStart * 1000 * 60 * 60 * 24);
			var h : Date = dc.openingHour;
			orderStartDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);
			
			var a = DateTools.delta(startDate, -1.0 * dc.daysBeforeOrderEnd * 1000 * 60 * 60 * 24);
			var h : Date = dc.closingHour;
			orderEndDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);			
		}
		return { date: startDate, orderStartDate: orderStartDate, orderEndDate: orderEndDate };
	}

	/**
	 *  Creates all the distributions from the first date
	 *  @param dc - 
	 */
	static function createCycleDistribs(dc:db.DistributionCycle) {

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
			
			create(dc.contract,dates.date,
				new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.endHour.getHours(),dc.endHour.getMinutes(),0),
				dc.place.id,null,null,null,null,dates.orderStartDate,dates.orderEndDate,dc
			);

		}
	}
	
	/**
	 *   Deletes all distributions which are part of this cycle
	 *  @param cycle - 
	 */
	public static function deleteCycleDistribs(cycle:db.DistributionCycle){

		cycle.lock();

		//Generic variables 
		var t = sugoi.i18n.Locale.texts;
		var view = App.current.view;
		
		var children = db.Distribution.manager.search($distributionCycle == cycle, true);
		var messages = [];
		if(children.length != 0) {

			var contract = Lambda.array(children)[0].contract;
			for ( d in children ){
			
				if (d.contract.type == db.Contract.TYPE_VARORDER && !canDelete(d) ){
					messages.push(t._("The delivery of the ::delivDate:: could not be deleted because it has orders.", {delivDate:view.hDate(d.date)}));
				}else{
					d.delete();
				}
			}

			//In case this is a distrib cycle for an amap contract with payments enabled, it will update all the operations
			//names and amounts with the new number of distribs
			updateAmapContractOperations(contract);

		}
		cycle.delete();
		
		return messages;
	}

	 /**
	  *  Creates a new distribution cycle and prevents distribution overlapping and other checks
	  *  @param contract - 
	  *  @param cycleType - 
	  *  @param startDate - 
	  *  @param endDate - 
	  *  @param startHour - 
	  *  @param endHour - 
	  *  @param daysBeforeOrderStart - 
	  *  @param daysBeforeOrderEnd - 
	  *  @param openingHour - 
	  *  @param closingHour - 
	  *  @param placeId - 
	  *  @param dispatchEvent=true - 
	  *  @return db.DistributionCycle
	  */
	 public static function createCycle(contract:db.Contract,cycleType:db.DistributionCycle.CycleType,startDate:Date,endDate:Date,
	 startHour:Date,endHour:Date,daysBeforeOrderStart:Null<Int>,daysBeforeOrderEnd:Null<Int>,openingHour:Null<Date>,closingHour:Null<Date>,
	 placeId:Int,?dispatchEvent=true):db.DistributionCycle {

		 //Generic variables 
		var t = sugoi.i18n.Locale.texts;
		var view = App.current.view;
		
		var dc = new db.DistributionCycle();
		dc.contract = contract;
		dc.cycleType = cycleType;
		dc.startDate = startDate;
		dc.endDate = endDate;
		dc.startHour = startHour;
		dc.endHour = endHour;
		dc.place = db.Place.manager.get(placeId);

		if (contract.type == db.Contract.TYPE_VARORDER) {
			dc.daysBeforeOrderStart = daysBeforeOrderStart;
			dc.daysBeforeOrderEnd = daysBeforeOrderEnd;
			dc.openingHour = openingHour;
			dc.closingHour = closingHour;			
		}
				
		if (dc.endDate.getTime() > contract.endDate.getTime()) {
			throw new Error(t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(contract.endDate)}));
		}
		if (dc.startDate.getTime() < contract.startDate.getTime()) {
			throw new Error(t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(contract.startDate)}));
		}

		if(dispatchEvent){
			App.current.event(NewDistribCycle(dc));
		}
		
		dc.insert();
		createCycleDistribs(dc);

		return dc;

	}
}