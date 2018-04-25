package service;

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

		//We are checking that there is no existing distribution with an overlapping time frame for the same place and contract
		//Looking for existing distributions with a time range overlapping the start of the about to be created distribution
		var distribs1 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.date && $end >= d.date, false);
		//Looking for existing distributions with a time range overlapping the end of the about to be created distribution
		var distribs2 = db.Distribution.manager.search($contract == c && $place == d.place && $date <= d.end && $end >= d.end, false);	
		//Looking for existing distributions with a time range included in the time range of the about to be created distribution		
		var distribs3 = db.Distribution.manager.search($contract == c && $place == d.place && $date >= d.date && $end <= d.end, false);	
			
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
}