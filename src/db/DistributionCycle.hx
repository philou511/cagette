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
		var t = sugoi.i18n.Locale.texts;
		return [
			"cycleType"		=> t._("Fréquence"),
			"startDate" 	=> t._("Date de début"),
			"endDate"		=> t._("Date de fin"),
			"daysBeforeOrderStart" 		=> t._("Ouverture de commande (nbre de jours avant distribution)"),			
			"daysBeforeOrderEnd"		=> t._("Fermeture de commande (nbre de jours avant distribution)"),
			"place" 		=> t._("Place"),		
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