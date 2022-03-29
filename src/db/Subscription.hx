package db;
import Common;
import db.Operation.OperationType;
import sys.db.Object;
import sys.db.Types;

class Subscription extends Object {

	public var id : SId;
	@formPopulate("populate") @:relation(userId) public var user : db.User;
	@hideInForms @:relation(userId2) public var user2 : SNull<db.User>;
	@:relation(catalogId) public var catalog : db.Catalog;
	public var startDate : SDateTime;
	public var endDate : SDateTime;
	@hideInForms public var isPaid : SBool;
	var defaultOrders : SNull<SText>;
	var absentDistribIds : SNull<SText>;

	public function populate() {		
		return App.current.user.getGroup().getMembersFormElementData();
	}

	public function paid() : Bool {

		if( this.id == null ) return false;

		if ( this.catalog.group.hasPayments() ) {

			var totalPrice = getTotalPrice();
			return 0 < totalPrice && totalPrice <= getPaymentsTotal();
		}
		else {

			return this.isPaid;
		}
	}

	public function getTotalPrice() : Float {

		if( this.id == null ) return 0;

		var totalPrice : Float = 0;
		var orders = db.UserOrder.manager.search( $subscription == this, false );
		for ( order in orders ) {

			totalPrice += Formatting.roundTo( order.quantity * order.productPrice, 2 );
		}

		return Formatting.roundTo( totalPrice, 2 );
	}

	public function getTotalOperation() : db.Operation {

		if( this.id == null ) return null;

		return db.Operation.manager.select( $user == this.user && $subscription == this && $type == SubscriptionTotal, true );
	}

	/**
		get total of payment operations linked to this subscription
	**/
	public function getPaymentsTotal() : Float {
		if( this.id == null ) return 0;
		var paymentsTotal : Float = 0;
		var operations = db.Operation.manager.search( $user == user && $subscription == this && $type == Payment, null, false );
		for ( operation in operations ) {
			paymentsTotal += Formatting.roundTo( operation.amount, 2 );
		}
		return Formatting.roundTo( paymentsTotal, 2 );
	}

	public function getBalance() : Float {

		if( this.id == null ) return 0;

		var total : Float = 0;
		var totalOperation = getTotalOperation();
		if ( totalOperation != null ) total = totalOperation.amount;

		return Formatting.roundTo( getPaymentsTotal() + total, 2 );
	}

	public function setDefaultOrders( defaultOrders : Array<{ productId:Int, quantity:Float }> ) {
		this.defaultOrders = haxe.Json.stringify( defaultOrders );
	}	
	
	public function getDefaultOrders( ?productId : Int ) : Array<{ productId:Int, quantity:Float }> {

		if ( this.defaultOrders == null ) return [];
		
		var defaultOrders : Array<{ productId:Int, quantity:Float }> = haxe.Json.parse( this.defaultOrders );
		if ( productId != null ) {
			return [ defaultOrders.find( order -> return order.productId == productId ) ];
		}

		return defaultOrders;
	}

	public function getDefaultOrdersTotal() : Float {

		if ( this.defaultOrders == null ) return 0;
		
		var defaultOrders : Array< { productId : Int, quantity : Float } > = haxe.Json.parse( this.defaultOrders );
		var totalPrice = 0.0;
		for ( order in defaultOrders ) {

			var product = db.Product.manager.get( order.productId, false );
			if ( product != null && order.quantity != null && order.quantity != 0 ) {

				totalPrice += Formatting.roundTo( order.quantity * product.price, 2 );
			}
			
		}

		return Formatting.roundTo( totalPrice, 2 );
	}


	public function getDefaultOrdersToString() : String {

		if ( this.defaultOrders == null ) return 'Aucune commande par défaut définie';
		
		var label : String = '';
		var defaultOrders : Array<{ productId:Int, quantity:Float }> = haxe.Json.parse( this.defaultOrders );
		var totalPrice = 0.0;
		for ( order in defaultOrders ) {
			if(order.quantity == null || order.quantity == 0) continue;

			var product = db.Product.manager.get( order.productId, false );
			if ( product != null ) {
				label += tools.FloatTool.clean( order.quantity ) + ' x ' + product.name + '<br />';
				totalPrice += Formatting.roundTo( order.quantity * product.price, 2 );
			}			
		}

		label += 'Total : ' + Formatting.roundTo( totalPrice, 2 ) + ' €';
		return label;
	}

	/**
		set subscriptions absence distributions
	**/
	public function setAbsences( distribIds:Array<Int> ) {

		//check there is no duplicates
		if(tools.ArrayTool.deduplicate(distribIds).length != distribIds.length){
			throw new Error(500,"Vous ne pouvez pas choisir deux fois la même distribution");
		}

		var possibleDistribs = this.getPossibleAbsentDistribs().map(d -> d.id);
		for(did in distribIds){
			if(!possibleDistribs.has(did)){
				throw new Error('Distrib #${did} is not in possible absent distribs');
			} 
		}

		if(distribIds.length != this.getAbsencesNb()){
			throw new Error('There should be ${this.getAbsencesNb()} absent distribs');
		}
		

		if( distribIds != null && distribIds.length != 0 ) {
			distribIds.sort( function(b, a) { return  a < b ? 1 : -1; } );
			this.absentDistribIds = distribIds.join(',');
		} else {
			this.absentDistribIds = null;
		}
	}

	public function getAbsencesNb():Int {
		return getAbsentDistribIds().length;
	}
	
	public function getAbsentDistribIds() : Array<Int> {

		if ( this.absentDistribIds == null ) return [];
		var distribIds : Array<Int> = this.absentDistribIds.split(',').map( Std.parseInt );
		if ( distribIds.length > catalog.absentDistribsMaxNb ) {
			//shorten list
			distribIds = distribIds.slice(0,catalog.absentDistribsMaxNb);
		}

		return distribIds;
	}

	/**
		get subscription absence distribs
	**/
	public function getAbsentDistribs() : Array<db.Distribution> {

		var absentDistribIds = getAbsentDistribIds();
		if ( absentDistribIds == null ) return [];
		return db.Distribution.manager.search($id in absentDistribIds,false).array();
	}

	/**
		get subscription POSSIBLE absence distribs
	**/
	public function getPossibleAbsentDistribs() : Array<db.Distribution> {
		if (this.catalog.absencesStartDate == null) return [];
		//get all subscription distribs
		var subDistributions = db.Distribution.manager.search( $catalog == this.catalog && $date >= this.startDate && $end <= this.endDate, { orderBy : date }, false );
		var out = [];
		//keep only those who are in the absence period
		for( d in subDistributions ){
			if(d.date.getTime() >= this.catalog.absencesStartDate.getTime()){
				if(d.date.getTime() <= this.catalog.absencesEndDate.getTime()){
					out.push(d);
				}
			}
		}
		return out;
	}

	override public function toString(){
		return 'Souscription #$id de ${user.getName()} à ${catalog.name}';
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