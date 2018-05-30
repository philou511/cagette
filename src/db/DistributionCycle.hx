package db;
import sys.db.Object;
import sys.db.Types;
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
	
	public function placePopulate():Array<{label:String,value:Int}> {
		var out = [];
		if ( App.current.user == null || App.current.user.amap == null ) return out;
		var places = db.Place.manager.search($amapId == App.current.user.amap.id, false);
		for (p in places) out.push( { label:p.name,value :p.id } );
		return out;
	}
}