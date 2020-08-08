package db;
import sys.db.Object;
import sys.db.Types;
import Common;

class Subscription extends Object {

	public var id : SId;
	@formPopulate("populate") @:relation(userId) public var user : db.User;
	@:relation(catalogId) public var catalog : db.Catalog;
	public var startDate : SDateTime;
	public var endDate : SDateTime;
	@hideInForms public var isValidated : SBool;
	@hideInForms public var isPaid : SBool;
	var defaultOrders : SNull<SText>;
	public var absencesNb : SNull<SInt>;
	var absentDistribIds : SNull<SText>;

	public function populate() {
		
		return App.current.user.getGroup().getMembersFormElementData();
	}

	public function setDefaultOrders( ordersData : Array< { productId : Int, quantity : Float } > ) {

		this.defaultOrders = haxe.Json.stringify( ordersData );
	}	
	
	public function getDefaultOrders( ?productId : Int ) : Array< { productId : Int, quantity : Float } > {

		if ( this.defaultOrders == null ) return null;
		
		var defaultOrders : Array< { productId : Int, quantity : Float } > = haxe.Json.parse( this.defaultOrders );
		if ( productId != null ) {

			return [ defaultOrders.find( function( order ) return order.productId == productId ) ];
		}

		return defaultOrders;
	}

	public function getDefaultOrdersToString() : String {

		if ( this.defaultOrders == null ) return 'Aucune commande par défaut définie';
		
		var label : String = '';
		var defaultOrders : Array< { productId : Int, quantity : Float } > = haxe.Json.parse( this.defaultOrders );
		for ( order in defaultOrders ) {

			label += tools.FloatTool.clean( order.quantity ) + ' x ' + db.Product.manager.get( order.productId ).name + '<br />';
		}

		return label;
	}

	public function setAbsentDistribIds( distribIds : Array<Int> ) {

		distribIds.sort( function(b, a) { return  a < b ? 1 : -1; } );
		this.absentDistribIds = distribIds.join(',');
	}	
	
	public function getAbsentDistribIds() : Array<Int> {

		if ( this.absentDistribIds == null ) return [];
		return this.absentDistribIds.split(',').map( Std.parseInt );
	}

	public function getAbsentDistribs() : Array<db.Distribution> {

		var absentDistribIds : Array<Int> = getAbsentDistribIds();
		return absentDistribIds.map( function( distribId ) { return  db.Distribution.manager.get( distribId ); } );
	}

	override public function toString(){
		return "Souscription #"+id+" de "+user.getName()+" à "+catalog.name;
	}

	public static function getLabels() {

		var t = sugoi.i18n.Locale.texts;
		return [
			"user" 				=> t._("Member"),
			"startDate" 		=> t._("Start date"),
			"endDate" 			=> t._("End date"),
			"absencesNb" 		=> "Nombre d'absences",
			"absencesDates" 	=> "Dates des absences"
		];
	}
	
}