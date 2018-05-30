package service;
import Common;

/**
 * Distribution Service
 * @author web-wizard
 */
class DistributionService
{
	
	var distribution : db.Distribution;

	public function new(d:db.Distribution) 
	{
		this.distribution = d;
		
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
			throw t._("There is already a distribution at this place overlapping with the time range you've selected.");
		}
 
		if (d.date.getTime() > c.endDate.getTime()) throw t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(c.endDate)});
		if (d.date.getTime() < c.startDate.getTime()) throw t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(c.startDate)});
		
		if (c.type == db.Contract.TYPE_VARORDER ) {
			if (d.date.getTime() < d.orderEndDate.getTime() ) throw t._("The distribution start date must be set after the orders end date.");
			if (d.orderStartDate.getTime() > d.orderEndDate.getTime() ) throw t._("The orders end date must be set after the orders start date !");
		}

	}

	/**
	* Creates a new distribution and prevents distribution overlapping and other checks
	*  @param contract
	*  @param date
	*  @param end
	*  @param placeId
	*  @param distributor1Id
	*  @param distributor2Id
	*  @param distributor3Id
	*  @param distributor4Id
	*  @param orderStartDate
	*  @param orderEndDate
	*/
	 public static function create(contract:db.Contract,date:Date,end:Date,placeId:Int,
	 	?distributor1Id:Int,?distributor2Id:Int,?distributor3Id:Int,?distributor4Id:Int,
		orderStartDate:Date,orderEndDate:Date,?distributionCycle:db.DistributionCycle):db.Distribution {

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
					
		if (end == null) {
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 60);
		}
		else {
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), end.getHours(), end.getMinutes(), 0);
		} 
		
		DistributionService.checkDistrib(d);
		
		if(distributionCycle == null) {
			var e :Event = NewDistrib(d);
			App.current.event(e);
		}
		
		if (d.date == null){
			return null;
		} 
		else {
			d.insert();
			return d;
		}
	}

	/**
	* Modifies an existing distribution and prevents distribution overlapping and other checks
	*  @param d
	*  @param date
	*  @param end
	*  @param placeId
	*  @param distributor1Id
	*  @param distributor2Id
	*  @param distributor3Id
	*  @param distributor4Id
	*  @param orderStartDate
	*  @param orderEndDate
	*/
	 public static function edit(d:db.Distribution,date:Date,end:Date,placeId:Int,
	 	distributor1Id:Int,distributor2Id:Int,distributor3Id:Int,distributor4Id:Int,
		orderStartDate:Date,orderEndDate:Date):db.Distribution {

		//We prevent others from modifying it
		d.lock();

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
		
		DistributionService.checkDistrib(d);

		App.current.event(EditDistrib(d));
		
		if (d.date == null){
			return null;
		} 
		else {
			d.update();
			return d;
		}
	}

	public static function getDates(dc:db.DistributionCycle, datePointer:Date) {
		var startDate = new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.startHour.getHours(),dc.startHour.getMinutes(),0);
		var orderStartDate = null;
		var orderEndDate = null;
		if (dc.contract.type == db.Contract.TYPE_VARORDER){
			
			if (dc.daysBeforeOrderEnd == null || dc.daysBeforeOrderStart == null) throw "daysBeforeOrderEnd or daysBeforeOrderStart is null";
			
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
	 * on créé toutes les distribs en partant du jour de la semaine de la premiere date
	 */
	public static function createCycleDistribs(dc:db.DistributionCycle) {
		//switch end date to 23:59 to avoid the last distribution to be skipped
		dc.endDate = tools.DateTool.setHourMinute(dc.endDate,23,59);
		
		if (dc.id == null) throw "this distributionCycle has not been recorded";
		
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
						App.log("on ajoute "+(oneDay * 7.0)+"millisec pour ajouter 7 jours");
						App.log('pointer : $datePointer');
						
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
			
			service.DistributionService.create(dc.contract,dates.date,
			new Date(datePointer.getFullYear(),datePointer.getMonth(),datePointer.getDate(),dc.endHour.getHours(),dc.endHour.getMinutes(),0),
			dc.place.id,null,null,null,null,dates.orderStartDate,dates.orderEndDate,dc);

		}
	}
	
	/**
	 *  Delete distributions which are part of this cycle
	 */
	public static function deleteCycleDistribs(cycle:db.DistributionCycle){
		
		var children = db.Distribution.manager.search($distributionCycle == cycle, true);
		var messages = [];
		for ( d in children ){
			
			if (d.contract.type == db.Contract.TYPE_VARORDER && !d.canDelete() ){
				var t = sugoi.i18n.Locale.texts;
				messages.push(t._("The delivery of the ::delivDate:: could not be deleted because it has orders.", {delivDate:App.current.view.hDate(d.date)}));
			}else{
				d.lock();
				d.delete();
			}
		}
		
		return messages;
		
	}

	/**
	* Creates a new distribution cycle and prevents distribution overlapping and other checks
	*  @param contract
	*  @param date
	*  @param end
	*  @param placeId
	*  @param distributor1Id
	*  @param distributor2Id
	*  @param distributor3Id
	*  @param distributor4Id
	*  @param orderStartDate
	*  @param orderEndDate
	*/
	 public static function createCycle(contract:db.Contract,cycleType:db.DistributionCycle.CycleType,startDate:Date,endDate:Date,
	 startHour:Date,endHour:Date,daysBeforeOrderStart:Null<Int>,daysBeforeOrderEnd:Null<Int>,openingHour:Null<Date>,closingHour:Null<Date>,
	 placeId:Int):db.DistributionCycle {	

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
			throw t._("The date of the delivery must be prior to the end of the contract (::contractEndDate::)", {contractEndDate:view.hDate(contract.endDate)});
		}
		if (dc.startDate.getTime() < contract.startDate.getTime()) {
			throw t._("The date of the delivery must be after the begining of the contract (::contractBeginDate::)", {contractBeginDate:view.hDate(contract.startDate)});
		}

		App.current.event(NewDistribCycle(dc));

		dc.insert();
		createCycleDistribs(dc);

		return dc;

	}
}