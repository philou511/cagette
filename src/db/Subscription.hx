package db;
import service.SubscriptionService;
import db.Operation.OperationType;
import sys.db.Object;
import sys.db.Types;
import Common;
import tink.core.Error;

class Subscription extends Object {

	public var id : SId;
	@formPopulate("populate") @:relation(userId) public var user : db.User;
	@hideInForms @:relation(userId2) public var user2 : SNull<db.User>;
	@:relation(catalogId) public var catalog : db.Catalog;
	public var startDate : SDateTime;
	public var endDate : SDateTime;
	@hideInForms public var isPaid : SBool;
	public var defaultOrders : SNull<SText>;
	public var absentDistribIds : SNull<SText>;

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

	/**
		get total cost of subscription orders
	**/
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

	/**
		get subscription balance
	**/
	public function getBalance() : Float {

		if( this.id == null ) return 0;

		var total = 0.0;
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

	

	public function getAbsencesNb():Int {
		return getAbsentDistribIds().length;
	}
	
	/**
		get chosen absence distribs of this subscription
	**/
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
		get subscription POSSIBLE absence distribs, including closed distributions
	**/
	public function getPossibleAbsentDistribs() : Array<db.Distribution>
	{
		if (this.catalog.absencesStartDate == null) return [];

		//get all subscription distribs
		var subDistributions = db.Distribution.manager.search( $catalog == this.catalog && $date >= this.startDate && $end <= this.endDate, { orderBy:date }, false );
		
		//keep only those who are in the absence period
		var out = [];		
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