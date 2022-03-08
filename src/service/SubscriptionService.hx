package service;
import controller.Distribution;
import db.Group.RegOption;
import db.Operation.OperationType;
import db.Subscription;
import db.Catalog;
import Common;
import tink.core.Error;
using tools.DateTool;
using Lambda;

enum SubscriptionServiceError {
	NoSubscription;
	PastDistributionsWithoutOrders;
	PastOrders;
	OverlappingSubscription;
	InvalidParameters;
	CatalogRequirementsNotMet;
}

typedef CSAOrder = { productId:Int, quantity:Float, ?userId2:Int, ?invertSharedOrder:Bool };

/**
 * Subscription service
 * @author web-wizard
 */
class SubscriptionService
{

	public var adminMode:Bool;

	public function new(){}

	/**
		get subscriptions of a catalog
	**/
	public static function getCatalogSubscriptions( catalog : db.Catalog ) {
		return db.Subscription.manager.search( $catalogId == catalog.id, {orderBy:id},false ).array();
	}

	/**
		Get user subscriptions in active catalogs
	**/
	public static function getActiveSubscriptions( user:db.User, group:db.Group ) : Array<db.Subscription> {

		var catalogIds = group.getActiveContracts( true ).map( c -> return c.id );
		return db.Subscription.manager.search( ( $user == user || $user2 == user ) && ( $catalogId in catalogIds ), false ).array();
	}

	/**
		Get user not closed subscriptions for a given vendor
	**/
	public static function getUserVendorNotClosedSubscriptions( subscription : db.Subscription ) : Array<db.Subscription> {

		var notClosedSubscriptions = db.Subscription.manager.search( $user == subscription.user && $endDate >= Date.now(), false ).array();
		var vendorNotClosedSubscriptions = new Array<db.Subscription>();
		for ( sub in notClosedSubscriptions ) {
			if( sub.id != subscription.id && sub.catalog.vendor.id == subscription.catalog.vendor.id ) {
				vendorNotClosedSubscriptions.push( sub );
			}
		}
		return vendorNotClosedSubscriptions;
	}

	/**
		Get user active subscriptions, ordered by catalogs.
		This includes the subscriptions as a secondary user.
	**/
	public static function getActiveSubscriptionsByCatalog( user:db.User, group:db.Group ) : Map< db.Catalog, Array< db.Subscription > > {

		if( user == null || user.id == null ) throw new Error( 'Le membre que vous cherchez n\'existe pas');

		var memberSubscriptions = getActiveSubscriptions( user, group );
		var subscriptionsByCatalog = new Map<Catalog,Array<Subscription>>();
		for ( subscription in memberSubscriptions ) {

			if ( subscriptionsByCatalog[subscription.catalog] == null ) {
				subscriptionsByCatalog[subscription.catalog] = [];
			}
			subscriptionsByCatalog[subscription.catalog].push( subscription );
		}

		return subscriptionsByCatalog;
	}

	/**
		get next open ditrib
	**/
	public static function getComingOpenDistrib( catalog : db.Catalog ) : db.Distribution {

		var now = Date.now();		
		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
			return db.Distribution.manager.select( $catalog == catalog && $date > now && $orderStartDate <= now && $orderEndDate > now, { orderBy : date }, false );
		} else {
			return db.Distribution.manager.select( $catalog == catalog && $date > now && $orderEndDate > now, { orderBy : date }, false );
		}
	}

	public static function getComingUnclosedDistrib(catalog:db.Catalog) {
		
		var now = Date.now();
		return db.Distribution.manager.select( $catalog == catalog && $date > now && $orderEndDate > now, { orderBy : date }, false );
	}

	public static function getOpenDistribsForSubscription( user:db.User, catalog:db.Catalog, currentOrComingSubscription:db.Subscription ) : Array<db.Distribution> {

		var openDistribs = new Array< db.Distribution >();

		if ( currentOrComingSubscription != null ) {
			openDistribs = getSubscriptionDistributions( currentOrComingSubscription, "open" );
		} else {
			var now = Date.now();
			openDistribs = db.Distribution.manager.search( $catalog == catalog && $orderStartDate <= now && $orderEndDate > now, { orderBy : date }, false ).array();
		}

		return openDistribs;
    }

	public static function getCurrentOrComingSubscription( user:db.User, catalog:db.Catalog ):db.Subscription
	{
		var comingOpenDistrib = getComingOpenDistrib( catalog );
		var fromDate = comingOpenDistrib != null ? comingOpenDistrib.date : Date.now();
		return db.Subscription.manager.select( $user == user && $catalog == catalog && $endDate >= fromDate, false );
	}

	public static function getUserCatalogSubscriptions( user : db.User, catalog : db.Catalog ) : Array<db.Subscription>
	{		
		if( user == null || user.id == null ) throw new Error( 'Le membre que vous cherchez n\'existe pas');
		return db.Subscription.manager.search( $user == user && $catalog == catalog , false ).array();
	}

	/**
		Get subscription distributions
	**/
	public static function getSubscriptionDistributions( subscription:db.Subscription, ?type='all' ) : Array<db.Distribution> {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );

		var subscriptionDistribs = new List();
		if ( type == "all" || type=="allIncludingAbsences") {
			subscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate, { orderBy : date }, false );
		} else if ( type == "open" ) {
			var now = Date.now();
			subscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog  && $orderStartDate <= now && $orderEndDate > now && $date >= subscription.startDate && $end <= subscription.endDate, { orderBy : date }, false );
		} else if ( type == "past" ) {
			var now = Date.now();
			var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );			
			subscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog  && $end <= endOfToday && $date >= subscription.startDate && $end <= subscription.endDate, false );
		}
		
		if ( type != "allIncludingAbsences" && subscriptionDistribs.length>0 && subscription.catalog.hasAbsencesManagement() ) {
			//remove absence distribs
			var absentDistribs = subscription.getAbsentDistribs();
			for ( absentDistrib in absentDistribs ) {
				subscriptionDistribs = subscriptionDistribs.filter( distrib -> distrib.id != absentDistrib.id );
			}
		}
		
		return subscriptionDistribs.array();
	}

	public static function getSubscriptionRemainingDistribsNb( subscription : db.Subscription ) : Int {

		if( subscription == null ) return 0;

		var remainingSubscriptionDistribs = null;
		remainingSubscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog  && $date >= Date.now() && $end <= subscription.endDate, false );
			
		if ( remainingSubscriptionDistribs.length != 0 && subscription.catalog.hasAbsencesManagement() ) {

			var absentDistribs = subscription.getAbsentDistribs();
			for ( absentDistrib in absentDistribs ) {

				remainingSubscriptionDistribs = remainingSubscriptionDistribs.filter( distrib -> return distrib.id != absentDistrib.id );
			}
		}
		
		return remainingSubscriptionDistribs.length;
	}

	/**
		get possible absence distribs of this catalog
	**/
	public static function getContractAbsencesDistribs( catalog:db.Catalog ) : Array<db.Distribution> {
		if ( !catalog.hasAbsencesManagement() ) return [];
		return db.Distribution.manager.search( $catalog == catalog && $date >= catalog.absencesStartDate && $end <= catalog.absencesEndDate, { orderBy : date }, false ).array();
	}

	public static function getSubscriptionDistribsNb( subscription:db.Subscription, ?type:String, ?excludeAbsences=true ):Int {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );

		var subscriptionDistribsNb = 0;
		if ( type == null ) {
			subscriptionDistribsNb = db.Distribution.manager.count( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate );
		} else if ( type == "past" ) {
			var now = Date.now();
			var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );			
			subscriptionDistribsNb = db.Distribution.manager.count( $catalog == subscription.catalog  && $date <= endOfToday && $date >= subscription.startDate && $end <= subscription.endDate );
		}

		if ( excludeAbsences ) {
			subscriptionDistribsNb = subscriptionDistribsNb - subscription.getAbsencesNb();
		}
		
		return subscriptionDistribsNb;
	}

	public static function getSubscriptionAllOrders( subscription : db.Subscription ) : Array<db.UserOrder> {
		if( subscription == null || subscription.id == null ) return [];
		return db.UserOrder.manager.search( $subscription == subscription, false ).array();
	}

	public static function getCSARecurrentOrders( subscription:db.Subscription, oldAbsentDistribIds:Array<Int> ) : Array<db.UserOrder> {
		
		if( subscription == null || subscription.id == null ) return [];

		var oneDistrib = db.Distribution.manager.select( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate, false );
		if( oneDistrib == null ) return [];

		var oneDistriborders = db.UserOrder.manager.search( $subscription == subscription && $distribution == oneDistrib, false ).array();
		if ( oneDistriborders.length == 0 && subscription.getAbsencesNb() != 0 ) {

			var absentDistribIds = oldAbsentDistribIds;
			if ( absentDistribIds == null ) {

				absentDistribIds = subscription.getAbsentDistribIds();
			}
			var isAbsentDistrib = false;
			var presentDistribFound = false;
			while ( !presentDistribFound ) {

				isAbsentDistrib = false;
				for ( distribId in absentDistribIds ) {

					if ( oneDistrib != null && oneDistrib.id == distribId ) {

						isAbsentDistrib = true;
						oneDistrib = db.Distribution.manager.select( $catalog == subscription.catalog && $date > oneDistrib.date && $end <= subscription.endDate, false );
						break;
					}
				}

				presentDistribFound = !isAbsentDistrib;
			}

			oneDistriborders = db.UserOrder.manager.search( $subscription == subscription && $distribution == oneDistrib, false ).array();
		}
	
		return oneDistriborders;
	}

	/**
		Get contract constraints (no subscription for the current user)
	**/
	public static function getContractConstraints( catalog:db.Catalog ):String{
		var label = '';
		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

			if ( catalog.requiresOrdering ) {				
				label += 'Commande obligatoire à chaque distribution';
				if ( catalog.distribMinOrdersTotal != null && catalog.distribMinOrdersTotal != 0 ) {				
					label += ' d\'au moins ${catalog.distribMinOrdersTotal} €';
				}
			}

			if(catalog.catalogMinOrdersTotal != null){
				var catalogMinOrdersTotal = getCatalogMinOrdersTotal(catalog);
				label += '<br />Minimum de commandes sur la durée du contrat : ${catalogMinOrdersTotal} €';
				if(catalogMinOrdersTotal != catalog.catalogMinOrdersTotal){
					label += '<br /><span class="disabled">A l\'origine ce minimum était de ${catalog.catalogMinOrdersTotal} € mais un prorata a été appliqué<br/>car des distributions ont déjà eu lieu.</span>';
				}

				/*if( catalog.allowedOverspend != null ){
					if(catalog.hasPayments){
						label += '<br />Dépassement autorisé au delà du solde : ${catalog.allowedOverspend} €';
					}else{
						label += '<br />Maximum de commandes sur la durée du contrat : ${catalogMinOrdersTotal + catalog.allowedOverspend} €';
					}				
				}*/			
			}

		} else {
			label += "Contrat AMAP classique : votre commande est identique à chaque distribution.";
		}

		if( label == '' ) return null;
		return label;
	}

	/**
		Get constraints of a subscription
	**/
	public static function getSubscriptionConstraints( subscription:db.Subscription ) {

		var label = '';
		var catalog = subscription.catalog;
		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
			//requires ordering + distribMinOrdersTotal
			if ( catalog.requiresOrdering ) {				
				label += 'Commande obligatoire à chaque distribution';
				if ( catalog.distribMinOrdersTotal != null && catalog.distribMinOrdersTotal != 0 ) {				
					label += ' d\'au moins ${catalog.distribMinOrdersTotal} €';
				}
			}

			// catalogMinOrdersTotal + allowedOverspend
			if(catalog.catalogMinOrdersTotal != null){
				var subscriptionDistribsNb = getSubscriptionDistribsNb( subscription, null, true );
				var catalogAllDistribsNb = db.Distribution.manager.count( $catalog == catalog );
				var ratio = subscriptionDistribsNb / catalogAllDistribsNb;
				// safer to do a "floor" than a "round"
				var catalogMinOrdersTotal = Math.floor(ratio * catalog.catalogMinOrdersTotal);
				label += '<br />Minimum de commandes sur la durée du contrat : $catalogMinOrdersTotal€';
				if(subscriptionDistribsNb < catalogAllDistribsNb){
					label += '<br /><span class="disabled">Calculé au prorata de vos distributions : ${catalog.catalogMinOrdersTotal}€ x ($subscriptionDistribsNb/$catalogAllDistribsNb) = $catalogMinOrdersTotal€</span>';
				}

				/*if( catalog.allowedOverspend != null ){
					if(catalog.hasPayments){
						label += '<br />Dépassement autorisé au delà du solde : ${catalog.allowedOverspend}€';
					}else{
						label += '<br />Maximum de commandes sur la durée du contrat : ${catalogMinOrdersTotal + catalog.allowedOverspend}€';
					}				
				}*/
			}

		} else {

			var subscriptionOrders = getCSARecurrentOrders( subscription, null );
			if( subscriptionOrders.length == 0 ) return null;
			for ( order in subscriptionOrders ) {
				label += tools.FloatTool.clean( order.quantity ) + ' x ' + order.product.name + '<br />';
			}
			label += "à chaque distribution.";

		}

		if( label == '' ) return null;
		return label;
	}

	public static function getAbsencesDescription( catalog : db.Catalog ) {
		if ( catalog.absentDistribsMaxNb==0 || catalog.absentDistribsMaxNb==null ) return "Pas d'absences autorisées";
		if(catalog.absentDistribsMaxNb>0 && catalog.absencesStartDate==null ) throw "Une période d'absence doit être définie pour ce contrat";
		return '${catalog.absentDistribsMaxNb} absences maximum autorisées  du ${DateTools.format( catalog.absencesStartDate, "%d/%m/%Y" )} au ${DateTools.format( catalog.absencesEndDate, "%d/%m/%Y")} ';
	}

	/**
	 * Checks subscription validity
	 */
	public function check( subscription:db.Subscription, ?previousStartDate:Date ) {

		//catalog should have distribs
		if(subscription.catalog.getDistribs().length==0){
			throw new Error("Ce catalogue n'a pas de distributions planifiées");
		}

		//startDate should be later than endDate
		if(subscription.startDate.getTime() >= subscription.endDate.getTime()){
			throw TypedError.typed( 'La date de début de la souscription doit être antérieure à la date de fin.', InvalidParameters );
		}

		//If not admin : start date should be next unclosed distrib, or later, but not before.
		if(!adminMode){
			var newSubscriptionStartDate = getNewSubscriptionStartDate( subscription.catalog );
			if ( newSubscriptionStartDate == null ) {
				throw TypedError.typed( "Toutes les distributions futures sont déjà fermées, ou il n'existe aucune distribution dans le futur.", InvalidParameters );
			}
			if( subscription.id == null ) {
				//new sub
				if ( subscription.startDate.getTime() < newSubscriptionStartDate.getTime() ) {
					throw TypedError.typed( 'La date de début de la souscription ne doit pas être avant la date de la prochaine distribution : ' + Formatting.dDate( newSubscriptionStartDate ), InvalidParameters );
				}
			} else {	
				//existing sub		
				if ( previousStartDate.toString() != subscription.startDate.toString() ) {
					if ( Date.now().getTime() <= subscription.startDate.getTime() && subscription.startDate.getTime() < newSubscriptionStartDate.getTime() ) {
						throw TypedError.typed( 'La date de début de la souscription ne doit pas être avant la date de la prochaine distribution : '
											+ Formatting.dDate( newSubscriptionStartDate ), InvalidParameters );
					}
				}
			}
		}
		
		var subName = ' (souscription de ${subscription.user.getName()})';

		//dates should be inside catalog dates
		var catalogStartDate = new Date( subscription.catalog.startDate.getFullYear(), subscription.catalog.startDate.getMonth(), subscription.catalog.startDate.getDate(), 0, 0, 0 );
		var catalogEndDate = new Date( subscription.catalog.endDate.getFullYear(), subscription.catalog.endDate.getMonth(), subscription.catalog.endDate.getDate(), 23, 59, 59 );
		if ( subscription.startDate.getTime() < catalogStartDate.getTime() || subscription.startDate.getTime() >= catalogEndDate.getTime() ) {
			throw new Error( 'La date de début de la souscription doit être comprise entre les dates de début et de fin du catalogue.'+subName );
		}
		if ( subscription.endDate.getTime() <= catalogStartDate.getTime() || subscription.endDate.getTime() > catalogEndDate.getTime() ) {
			throw new Error( 'La date de fin de la souscription doit être comprise entre les dates de début et de fin du catalogue.'+subName );
		}

		//dates overlap check
		var subscriptions1;
		var subscriptions2;	
		var subscriptions3;	
		//We are checking that there is no existing subscription with an overlapping time frame for the same user and catalog
		if ( subscription.id == null ) { //We need to check there the id as $id != null doesn't work in the manager.search

			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog 
															&& $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog 
															&& $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog 
															&& $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		} else {
			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id 
															&& $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id 
															&& $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id 
															&& $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		}
			
		if ( subscriptions1.length != 0 || subscriptions2.length != 0 || subscriptions3.length != 0 ) {
			var subs = subscriptions1.concat(subscriptions2).concat(subscriptions3).array();
			subs = tools.ObjectListTool.deduplicate(subs);
			throw TypedError.typed( 'Il y a déjà une souscription pour ce membre pendant la période choisie.'+"("+subs.join(',')+")", OverlappingSubscription );
		}
	
		if ( subscription.id != null && hasPastDistribOrdersOutsideSubscription(subscription) && !subscription.catalog.isConstantOrders() ) {
			throw TypedError.typed( 
				'La nouvelle période sélectionnée exclue des commandes déjà passées, Il faut élargir la période sélectionnée $subName.',
				PastOrders
			);
		}
		
		if ( !adminMode && hasPastDistribsWithoutOrders( subscription ) ) {
			throw TypedError.typed(
				'La nouvelle période sélectionnée inclue des distributions déjà passées auxquelles le membre n\'a pas participé, Il faut choisir une date ultérieure $subName.',
				PastDistributionsWithoutOrders
			);
		}

	}

	/**
		Minimum de commande sur la durée du contrat.
		Si souscription != null, calcul le pro-rata 
	**/
	public static function getCatalogMinOrdersTotal( catalog:db.Catalog, ?subscription:db.Subscription ) : Float {

		if ( catalog.catalogMinOrdersTotal == null || catalog.catalogMinOrdersTotal == 0 /*|| catalog.allowedOverspend == null*/ ) {
			return null;
		}

		//si paiements, le minimum à commander correspond à la provision déja payée
		if ( catalog.hasPayments && subscription != null ) {
			var subscriptionPayments = subscription.getPaymentsTotal();
			if ( subscriptionPayments != 0 ) {
				return subscriptionPayments;
			}
		}

		var subscriptionDistribsNb = 0;
		if ( subscription != null ) {
			subscriptionDistribsNb = getSubscriptionDistribsNb( subscription, null, true );
		} else {
			subscriptionDistribsNb = db.Distribution.manager.count( $catalog == catalog && $date >= SubscriptionService.getNewSubscriptionStartDate( catalog ) );
		}
		
		var catalogAllDistribsNb = db.Distribution.manager.count( $catalog == catalog );
		if ( catalogAllDistribsNb == 0 ) return null;
		var ratio = subscriptionDistribsNb / catalogAllDistribsNb;

		// safer to do a "floor" than a "round"
		return Math.floor(ratio * catalog.catalogMinOrdersTotal);
	}

	 /*
	  *	Checks if automated orders are valid.
	  */
	  /*public static function areAutomatedOrdersValid( subscription:db.Subscription, distribution:db.Distribution ):Bool {

		var catalog = subscription.catalog;
		
		var catalogMinOrdersTotal = getCatalogMinOrdersTotal( catalog, subscription );
		if ( catalogMinOrdersTotal == null || catalogMinOrdersTotal == 0 || catalog.allowedOverspend == null || catalog.allowedOverspend == 0 ) {
			return true;
		}

		if ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 && catalog.allowedOverspend != null && catalog.allowedOverspend != 0 ) {

			//Computes the new orders total
			var subscriptionNewTotal = subscription.getTotalPrice() + subscription.getDefaultOrdersTotal();

			//Checks that the orders total is lower than the allowed overspend
			var maxAllowedTotal = catalogMinOrdersTotal + catalog.allowedOverspend;
			if ( maxAllowedTotal < subscriptionNewTotal ) {
				return false;
			}

		}

		return true;
	}*/


	 /*
	  *	Checks if variable orders for one or several distributions meet all the catalog requirements 
	  */
	 public static function areVarOrdersValid( subscription:db.Subscription, pricesQuantitiesByDistrib:Map<db.Distribution,Array<{productQuantity:Float, productPrice:Float}>> ) : Bool {

		var catalog : db.Catalog = null;
		if ( subscription != null ) {
			catalog = subscription.catalog;
		} else {
			catalog = pricesQuantitiesByDistrib.keys().next().catalog;
		}

		var catalogMinOrdersTotal = getCatalogMinOrdersTotal( catalog, subscription );
		if ( ( catalog.distribMinOrdersTotal == null || catalog.distribMinOrdersTotal == 0 ) && ( catalogMinOrdersTotal == null || catalogMinOrdersTotal == 0 /*|| catalog.allowedOverspend == null*/ ) ) {
			return true;
		}

		//Distribution minimum orders total
		if ( catalog.distribMinOrdersTotal != null && catalog.distribMinOrdersTotal != 0 ) {

			var distribTotal : Float = 0;
			for ( distrib in pricesQuantitiesByDistrib.keys() ) {

				distribTotal = 0;
				for ( quantityPrice in pricesQuantitiesByDistrib[distrib] ) {
					distribTotal += Formatting.roundTo( quantityPrice.productQuantity * quantityPrice.productPrice, 2 );
				}

				distribTotal = Formatting.roundTo( distribTotal, 2 );

				if ( distribTotal < catalog.distribMinOrdersTotal ) {
					var message = '<strong>Distribution du ' + Formatting.hDate( distrib.date ) + ' :</strong><br/>';
					message += 'Le montant votre commande doit être d\'au moins ' + catalog.distribMinOrdersTotal + ' € par distribution.';
					throw TypedError.typed( message, CatalogRequirementsNotMet );
				}
			}
		}

		//Catalog minimum orders total
		if ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 ) {

			//Computes orders total
			var ordersTotal : Float = 0;
			var ordersDistribIds = new Array<Int>();
			for ( distrib in pricesQuantitiesByDistrib.keys() ) {
				ordersDistribIds.push( distrib.id );
				for ( quantityPrice in pricesQuantitiesByDistrib[distrib] ) {
					ordersTotal += Formatting.roundTo( quantityPrice.productQuantity * quantityPrice.productPrice, 2 );
				}
			}
			ordersTotal = Formatting.roundTo( ordersTotal, 2 );

			var otherDistribsTotal : Float = 0;
			if( subscription != null && subscription.id != null ) {
				var orders = db.UserOrder.manager.search( $subscription == subscription, false );
				for ( order in orders ) {
					//We are are adding up all the orders prices for the distribs that are not among the new submitted orders
					if ( ordersDistribIds.find( id -> id == order.distribution.id ) == null ) {
						otherDistribsTotal += Formatting.roundTo( order.quantity * order.productPrice, 2 );
					}
				}
				otherDistribsTotal = Formatting.roundTo( otherDistribsTotal, 2 );
			}

			var subscriptionNewTotal = otherDistribsTotal + ordersTotal;

			//Checks that the orders total is higher than the required minimum
			var lastDistrib : db.Distribution = null;
			if( subscription != null ) {
				var allSubsriptionDistribs = getSubscriptionDistributions( subscription, 'all' );
				lastDistrib = allSubsriptionDistribs[ allSubsriptionDistribs.length - 1 ];
			} else {
				lastDistrib = catalog.getDistribs().last();
			}

			if( lastDistrib != null ) {

				var now = Date.now();
				var doCheckMin = false;
				if ( catalog.requiresOrdering ) {
					if ( ordersDistribIds.find( id -> id == lastDistrib.id ) != null ) {	
						doCheckMin = true;
					}
				} else if ( lastDistrib.orderStartDate.getTime() <= now.getTime() &&  now.getTime() < lastDistrib.orderEndDate.getTime() ) {
					doCheckMin = true;
				}

				if ( doCheckMin ) {
					if ( subscriptionNewTotal < catalogMinOrdersTotal ) {
						var message = 'Le nouveau total de toutes vos commandes sur la durée du contrat serait de $subscriptionNewTotal€ 
						alors qu\'il doit être supérieur à $catalogMinOrdersTotal€. Veuillez rajouter des produits.';
						throw TypedError.typed( message, CatalogRequirementsNotMet );
					}
				}
			}

			//Checks that the orders total is lower than the allowed overspend
			/*if(catalog.allowedOverspend!=null){
				if(catalog.hasPayments && subscription!=null){

					var paid = subscription.getPaymentsTotal();
					if( subscriptionNewTotal > paid+catalog.allowedOverspend){
						var msg = "";
						if(catalog.allowedOverspend==0){
							msg = 'Sachant que ce contrat n\'autorise pas de dépassement de votre solde (vous ne pouvez pas commander pour plus que votre solde), vous ne pouvez pas enregistrer cette commande. Vous devez faire un paiement complémentaire au producteur.';
						}else{
							msg = 'Sachant que ce contrat autorise des dépassements de ${catalog.allowedOverspend}€ au maximum, vous ne pouvez pas enregistrer cette commande. Vous devez faire un paiement complémentaire au producteur.';
						}
						throw TypedError.typed( msg, CatalogRequirementsNotMet );
					}
	
				}
				if(!catalog.hasPayments){
	
					var maxAllowedTotal = catalogMinOrdersTotal + catalog.allowedOverspend;
					if ( maxAllowedTotal < subscriptionNewTotal ) {
						var message = 'Le nouveau total de toutes vos commandes serait de $subscriptionNewTotal€ 
						alors qu\'il doit être inférieur à $maxAllowedTotal€. Veuillez enlever des produits.';
						throw TypedError.typed( message, CatalogRequirementsNotMet );
					}
				}
			}*/
		}

		return true;
	}

	/**
		Find date of next unclosed distribution
	**/
	public static function getNewSubscriptionStartDate( catalog : db.Catalog ) : Date {

		var notClosedComingDistrib = getComingUnclosedDistrib(catalog);
		
		if ( notClosedComingDistrib != null ) {
			return new Date( notClosedComingDistrib.date.getFullYear(), notClosedComingDistrib.date.getMonth(), notClosedComingDistrib.date.getDate(), 0, 0, 0 );
		} else {
			return null;
		}
	}

	 /**
		Creates a new subscription
		* ordersData is defaultOrder or recurrent order
		* set absences number
	  */
	 public function createSubscription( user:db.User, catalog:db.Catalog, ?ordersData:Array<CSAOrder>, ?absenceDistribIds:Array<Int>,?absenceNb:Int,?startDate:Date, ?endDate:Date ):db.Subscription {

		if ( startDate == null ) startDate = getNewSubscriptionStartDate( catalog );
		if ( endDate == null ) 	endDate = catalog.endDate;
		
		//if the user is not a member of the group
		if(!user.isMemberOf(catalog.group)){
			if(catalog.group.regOption==RegOption.Open){
				user.makeMemberOf(catalog.group);
			}else{
				throw new Error(user.getName()+" n'est pas membre de "+catalog.group.name);
			}
		}

		var subscription = new db.Subscription();
		subscription.user = user;
		subscription.catalog = catalog;
		subscription.startDate 	= new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate(), 0, 0, 0 );
		subscription.endDate 	= new Date( endDate.getFullYear()  , endDate.getMonth()  , endDate.getDate()  , 23, 59, 59 );
		subscription.isPaid = false;

		//is there a secondary user in this subscription
		if( catalog.type == db.Catalog.TYPE_CONSTORDERS ) {
			var user2 = checkUser2( ordersData );
			subscription.user2 = db.User.manager.get( user2, false );
		}
		
		if(absenceDistribIds!=null){
			//absences are define
			setAbsences(subscription,absenceDistribIds);
		}else{
			//only absence number is defined, thus we get absence dates automatically
			setAbsences(subscription,getAutomaticAbsentDistribs(catalog, catalog.absentDistribsMaxNb).map(d->d.id));
		}
		
		check(subscription);
		subscription.insert();

		this.createCSARecurrentOrders( subscription, ordersData );
		this.updateDefaultOrders( subscription, ordersData );
		

		return subscription;
	}

	/**
		set subscriptions absence distributions
	**/
	function setAbsences( subscription:db.Subscription, distribIds:Array<Int> ) {

		//check there is no duplicates
		if(tools.ArrayTool.deduplicate(distribIds).length != distribIds.length){
			throw new Error(500,"Vous ne pouvez pas choisir deux fois la même distribution");
		}

		//check if absence number is correct
		if(subscription.id!=null && distribIds.length != subscription.getAbsencesNb()){
			throw new Error('There should be ${subscription.getAbsencesNb()} absent distribs');
		}

		//check if absent distribs are correct
		var possibleDistribs = subscription.getPossibleAbsentDistribs().map(d -> d.id);
		throw possibleDistribs;
		for(did in distribIds){
			if(!possibleDistribs.has(did)){
				throw new Error('Distrib #${did} is not in possible absent distribs');
			} 
		}

		// /!\ we dont check here if a *new* absence has been set on a closed distribution !
		// --> On the frontend, closed distributions are disabled and cannot be selected.
		
		if( distribIds != null && distribIds.length != 0 ) {
			distribIds.sort( function(b, a) { return  a < b ? 1 : -1; } );
			subscription.absentDistribIds = distribIds.join(',');
		} else {
			subscription.absentDistribIds = null;
		}
	}

	public static function checkUser2(ordersData:Array<CSAOrder>):Int{
		//check that there is only one secondary user
		var user2 = null;
		for( order in ordersData){
			if(order.userId2!=null){
				if(user2==null){
					user2=order.userId2;
				}else if(user2!=order.userId2){
					throw new Error("Il n'est pas possible d'alterner vos paniers avec plusieurs personnes. Choisissez un seul binôme.");
				}
			}
		}
		return user2;
	}

	/**
		Update an existing subscription.
		Optionnaly updates recurrent order(CONST) or default order(VAR) with ordersData param
	**/
	public function updateSubscription( subscription:db.Subscription, startDate:Date, endDate:Date, ?ordersData:Array<CSAOrder>) {

		if ( startDate == null || endDate == null ) {
			throw new Error( 'La date de début et de fin de la souscription doivent être définies.' );
		}

		subscription.lock();

		var previousStartDate = subscription.startDate;
	
		subscription.startDate = new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate(), 0, 0, 0 );
		subscription.endDate = new Date( endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59 );
		
		//check secondary user for CONSTORDERS
		if(subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS && ordersData!=null){
			var userId2 = checkUser2(ordersData);
			if(userId2!=null){
				subscription.user2 = db.User.manager.get(userId2,false);
			}
		}
		
		check(subscription,previousStartDate);

		subscription.update();

		if(ordersData!=null){
			if( subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS ) { 
				//CONST
				createCSARecurrentOrders( subscription, ordersData );
			}else{
				//VAR
				updateDefaultOrders( subscription, ordersData );			
			}
		}
	}

	public static function getAbsentDistribsMaxNb( catalog:Catalog/*, ?subscription:Subscription*/ ) {


		if ( !catalog.hasAbsencesManagement() ) return 0;
		return catalog.absentDistribsMaxNb;

		/*if ( subscription == null || subscription.startDate == null || subscription.endDate == null ||
			( subscription.startDate.getTime() <= catalog.absencesStartDate.getTime() && subscription.endDate.getTime() >= catalog.absencesEndDate.getTime() ) ) {
			return catalog.absentDistribsMaxNb;
		} else {

			var absencesDistribsNbDuringSubscription = 0;
			if ( subscription.startDate.getTime() > catalog.absencesStartDate.getTime() && subscription.endDate.getTime() < catalog.absencesEndDate.getTime() ) {
				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= subscription.startDate && $end <= subscription.endDate );
			} else if ( subscription.startDate.getTime() > catalog.absencesStartDate.getTime() ) {
				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= subscription.startDate && $end <= catalog.absencesEndDate );
			} else {
				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= catalog.absencesStartDate && $end <= subscription.endDate );
			}

			if ( absencesDistribsNbDuringSubscription <= catalog.absentDistribsMaxNb ) {
				return absencesDistribsNbDuringSubscription;
			} else {
				return catalog.absentDistribsMaxNb;
			}
		}*/
	}

	/**
		get automatically absence distributions from an asbence number ( last distributions of the subscription )
	**/
	public function getAutomaticAbsentDistribs(catalog:db.Catalog, absencesNb:Int):Array<db.Distribution>{		
		if( !catalog.hasAbsencesManagement() ) return [];
		if(absencesNb==null) return [];
		
		if ( absencesNb > catalog.absentDistribsMaxNb ) {
			throw new Error( 'Nombre de jours d\'absence invalide, vous avez droit à ${catalog.absentDistribsMaxNb} jours d\'absence maximum.' );
		}

		var distribs = SubscriptionService.getContractAbsencesDistribs(catalog);
		if ( absencesNb > distribs.length ) {
			throw new Error( 'Nombre de jours d\'absence invalide, il n\'y a que ${distribs.length} distributions pendant le période d\'absence de cette souscription.' );
		}

		//sort from later to sooner distrib
		distribs.sort( (a,b)-> Math.round(b.date.getTime()/1000) - Math.round(a.date.getTime()/1000) );

		return distribs.slice(0,absencesNb);
	}

	/**
		Set Absences Number on a newly created subscription
	**/
	/*public function setAbsencesNb( subscription:Subscription, absencesNb:Int ) {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );
		if( !subscription.catalog.hasAbsencesManagement() ) return;
		if(absencesNb==null) return;
		
		//a user can only choose absenceNb on subscription creation
		//an admin can change it at anytime
		if ( subscription.id == null || adminMode) {
			
			if ( absencesNb > subscription.catalog.absentDistribsMaxNb ) {
				throw new Error( 'Nombre de jours d\'absence invalide, vous avez droit à ${subscription.catalog.absentDistribsMaxNb} jours d\'absence maximum.' );
			}

			var distribs = subscription.getPossibleAbsentDistribs();
			if ( absencesNb > distribs.length ) {
				throw new Error( 'Nombre de jours d\'absence invalide, il n\'y a que ${distribs.length} distributions pendant le période d\'absence de cette souscription.' );
			}

			//sort from later to sooner distrib
			distribs.sort( (a,b)-> Math.round(b.date.getTime()/1000) - Math.round(a.date.getTime()/1000) );

			subscription.setAbsences( distribs.slice(0,absencesNb).map(d -> d.id) );

		} else {
			throw new Error('Il n\'est pas possible de modifier le nombre de jours d\'absence sur une souscription déjà créée.' );			
		}
	}*/


	public static function markAsPaid( subscription : Subscription, ?paid : Bool = true ){
		subscription.lock();
		subscription.isPaid = paid;
		subscription.update();
	}

	public static function getOperations( subscription : db.Subscription, ?lock=false):Array<db.Operation>{
		return db.Operation.manager.search( $subscription == subscription, { orderBy : -date }, lock ).array();
	}

	 /**
	  *  Deletes a subscription if there is no orders that occurred in the past
	  */
	public static function deleteSubscription( subscription : db.Subscription ) {
		
		subscription.lock();

		if ( hasPastDistribOrders( subscription ) && !subscription.catalog.isDemoCatalog() ) {
			throw TypedError.typed( 'Impossible de supprimer cette souscription car il y a des distributions passées avec des commandes.', PastOrders );
		}

		//cant delete if some payment has been recorded
		var hasPayments = subscription.catalog.hasPayments;
		var subscriptionOperations = db.Operation.manager.count( $subscription == subscription && $type==Payment );
		if ( hasPayments && subscriptionOperations > 0 ) {
			throw new Error( 'Impossible de supprimer cette souscription car il y a des paiements enregistrés.' );
		}

		//Delete all the orders for this subscription
		var subscriptionOrders = db.UserOrder.manager.search( $subscription == subscription, false );
		for ( order in subscriptionOrders ) {
			OrderService.delete(order,true);
		}

		//Delete all the operations for this subscription
		for ( operation in getOperations(subscription,true) ) operation.delete();
		
		if( subscription.catalog.hasPayments ) {
			service.PaymentService.updateUserBalance( subscription.user, subscription.catalog.group );
		}

		subscription.delete();
	}

	/**
	 *  Checks whether there are orders with non zero quantity in the past
	 */
	public static function hasPastDistribOrders( subscription:db.Subscription ) : Bool {

		if ( !hasPastDistributions( subscription ) ) {
			return false;
		} else {

			var pastDistributions = getSubscriptionDistributions( subscription, 'past' );
			for ( distribution in pastDistributions ) {

				if ( db.UserOrder.manager.count( $distribution == distribution && $subscription == subscription ) != 0 ) {					
					return true;
				}
			}
		}		
		return false;		
	}

	public static function hasPastDistribOrdersOutsideSubscription( subscription : db.Subscription ) : Bool {
		
		var now = Date.now();
		var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );
		var orders =  db.UserOrder.manager.search( $subscription == subscription, false ).array();
		for ( order in orders ) {

			if ( order.distribution != null ) {

				if ( order.distribution.date.getTime() <= endOfToday.getTime() && ( order.distribution.date.getTime() < subscription.startDate.getTime() || order.distribution.date.getTime() > subscription.endDate.getTime() ) ) {					
					return true;
				}
			}
			
		}
		
		return false;
		
	}

	public static function hasPastDistribsWithoutOrders( subscription : db.Subscription ) : Bool {

		if ( !hasPastDistributions( subscription ) ) {

			return false;

		} else if ( /*( subscription.catalog.type == db.Catalog.TYPE_VARORDER && subscription.catalog.requiresOrdering ) ||*/ subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS ) {
			//fbarbut 2021-01-13 : on ne veut pas bloquer les commandes si le contrat est variable avec commande obligatoires, et qu'il y a des distributions sans commandes.
			var pastDistributions = getSubscriptionDistributions( subscription, 'past' );
			for ( distribution in pastDistributions ) {
				if ( db.UserOrder.manager.count( $distribution == distribution && $subscription == subscription ) == 0 ) {
					return true;
				}
			}
		}
		return false;
	}

	
	public static function hasPastDistributions( subscription : db.Subscription ) : Bool {
		return getSubscriptionDistribsNb( subscription, 'past' ) != 0;
	}

	/**
		Create contract's recurrent orders
	**/
	public function createCSARecurrentOrders(subscription:db.Subscription, ordersData:Array<CSAOrder>, ?oldAbsentDistribIds:Array<Int> ) : Array<db.UserOrder> {

		if ( ordersData == null || ordersData.length == 0 ) {
			ordersData = [];
			var subscriptionOrders = getCSARecurrentOrders( subscription, oldAbsentDistribIds );
			for ( order in subscriptionOrders ) {
				ordersData.push( { productId : order.product.id, quantity : order.quantity, userId2 : order.user2 != null ? order.user2.id : null, invertSharedOrder : order.hasInvertSharedOrder() } );
			}
		} else if ( hasPastDistribOrders( subscription ) && !adminMode ) {

			throw TypedError.typed( 'Il y a des commandes pour des distributions passées. Les commandes du passé ne pouvant être modifiées, il faut modifier la date de fin de
			la souscription et en recréer une nouvelle pour la nouvelle période. Vous pourrez ensuite définir une nouvelle commande pour cette nouvelle souscription.', SubscriptionServiceError.PastOrders );
		}

		var subscriptionAllOrders = getSubscriptionAllOrders( subscription );
		for ( order in subscriptionAllOrders ) {
			OrderService.delete(order,true);
		}
	
		var t = sugoi.i18n.Locale.texts;
	
		var orders : Array<db.UserOrder> = [];
		for ( distribution in getSubscriptionDistributions(subscription) ) {

			for ( order in ordersData ) {

				if ( order.quantity > 0 ) {

					var product = db.Product.manager.get( order.productId, false );
					// User2 + Invert
					var user2 : db.User = null;
					var invert = false;
					if ( order.userId2 != null && order.userId2 != 0 ) {

						user2 = db.User.manager.get( order.userId2, false );
						if ( user2 == null ) throw new Error( t._( "Unable to find user #::num::", { num : order.userId2 } ) );
						if ( subscription.user.id == user2.id ) throw new Error( t._( "Both selected accounts must be different ones" ) );
						if ( !user2.isMemberOf( product.catalog.group ) ) throw new Error( t._( "::user:: is not part of this group", { user : user2 } ) );
						
						invert = order.invertSharedOrder;
					}
					
					var newOrder =  OrderService.make( subscription.user, order.quantity , product,  distribution.id, false, subscription, user2, invert );
					if ( newOrder != null ) orders.push( newOrder );
				}
			}
		}
		
		App.current.event( MakeOrder( orders ) );

		if ( subscription.catalog.hasPayments ) {
			// create/update a single operation for the subscription total price
			createOrUpdateTotalOperation( subscription );
		}

		return orders;	
	}	

	/*public static function getLastDistribBeforeAbsences( catalog:db.Catalog ) : db.Distribution {

		if ( !catalog.hasAbsencesManagement() ) return null;
		
		var catalogDistribs = catalog.getDistribs( false ).array();
		var lastDistribBeforeAbsences : db.Distribution = catalogDistribs[0];
		for ( distrib in catalogDistribs ) {

			if ( distrib.date.getTime() < catalog.absencesStartDate.getTime() ) {
				lastDistribBeforeAbsences = distrib;
			} else {
				break;
			}
		}

		return lastDistribBeforeAbsences;
	}*/

	/**
		can change absences number ?
	**/
	public static function canAbsencesNbBeEdited( catalog:db.Catalog, subscription:db.Subscription ):Bool {

		if( !catalog.hasAbsencesManagement() ) return false;

		if(subscription!=null){
			if(subscription.id==null){
				//can edit absence number only on creation
				return true;
			}else{
				return false;
			}

		}else{
			return true;
		}
		// var lastDistribBeforeAbsences = getLastDistribBeforeAbsences( catalog );
		// if( lastDistribBeforeAbsences == null ) return false;

		// var deadline = lastDistribBeforeAbsences.date.getTime();
		// var beforeDeadline = Date.now().getTime() < deadline;
		// var subscriptionInAbsencesPeriod = subscription == null || ( subscription.startDate.getTime() < deadline && subscription.endDate.getTime() > catalog.absencesStartDate.getTime() );
		// var forbidden = catalog.type == db.Catalog.TYPE_CONSTORDERS && subscription != null && subscription.paid();

		// return !forbidden && beforeDeadline && subscriptionInAbsencesPeriod;
		
	}

	/**
		can change absences ?
	**/
	public static function canAbsencesBeEdited( catalog:db.Catalog ) : Bool {
		// return catalog.hasAbsencesManagement() && Date.now().getTime() < getLastDistribBeforeAbsences( catalog ).date.getTime();
		return catalog.hasAbsencesManagement();
	}

	/**
		Updates a subscription's absences
	**/
	public function updateAbsencesDates( subscription:db.Subscription, newAbsentDistribIds:Array<Int> ) {
		var oldAbsentDistribIds = subscription.getAbsentDistribIds();

		subscription.lock();
		setAbsences( subscription, newAbsentDistribIds );
		subscription.update();

		if ( subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS ) {
			//regen recurrent orders
			this.createCSARecurrentOrders( subscription, null, oldAbsentDistribIds );
		} else {
			//remove orders in new absence dates
			var absentDistribsOrders = db.UserOrder.manager.search( $subscription == subscription && $distributionId in newAbsentDistribIds, false );
			for ( order in absentDistribsOrders ) {
				order.lock();
				order.delete();
			}
		}

	}

	/**
		Update default orders on a variable contract with requiresOrdering
	**/
	public function updateDefaultOrders( subscription:db.Subscription, defaultOrders:Array<CSAOrder>){

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );		
		if( !subscription.catalog.requiresOrdering ) return;
		if ( subscription.catalog.requiresOrdering && (defaultOrders==null || defaultOrders.length==0 ) ) {
			throw new Error('La commande par défaut ne peut pas être vide. (Souscription de ${subscription.user.getName()})');
		}

		// if( subscription.catalog.type==Catalog.TYPE_CONSTORDERS) return;
		
		var totalPrice : Float = 0;
		var totalQuantity : Float = 0;
		for ( order in defaultOrders ) {

			var product = db.Product.manager.get( order.productId, false );
			if ( product != null && order.quantity != null && order.quantity != 0 ) {

				totalPrice += Formatting.roundTo( order.quantity * product.price, 2 );
				totalQuantity += order.quantity;
			}
		}
		totalPrice = Formatting.roundTo( totalPrice, 2 );
		
		//Let's check that it meets the constraint when there is one
		if ( subscription.catalog.distribMinOrdersTotal != null && subscription.catalog.distribMinOrdersTotal != 0 ) {

			if ( totalPrice < subscription.catalog.distribMinOrdersTotal ) {
				var message = '<strong>Engagement du catalogue :</strong> ' + subscription.catalog.name + '<br/>';
				message += 'Le total de votre commande par défaut doit être d\'au moins ' + subscription.catalog.distribMinOrdersTotal + ' €. Veuillez rajouter des produits.';
				throw TypedError.typed( message, CatalogRequirementsNotMet );
			}
		} else {

			if ( totalQuantity < 0.1 ) {
				var message = '<strong>Engagement du catalogue :</strong> ' + subscription.catalog.name + '<br/>';
				message += 'La commande par défaut ne peut pas être vide.';
				throw TypedError.typed( message, CatalogRequirementsNotMet );
			}
		}

		subscription.lock();
		subscription.setDefaultOrders( defaultOrders );
		subscription.update();
	}

	public static function createOrUpdateTotalOperation( subscription:db.Subscription ) : db.Operation {

		if( subscription == null )  throw new Error( 'Pas de souscription fournie.' );

		var totalOperation : db.Operation = null;

		if ( subscription.catalog.hasPayments ) {

			totalOperation = db.Operation.manager.select ( $user == subscription.user && $subscription == subscription && $type == SubscriptionTotal, true );
	
			if( totalOperation == null ) {
	
				totalOperation = new db.Operation();
				totalOperation.name = "Total Commandes";
				totalOperation.type = SubscriptionTotal;
				totalOperation.user = subscription.user;
				totalOperation.subscription = subscription;
				totalOperation.group = subscription.catalog.group;
				totalOperation.pending = false;
			}
	
			//create or update it if needed
			var currentTotalPrice = subscription.getTotalPrice();
			if( totalOperation.id == null || totalOperation.amount != (0 - currentTotalPrice) ) {

				totalOperation.date = Date.now();
				totalOperation.amount = 0 - currentTotalPrice;
		
				if ( totalOperation.id != null ) {
					totalOperation.update();
				} else {		
					totalOperation.insert();
				}
		
				service.PaymentService.updateUserBalance( totalOperation.user, totalOperation.group );
			}			
		}
		return totalOperation;
	}

	public static function updateCatalogSubscriptionsOperation( catalog : db.Catalog ) {

		var group = catalog.group;
		if ( group.hasPayments()) {

			var catalogSubsciptions = SubscriptionService.getCatalogSubscriptions(catalog);
			for ( subscription in catalogSubsciptions ) {

				createOrUpdateTotalOperation( subscription );
			}
			
		}
	}

	public static function transferBalance( fromSubscription : db.Subscription, toSubscription : db.Subscription ) {

		var balance = fromSubscription.getBalance();
		
		if( fromSubscription == null || toSubscription == null )  throw new Error( 'Pas de souscriptions fournies.' );
		if( fromSubscription.user.id != toSubscription.user.id )  throw new Error( 'Le transfert est possible uniquement pour un même membre.' );
		if( balance <= 0 ) throw new Error( 'Impossible de transférer un solde négatif ou à zéro.' );
		
		if( !toSubscription.catalog.hasPayments ) throw new Error('Les paiements ne sont pas activés sur ce contrat');
		if( !fromSubscription.catalog.hasPayments ) throw new Error("Les paiements ne sont pas activés sur ce contrat");

		var operationFrom = new db.Operation();
		operationFrom.name = "Transfert du solde sur la souscription #" + toSubscription.id + " de " + toSubscription.catalog.name;
		operationFrom.type = Payment;
		operationFrom.setPaymentData( { type : 'transfer' } );
		operationFrom.user = fromSubscription.user;
		operationFrom.subscription = fromSubscription;
		operationFrom.group = fromSubscription.catalog.group;
		operationFrom.pending = false;
		operationFrom.date = Date.now();
		operationFrom.amount = 0 - balance;

		var operationTo = new db.Operation();
		operationTo.name = "Transfert du solde de la souscription #" + fromSubscription.id + " de " + fromSubscription.catalog.name;
		operationTo.type = Payment;
		operationTo.setPaymentData( { type : 'transfer' } );
		operationTo.user = toSubscription.user;
		operationTo.subscription = toSubscription;
		operationTo.group = toSubscription.catalog.group;
		operationTo.pending = false;
		operationTo.date = Date.now();
		operationTo.amount = balance;

		operationFrom.insert();
		operationTo.insert();
	
		service.PaymentService.updateUserBalance( fromSubscription.user, fromSubscription.catalog.group );
		if( fromSubscription.catalog.group.id != toSubscription.catalog.group.id  ) {
			service.PaymentService.updateUserBalance( fromSubscription.user, toSubscription.catalog.group );
		}

	}

	public static function getDistribOrdersAverageTotal( subscription : db.Subscription ) : Float {

		if( subscription == null || subscription.id == null )  throw new Error( 'Pas de souscription fournie.' );

		var distribsOrderedNb = sys.db.Manager.cnx.request('SELECT COUNT(DISTINCT distributionId) FROM UserOrder WHERE subscriptionId=${subscription.id}').getIntResult(0);
		if( distribsOrderedNb == 0 ) return 0;

		return subscription.getTotalPrice() / distribsOrderedNb;
	}
	
}