package db;
import sys.db.Object;
import sys.db.Types;
import Common;

class Subscription extends Object {

	public var id : SId;
	@formPopulate("populate") @:relation(userId) public var user : db.User;
	@hideInForms @:relation(userId2) public var user2 : SNull<db.User>;
	@:relation(catalogId) public var catalog : db.Catalog;
	public var startDate : SDateTime;
	public var endDate : SDateTime;
	@hideInForms public var isValidated : SBool;
	@hideInForms public var isPaid : SBool;
	var defaultOrders : SNull<SText>;
	var absentDistribIds : SNull<SText>;

	public function populate() {
		
		return App.current.user.getGroup().getMembersFormElementData();
	}

	public function setDefaultOrders( defaultOrders : Array< { productId : Int, quantity : Float } > ) {

		this.defaultOrders = haxe.Json.stringify( defaultOrders );
	}	
	
	public function getDefaultOrders( ?productId : Int ) : Array< { productId : Int, quantity : Float } > {

		if ( this.defaultOrders == null ) return [];
		
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
		var totalPrice = 0.0;
		for ( order in defaultOrders ) {

			var product = db.Product.manager.get( order.productId );
			if ( product != null && order.quantity != 0 ) {

				label += tools.FloatTool.clean( order.quantity ) + ' x ' + product.name + '<br />';
				totalPrice += Formatting.roundTo( order.quantity * product.price, 2 );
			}
			
		}

		label += 'Total : ' + Formatting.roundTo( totalPrice, 2 ) + ' €';

		return label;
	}

	public function setAbsentDistribIds( distribIds : Array<Int> ) {

		if( distribIds != null ) {

			distribIds.sort( function(b, a) { return  a < b ? 1 : -1; } );
			this.absentDistribIds = distribIds.join(',');
		}
		else {

			this.absentDistribIds = null;
		}
		
	}

	public function getAbsencesNb() : Int {

		if ( this.absentDistribIds == null ) return 0;
		var distribIds = this.absentDistribIds.split(',');
		if ( this.catalog.absentDistribsMaxNb < distribIds.length ) {

			return this.catalog.absentDistribsMaxNb;
		}

		return distribIds.length;
	}
	
	public function getAbsentDistribIds() : Array<Int> {

		if ( this.absentDistribIds == null ) return [];
		var distribIds : Array<Int> = this.absentDistribIds.split(',').map( Std.parseInt );
		if ( this.catalog.absentDistribsMaxNb < distribIds.length ) {

			var shortenedDistribIds = new Array<Int>();
			for ( i in 0...this.catalog.absentDistribsMaxNb ) {

				shortenedDistribIds.push( distribIds[i] );
			}

			return shortenedDistribIds;
		}

		return distribIds;
	}

	public function getAbsentDistribs() : Array<db.Distribution> {

		var absentDistribIds : Array<Int> = getAbsentDistribIds();
		if ( absentDistribIds == null ) return [];

		var absentDistribs : Array<db.Distribution> = new Array<db.Distribution>();
		for ( distribId in absentDistribIds ) {

			var distribution = db.Distribution.manager.get( distribId );
			if ( distribution != null && this.catalog.absencesStartDate.toString() <= distribution.date.toString()
				&& distribution.date.toString() <= this.catalog.absencesEndDate.toString() ) {

				absentDistribs.push( distribution );
			}
			
		}

		return absentDistribs;
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