package db;
import sys.db.Object;
import sys.db.Types;
import datetime.DateTime;
using tools.DateTool;

enum CycleType {
	Weekly;	
	Monthly;
	BiWeekly;
	TriWeekly;
}

/**
 * Distribution cycle
 */
class DistributionCycle extends Object
{
	public var id : SId;	
	@:relation(contractId) public var contract : Contract;
	public var cycleType:SEnum<CycleType>;
	public var startDate : SDate; //debut
	public var endDate : SDate;	//fin de la recurrence
	public var startHour : SDateTime; 
	public var endHour : SDateTime;	
	public var daysBeforeOrderStart:SNull<STinyInt>;
	public var daysBeforeOrderEnd:SNull<STinyInt>;
	public var openingHour:SNull<SDate>;
	public var closingHour:SNull<SDate>;
	@formPopulate("placePopulate") @:relation(placeId) public var place : Place;
	
	public function new() {
		super();
	}
	
	public static function getLabels(){
		return [
			"cycleType"		=> "Fréquence",
			"startDate" 	=> "Date de début",
			"endDate"		=> "Date de fin",
			"daysBeforeOrderStart" 		=> "Ouverture de commande (nbre de jours avant distribution)" ,			
			"daysBeforeOrderEnd"		=> "Fermeture de commande (nbre de jours avant distribution)",			
		];
	}
	
	/**
	 * on créé toutes les distribs en partant du jour de la semaine de la premiere date
	 * 
	 * @TODO refactor this with http://thx-lib.org/api/thx/Dates.html#jump
	 */
	public static function updateAllDistribs(dc:DistributionCycle) {
		//switch end date to 23:59 to avoid the last distribution to be skipped
		dc.endDate = tools.DateTool.setHourMinute(dc.endDate,23,59);

		var datePointer = new Date(dc.startDate.getFullYear(), dc.startDate.getMonth(), dc.startDate.getDate(), 12, 0, 0);
		//why hour=12 ? because if we set hour to 0, it switch to 23 (-1) or 1 (+1) on daylight saving time switch dates, thus changing the day!!
		
		if (dc.id == null) throw "this distributionCycle has not been recorded";
		
		//first distrib
		var d = new Distribution();
		d.contract = dc.contract;
		d.distributionCycle = dc;
		d.place = dc.place;
		d.date = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.startHour.getHours(), dc.startHour.getMinutes(), 0);
		d.end  = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.endHour.getHours()  , dc.endHour.getMinutes()  , 0);
		if (dc.contract.type == Contract.TYPE_VARORDER){
			
			if (dc.daysBeforeOrderEnd == null || dc.daysBeforeOrderStart == null) throw "daysBeforeOrderEnd or daysBeforeOrderStart is null";
			
			var a = DateTools.delta(d.date, -1.0 * dc.daysBeforeOrderStart * 1000 * 60 * 60 * 24);
			var h : Date = dc.openingHour;
			d.orderStartDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);
			
			var a = DateTools.delta(d.date, -1.0 * dc.daysBeforeOrderEnd * 1000 * 60 * 60 * 24);
			var h : Date = dc.closingHour;
			d.orderEndDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);			
		}
		
		d.insert();

		var firstDistribDate = d.date;
		
		//iterations
		for(i in 0...100) {
			
			var d = new Distribution();
			d.contract = dc.contract;
			d.distributionCycle = dc;
			d.place = dc.place;
			
			//date de la distrib
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
			
			//stop if cycle end is reached
			if (datePointer.getTime() > dc.endDate.getTime()) {				
				break;
			}
			
			//set distribution date + end
			d.date = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.startHour.getHours(), dc.startHour.getMinutes(), 0);
			d.end  = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.endHour.getHours(),   dc.endHour.getMinutes(),   0);
			
			//set order opening and closing hours
			if (dc.contract.type == Contract.TYPE_VARORDER){
				
				var a = DateTools.delta(d.date, -1.0 * dc.daysBeforeOrderStart * 1000 * 60 * 60 * 24);
				var h : Date = dc.openingHour;
				d.orderStartDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);
				
				var a = DateTools.delta(d.date, -1.0 * dc.daysBeforeOrderEnd * 1000 * 60 * 60 * 24);
				var h : Date = dc.closingHour;
				d.orderEndDate = new Date(a.getFullYear(), a.getMonth(), a.getDate(), h.getHours(), h.getMinutes(), 0);
			}
			
			d.insert();
		}
	}
	
	/**
	 *  Delete distributions which are part of this cycle
	 */
	public function deleteChilds(){
		
		var childs = db.Distribution.manager.search($distributionCycle == this, true);
		var messages = [];
		for ( d in childs ){
			
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
	
	public function placePopulate():Array<{label:String,value:Int}> {
		var out = [];
		if ( App.current.user == null || App.current.user.amap == null ) return out;
		var places = db.Place.manager.search($amapId == App.current.user.amap.id, false);
		for (p in places) out.push( { label:p.name,value :p.id } );
		return out;
	}
}