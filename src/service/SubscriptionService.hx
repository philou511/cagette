package service;
import db.Group.RegOption;
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

/**
 * Subscription service
 * @author web-wizard
 */
class SubscriptionService
{

	/**
		get subscriptions of a catalog
	**/
	public static function getSubscriptions( catalog : db.Catalog ) {

		return db.Subscription.manager.search( $catalogId == catalog.id, false ).array();
	}

	/**
		Get user subscriptions in active catalogs
	**/
	public static function getActiveSubscriptions( user : db.User, group : db.Group ) : Array<db.Subscription> {

		var catalogIds = group.getActiveContracts().map( c -> return c.id );
		return db.Subscription.manager.search( ( $user == user || $user2 == user ) && ( $catalogId in catalogIds ), false ).array();
	}

	/**
		Get user active subscriptions, ordered by catalogs.
		This includes the subscriptions as a secondary user.
	**/
	public static function getActiveSubscriptionsByCatalog( user : db.User, group : db.Group ) : Map< db.Catalog, Array< db.Subscription > > {

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

	public static function getComingDistribSubscription( user : db.User, catalog : db.Catalog, ?isValidated : Bool ) : db.Subscription {

		var now = Date.now();
		var notClosedComingDistrib : db.Distribution = null;
		var subscription : db.Subscription = null;
		if ( catalog.type == db.Catalog.TYPE_CONSTORDERS ) {

			if ( catalog.orderEndHoursBeforeDistrib == null || catalog.orderEndHoursBeforeDistrib == 0 ) {

				throw new Error( 'Vous devez définir obligatoirement le nombre d\'heures avant distribution pour la fermeture des commandes.' );
			}

			var futureDistribs = db.Distribution.manager.search( $catalog == catalog && $date > now, { orderBy : date }, false ).array();
			for ( distrib in futureDistribs ) {

				var orderEndDate = DateTools.delta( distrib.date, -(1000 * 60 * 60 * catalog.orderEndHoursBeforeDistrib) );
				if ( now.getTime() < orderEndDate.getTime() ) {

					notClosedComingDistrib = distrib;
					break;
				}
			}
			
		}
		else {

			var notClosedFutureDistribs = db.Distribution.manager.search( $catalog == catalog && $date > now && $orderEndDate > now, { orderBy : date }, false ).array();
			if ( notClosedFutureDistribs.length != 0 ) { 

				notClosedComingDistrib = notClosedFutureDistribs[0];
			}
		}


		if( notClosedComingDistrib != null ) {

			if( isValidated != null ) {

				subscription = db.Subscription.manager.select( $user == user && $catalog == catalog && $startDate <= notClosedComingDistrib.date && $endDate >= notClosedComingDistrib.end && $isValidated == isValidated, false );
			}
			else {
		
				subscription = db.Subscription.manager.select( $user == user && $catalog == catalog && $startDate <= notClosedComingDistrib.date && $endDate >= notClosedComingDistrib.end, false );
			}
		}
		
		//JB TODO EXCLUDE ABSENTDISTRIB

		return subscription;
		
	}

	public static function getUserCatalogSubscriptions( user : db.User, catalog : db.Catalog ) : Array<db.Subscription> {
		
		if( user == null || user.id == null ) throw new Error( 'Le membre que vous cherchez n\'existe pas');

		return db.Subscription.manager.search( $user == user && $catalog == catalog , false ).array();
	}

	public static function getSubscriptionDistribs( subscription : db.Subscription, type : String = 'all' ) : Array<db.Distribution> {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );

		var subscriptionDistribs = null;
		if ( type == "all" ) {

			subscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate, { orderBy : date }, false );
		}
		else if ( type == "past" ) {

			var now = Date.now();
			var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );			
			subscriptionDistribs = db.Distribution.manager.search( $catalog == subscription.catalog  && $end <= endOfToday && $date >= subscription.startDate && $end <= subscription.endDate, false );
		}
		
		if ( subscriptionDistribs.length != 0 && subscription.catalog.hasAbsencesManagement() ) {

			var absentDistribs = subscription.getAbsentDistribs();
			for ( absentDistrib in absentDistribs ) {

				subscriptionDistribs = subscriptionDistribs.filter( distrib -> return distrib.id != absentDistrib.id );
			}
		}
		
		return subscriptionDistribs.array();
	}

	public static function getCatalogAbsencesDistribs( catalog : db.Catalog, ?subscription : db.Subscription ) : Array<db.Distribution> {

		if ( !catalog.hasAbsencesManagement() ) return [];

		var absencesStartDate : Date = null;
		var absencesEndDate : Date = null;
		if ( subscription == null ) {

			absencesStartDate = catalog.absencesStartDate;
			absencesEndDate = catalog.absencesEndDate;
		}
		else {

			absencesStartDate = subscription.startDate.getTime() < catalog.absencesStartDate.getTime() ? catalog.absencesStartDate : subscription.startDate;
			absencesEndDate = catalog.absencesEndDate.getTime() < subscription.endDate.getTime() ? catalog.absencesEndDate : subscription.endDate;
		}

		return db.Distribution.manager.search( $catalog == catalog && $date >= absencesStartDate && $end <= absencesEndDate, { orderBy : date }, false ).array();
	}

	public static function getCatalogAbsencesDistribsNb( catalog : db.Catalog, ?absStartDate : Date, ?absEndDate : Date ) : Int {

		var absencesStartDate : Date = absStartDate != null ? absStartDate : catalog.absencesStartDate;
		var absencesEndDate : Date = absEndDate != null ? absEndDate : catalog.absencesEndDate;
		
		if ( absencesStartDate == null || absencesEndDate == null ) {

			return 0;
		}

		return db.Distribution.manager.count( $catalog == catalog && $date >= absencesStartDate && $end <= absencesEndDate );

	}

	public static function getSubscriptionDistribsNb( subscription : db.Subscription, ?type : String = null, excludeAbsences : Bool = true ) : Int {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );

		var subscriptionDistribsNb = 0;
		if ( type == null ) {

			subscriptionDistribsNb = db.Distribution.manager.count( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate );
		}
		else if ( type == "past" ) {

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

	public static function getCSARecurrentOrders( subscription : db.Subscription, oldAbsentDistribIds : Array<Int> ) : Array<db.UserOrder> {
		
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

	public static function isSubscriptionPaid( subscription : db.Subscription ) : Bool {

		/*
		var orders = db.UserOrder.manager.search( $subscription == subscription, false );
		for ( order in orders ) {
			if ( !order.paid ) {
				return false;
			}
		}
		return true;*/
		return subscription.isPaid;

	}

	//REPRENDRE A PARTIR D'ICI POUR LA CONSOLIDATION ET RECHERHCE DE POSSIBLES NULL OU 0
	public static function getDescription( subscription : db.Subscription ) {

		var label : String = '';
		if ( subscription.catalog.type == db.Catalog.TYPE_VARORDER ) {

			if ( subscription.catalog.requiresOrdering ) {
				
				label += 'Obligation de commander à chaque distribution<br />';
			}

			if ( subscription.catalog.distribMinOrdersTotal != null && subscription.catalog.distribMinOrdersTotal != 0 ) {
				
				label += 'Minimum de commande par distribution : ' + subscription.catalog.distribMinOrdersTotal + ' €<br />';
			}

			var catalogMinOrdersTotal = getCatalogMinOrdersTotal( subscription.catalog, subscription );
			if ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 && subscription.catalog.allowedOverspend != null && subscription.catalog.allowedOverspend != 0 ) {
				
				label += 'Minimum de commandes sur la durée du contrat : ' + catalogMinOrdersTotal + ' €<br />';
				label += 'Dépassement autorisé : ' + subscription.catalog.allowedOverspend + ' €<br />';
			}

		}
		else {

			var subscriptionOrders = getCSARecurrentOrders( subscription, null );

			if( subscriptionOrders.length == 0 ) return null;
			for ( order in subscriptionOrders ) {

				label += tools.FloatTool.clean( order.quantity ) + ' x ' + order.product.name + '<br />';
			}

		}

		if( label == '' ) return null;

		return label;
	}

	/**
	 * Checks if dates are correct and if there is no other subscription for this user in that same time range
	 * @param subscription
	 */
	public static function isSubscriptionValid( subscription : db.Subscription, ?previousStartDate : Date ) : Bool {

		//When creating a new subscription the startDate needs to be for the next not closed coming 
		if(subscription.startDate.getTime() >= subscription.endDate.getTime()){
			throw TypedError.typed( 'La date de début de la souscription doit être antérieure à la date de fin.', InvalidParameters );
		}

		//Check new subscription Start Date
		var newSubscriptionStartDate = getNewSubscriptionStartDate( subscription.catalog );
		if( subscription.id == null ) {

			if ( subscription.startDate.getTime() < newSubscriptionStartDate.getTime() ) {

				throw TypedError.typed( 'La date de début de la souscription ne doit pas être avant la date de la prochaine distribution ouverte aux commandes : '
										+ Formatting.dDate( newSubscriptionStartDate ), InvalidParameters );
			}
		}
		else {
			
			if ( previousStartDate.toString() != subscription.startDate.toString() ) {

				if ( Date.now().getTime() <= subscription.startDate.getTime() && subscription.startDate.getTime() < newSubscriptionStartDate.getTime() ) {

					throw TypedError.typed( 'La date de début de la souscription ne doit pas être avant la date de la prochaine distribution ouverte aux commandes : '
										+ Formatting.dDate( newSubscriptionStartDate ), InvalidParameters );
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
			var subs = subscriptions1.concat(subscriptions2).concat(subscriptions3);
			throw TypedError.typed( 'Il y a déjà une souscription pour ce membre pendant la période choisie.'+"("+subs.join(',')+")", OverlappingSubscription );
		}

		if ( subscription.isValidated ) {

			var view = App.current.view;

			if ( subscription.id != null && hasPastDistribOrdersOutsideSubscription( subscription ) ) {
				throw TypedError.typed( 
					'La nouvelle période sélectionnée exclue des commandes déjà passées, Il faut élargir la période sélectionnée $subName.',
					PastOrders
				);
			}

			if ( hasPastDistribsWithoutOrders( subscription ) ) {
				throw TypedError.typed(
					'La nouvelle période sélectionnée inclue des distributions déjà passées auxquelles le membre n\'a pas participé, Il faut choisir une date ultérieure $subName.',
					PastDistributionsWithoutOrders
				);
			}
		}

		return true;
	}


	public static function getCatalogMinOrdersTotal( catalog : db.Catalog, subscription : db.Subscription ) : Float {

		if ( catalog.catalogMinOrdersTotal == null || catalog.catalogMinOrdersTotal == 0 || catalog.allowedOverspend == null || catalog.allowedOverspend == 0 ) {

			return null;
		}

		var subscriptionDistribsNb = 0;
		if ( subscription != null ) {
		
			subscriptionDistribsNb = getSubscriptionDistribsNb( subscription, null, true );
		}
		else {

			subscriptionDistribsNb = db.Distribution.manager.count( $catalog == catalog && $date >= SubscriptionService.getNewSubscriptionStartDate( catalog ) );
		}
		
		var catalogAllDistribsNb = db.Distribution.manager.count( $catalog == catalog );
		if ( catalogAllDistribsNb == 0 ) return null;
		var ratio = subscriptionDistribsNb / catalogAllDistribsNb;

		return Formatting.roundTo( ratio * catalog.catalogMinOrdersTotal, 0 );
	}

	 /*
	  *	Checks if automated orders are valid
	  * @param subscription 
	  * @param distribution 
	  * @return Bool
	  */
	  public static function areAutomatedOrdersValid( subscription : db.Subscription, distribution : db.Distribution ) : Bool {

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
	}


	 /*
	  *	Checks if variable orders for one or several distributions meet all the catalog requirements 
	  * @param subscription 
	  * @param pricesQuantitiesByDistrib 
	  * @return Bool
	  */
	 public static function areVarOrdersValid( subscription : db.Subscription, pricesQuantitiesByDistrib : Map< db.Distribution, Array< { productQuantity : Float, productPrice : Float } > > ) : Bool {

		var catalog : db.Catalog = null;
		if ( subscription != null ) {

			catalog = subscription.catalog;
		}
		else {

			catalog = pricesQuantitiesByDistrib.keys().next().catalog;
		}

		var catalogMinOrdersTotal = getCatalogMinOrdersTotal( catalog, subscription );
		if ( ( catalog.distribMinOrdersTotal == null || catalog.distribMinOrdersTotal == 0 ) && ( catalogMinOrdersTotal == null || catalogMinOrdersTotal == 0 || catalog.allowedOverspend == null || catalog.allowedOverspend == 0 ) ) {

			return true;
		}

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
					message += 'Le total de votre commande effectuée pour une distribution donnée doit être d\'au moins ' + catalog.distribMinOrdersTotal + ' €. Veuillez rajouter des produits.';
					throw TypedError.typed( message, CatalogRequirementsNotMet );
				}

			}
		}

		if ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 && catalog.allowedOverspend != null && catalog.allowedOverspend != 0 ) {

			//Computes the new orders total
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

				var allSubsriptionDistribs = getSubscriptionDistribs( subscription, 'all' );
				lastDistrib = allSubsriptionDistribs[ allSubsriptionDistribs.length - 1 ];
			}
			else {

				lastDistrib = catalog.getDistribs().last();
			}

			if( lastDistrib != null ) {

				var now = Date.now();
				var doCheckMin = false;
				if ( catalog.requiresOrdering ) {

					if ( ordersDistribIds.find( id -> id == lastDistrib.id ) != null ) {
	
						doCheckMin = true;
					}
				}
				else if ( lastDistrib.orderStartDate.getTime() <= now.getTime() &&  now.getTime() < lastDistrib.orderEndDate.getTime() ) {
	
					doCheckMin = true;
				}

				if ( doCheckMin ) {

					if ( subscriptionNewTotal < catalogMinOrdersTotal ) {
	
						var message = 'Le nouveau total de toutes vos commandes sur la durée du contrat serait de '+  subscriptionNewTotal
						+ ' € alors qu\'il doit être supérieur à ' + catalogMinOrdersTotal + ' €. Veuillez rajouter des produits.';
						throw TypedError.typed( message, CatalogRequirementsNotMet );
					}
				}
			}

			//Checks that the orders total is lower than the allowed overspend
			var maxAllowedTotal = catalogMinOrdersTotal + catalog.allowedOverspend;
			if ( maxAllowedTotal < subscriptionNewTotal ) {

				var message = 'Le nouveau total de toutes vos commandes serait de ' +  subscriptionNewTotal
				+ ' € alors qu\'il doit être inférieur à ' + maxAllowedTotal + ' €. Veuillez enlever des produits.';
				throw TypedError.typed( message, CatalogRequirementsNotMet );
			}

		}

		return true;
	}

	public static function getNewSubscriptionStartDate( catalog : db.Catalog ) : Date {

		var now = Date.now();
		var comingOpenDistrib : db.Distribution = null;

		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

			comingOpenDistrib = db.Distribution.manager.search( $catalog == catalog && $date > now && $orderStartDate <= now && $orderEndDate > now, { orderBy : date }, false ).first();
		}
		else {

			if ( catalog.orderEndHoursBeforeDistrib == null || catalog.orderEndHoursBeforeDistrib == 0 ) throw new Error( 'Il faut définir un nombre d\'heures pour la fermeture des commandes.' );

			var futureDistribs = db.Distribution.manager.search( $catalog == catalog && $date > now, { orderBy : date }, false );
			for ( distrib in futureDistribs ) {

				var orderEndDate = DateTools.delta( distrib.date, -(1000 * 60 * 60 * catalog.orderEndHoursBeforeDistrib) );
				if ( orderEndDate.getTime() > now.getTime() ) {

					comingOpenDistrib = distrib;
					break;
				}
			}
			
		}
		
		if ( comingOpenDistrib != null ) {

			return new Date( comingOpenDistrib.date.getFullYear(), comingOpenDistrib.date.getMonth(), comingOpenDistrib.date.getDate(), 0, 0, 0 );
		}
		else {

			throw new Error( 'Impossible de souscrire car il n\'y a pas de distribution ouverte à la commande.' );
		}

	}

	 /**
	  *  Creates a new subscription and prevents subscription overlapping and other checks
	  *  @return db.Subscription
	  */
	 public static function createSubscription( user : db.User, catalog : db.Catalog,
		?ordersData : Array< { productId : Int, quantity : Float, ?userId2 : Int, ?invertSharedOrder : Bool } >,
		?absencesNb : Int, ?startDate : Date, ?endDate : Date ) : db.Subscription {

		if ( startDate == null ) {
			
			startDate = getNewSubscriptionStartDate( catalog );
		}

		if ( endDate == null ) {
			
			endDate = catalog.endDate;
		}
		
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
		subscription.endDate 	= new Date( endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59 );
		subscription.isValidated = false;
		
		if( catalog.type == db.Catalog.TYPE_CONSTORDERS ) {

			var user2 = checkUser2( ordersData );
			subscription.user2 = db.User.manager.get( user2, false );
		}
		
		updateAbsencesNb( subscription, absencesNb );
		
		if ( isSubscriptionValid( subscription ) ) {

			subscription.insert();

			if( catalog.type == db.Catalog.TYPE_CONSTORDERS ) { 

				createCSARecurrentOrders( subscription, ordersData );
			}
			
		}

		updateDefaultOrders( subscription, ordersData );

		return subscription;
	}

	public static function checkUser2(ordersData:Array<{ productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool }>):Int{
		//check that there is only one secondary user
		var user2= null;
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


	public static function updateSubscription( subscription : db.Subscription, startDate : Date, endDate : Date, 
	 ?ordersData : Array<{ productId:Int, quantity:Float, userId2:Int, invertSharedOrder:Bool }>, ?absentDistribIds : Array<Int>, ?absencesNb : Int ) {

		if ( startDate == null || endDate == null ) {
			throw new Error( 'La date de début et de fin de la souscription doivent être définies.' );
		}

		subscription.lock();

		var previousStartDate = subscription.startDate;
	
		subscription.startDate = new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate(), 0, 0, 0 );
		subscription.endDate = new Date( endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59 );
		if ( absentDistribIds != null ) {

			if ( subscription.isValidated ) {

				subscription.setAbsentDistribIds( absentDistribIds );
			}
		}
		updateAbsencesNb( subscription, absencesNb );
		
		//check secondary user
		var userId2 = checkUser2(ordersData);
		if(userId2!=null){
			subscription.user2 = db.User.manager.get(userId2,false);
		}

		if ( isSubscriptionValid( subscription, previousStartDate ) ) {

			subscription.update();
			if( subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS ) { 

				createCSARecurrentOrders( subscription, ordersData );
			}
		}

		updateDefaultOrders( subscription, ordersData );

	}

	public static function getAbsentDistribsMaxNb( catalog : Catalog, ?subscription : Subscription ) {

		if ( !catalog.hasAbsencesManagement() ) return 0;

		if ( subscription == null || subscription.startDate == null || subscription.endDate == null ||
			( subscription.startDate.getTime() <= catalog.absencesStartDate.getTime() && subscription.endDate.getTime() >= catalog.absencesEndDate.getTime() ) ) {

			return catalog.absentDistribsMaxNb;
		}
		else {

			var absencesDistribsNbDuringSubscription = 0;
			if ( subscription.startDate.getTime() > catalog.absencesStartDate.getTime() && subscription.endDate.getTime() < catalog.absencesEndDate.getTime() ) {

				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= subscription.startDate && $end <= subscription.endDate );
			}
			else if ( subscription.startDate.getTime() > catalog.absencesStartDate.getTime() ) {

				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= subscription.startDate && $end <= catalog.absencesEndDate );
			}
			else {

				absencesDistribsNbDuringSubscription = db.Distribution.manager.count( $catalog == catalog && $date >= catalog.absencesStartDate && $end <= subscription.endDate );
			}

			if ( absencesDistribsNbDuringSubscription <= catalog.absentDistribsMaxNb ) {

				return absencesDistribsNbDuringSubscription;
			}
			else {

				return catalog.absentDistribsMaxNb;
			}

		}
	
	}

	public static function updateAbsencesNb( subscription : Subscription, newAbsencesNb : Int ) {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );
		if( !subscription.catalog.hasAbsencesManagement() ) return;

		var currentAbsencesNb = subscription.getAbsencesNb();
		if ( newAbsencesNb == currentAbsencesNb ) { return; }

		var absentDistribIds : Array<Int> = null;
		if ( newAbsencesNb != null && newAbsencesNb != 0 ) {

			absentDistribIds = new Array<Int>();
			if ( subscription.id == null || currentAbsencesNb == 0 ) {

				//Let's select the newAbsencesNb first distribs of the absences period in the subscription time range
				var absencesDistribs = getCatalogAbsencesDistribs( subscription.catalog, subscription );

				if ( newAbsencesNb > absencesDistribs.length ) {
					throw new Error( 'Il n\'y a seulement que ' + absencesDistribs.length +  ' distributions pendant la période des absences.' );
				}
				for ( i in 0...newAbsencesNb ) {
					
					absentDistribIds.push( absencesDistribs[i].id );
				}
			}
			else {

				var currentAbsentDistribIds = subscription.getAbsentDistribIds();
				var absencesNbDiff = newAbsencesNb - currentAbsencesNb;
				if ( absencesNbDiff < 0 ) {

					for ( i in 0...newAbsencesNb ) {

						absentDistribIds.push( currentAbsentDistribIds[i] );
					}
				}
				else if ( absencesNbDiff > 0 ) {

					for ( i in 0...currentAbsencesNb ) {

						absentDistribIds.push( currentAbsentDistribIds[i] );
					}

					var absencesDistribs = getCatalogAbsencesDistribs( subscription.catalog, subscription );
					var absencesDistribsNb = absencesDistribs.length;

					for ( i in 0...absencesNbDiff ) {

						if ( ( i + currentAbsencesNb ) > ( absencesDistribsNb - 1 ) ) {
							throw new Error( 'Il n\'y a seulement que ' + absencesDistribsNb +  ' distributions pendant la période des absences.' );
						}
						absentDistribIds.push( absencesDistribs[ i + currentAbsencesNb ].id );
					}
				}

			}

		}

		subscription.setAbsentDistribIds( absentDistribIds );
	}


	public static function updateValidation( subscription : Subscription, ?validate : Bool = true ){

		subscription.lock();
		if ( validate ) {

			subscription.isValidated = true;
			subscription.isPaid = true;
		}
		else {

			subscription.isValidated = false;
			subscription.isPaid = false;
		}

		subscription.update();
	}

	 /**
	  *  Deletes a subscription if there is no orders that occurred in the past
	  *  @return db.Subscription
	  */
	 public static function deleteSubscription( subscription : db.Subscription ) {

		if ( hasPastDistribOrders( subscription ) && !subscription.catalog.isDemoCatalog() ) {

			throw TypedError.typed( 'Impossible de supprimer cette souscription car il y a des distributions passées avec des commandes.', PastOrders );
		}

		//Delete all the orders for this subscription
		var subscriptionOrders = db.UserOrder.manager.search( $subscription == subscription, false );
		for ( order in subscriptionOrders ) {
			OrderService.delete(order,true);
		}
		//Delete the subscription
		subscription.lock();
		subscription.delete();

	}

	

	/**
	 *  Checks whether there are orders with non zero quantity in the past
	 *  @param d - 
	 *  @return Bool
	 */
	public static function hasPastDistribOrders( subscription : db.Subscription ) : Bool {

		if ( !subscription.isValidated || !hasPastDistributions( subscription ) ) {

			return false;
		}
		else {

			var pastDistributions = getSubscriptionDistribs( subscription, 'past' );
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
		}
		else {

			var pastDistributions = getSubscriptionDistribs( subscription, 'past' );
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


	public static function createCSARecurrentOrders( subscription : db.Subscription,
		ordersData : Array< { productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool } >, ?oldAbsentDistribIds : Array<Int> ) : Array<db.UserOrder> {


		if ( ordersData == null || ordersData.length == 0 ) {

			ordersData = new Array< { productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool } >();
			var subscriptionOrders = getCSARecurrentOrders( subscription, oldAbsentDistribIds );
			for ( order in subscriptionOrders ) {

				ordersData.push( { productId : order.product.id, quantity : order.quantity, userId2 : order.user2 != null ? order.user2.id : null, invertSharedOrder : order.hasInvertSharedOrder() } );
			}
		}
		else if ( hasPastDistribOrders( subscription ) ) {

			throw TypedError.typed( 'Il y a des commandes pour des distributions passées. Les commandes du passé ne pouvant être modifiées il faut modifier la date de fin de
			la souscription et en recréer une nouvelle pour la nouvelle période. Vous pourrez ensuite définir une nouvelle commande pour cette nouvelle souscription.', SubscriptionServiceError.PastOrders );
		}

		var subscriptionAllOrders = getSubscriptionAllOrders( subscription );
		for ( order in subscriptionAllOrders ) {
			OrderService.delete(order,true);
		}

		var subscriptionDistributions = getSubscriptionDistribs( subscription );

		var t = sugoi.i18n.Locale.texts;
	
		var orders : Array<db.UserOrder> = [];
		for ( distribution in subscriptionDistributions ) {

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

		if(subscription.catalog.group.hasPayments()){
			service.PaymentService.onOrderConfirm( orders );
		}

		return orders;
		
	}

	public static function getLastDistribBeforeAbsences( catalog : db.Catalog ) : db.Distribution {

		if ( !catalog.hasAbsencesManagement() ) return null;
		
		var catalogDistribs = catalog.getDistribs( false ).array();
		var lastDistribBeforeAbsences : db.Distribution = catalogDistribs[0];
		for ( distrib in catalogDistribs ) {

			if ( distrib.date.getTime() < catalog.absencesStartDate.getTime() ) {

				lastDistribBeforeAbsences = distrib;
			}
			else {

				break;
			}

		}

		return lastDistribBeforeAbsences;
	}

	public static function canAbsencesNbBeEdited( catalog : db.Catalog, subscription : db.Subscription ) : Bool {
		
		return catalog.hasAbsencesManagement() && ( subscription == null || !subscription.isValidated );
	}

	public static function canAbsencesBeEdited( catalog : db.Catalog ) : Bool {

		if ( !catalog.hasAbsencesManagement() ) return false;

		return Date.now().getTime() < getLastDistribBeforeAbsences( catalog ).date.getTime();
	}

	public static function updateAbsencesDates( subscription : db.Subscription, newAbsentDistribIds : Array<Int> ) {
   
		var oldAbsentDistribIds = subscription.getAbsentDistribIds();

		//Check that dates have actually changed
		var datesHaveChanged = false;
		var newDatesNb = newAbsentDistribIds.length;
		for ( i in 0...newDatesNb ) {

			if ( newAbsentDistribIds[i] != oldAbsentDistribIds[i] ) {

				datesHaveChanged = true;
				break;
			}
		}

		if ( !datesHaveChanged ) return;

		subscription.lock();
		subscription.setAbsentDistribIds( newAbsentDistribIds );
		subscription.update();

		if ( subscription.catalog.type == db.Catalog.TYPE_CONSTORDERS ) {

			createCSARecurrentOrders( subscription, null, oldAbsentDistribIds );
		}
		else {

			var absentDistribsOrders = db.UserOrder.manager.search( $subscription == subscription && $distributionId in newAbsentDistribIds, false );
			for ( order in absentDistribsOrders ) {

				order.lock();
				order.delete();
			}

		}

	}

	public static function updateDefaultOrders( subscription : db.Subscription, defaultOrders : Array< { productId : Int, quantity : Float } > ) {

		if( subscription == null ) throw new Error( 'La souscription n\'existe pas' );
		if( subscription.catalog.requiresOrdering != true ) return;
		if( defaultOrders.length == 0 ) throw new Error( 'La commande par défaut n\'est pas définie.' );
		
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
		}
		else {

			if ( totalQuantity < 0.1 ) {

				var message = '<strong>Engagement du catalogue :</strong> ' + subscription.catalog.name + '<br/>';
				message += 'La commande par défaut ne peut pas être vide. Vous devez obligatoirement commander quelque chose.';
				throw TypedError.typed( message, CatalogRequirementsNotMet );
			}
		}

		subscription.lock();
		subscription.setDefaultOrders( defaultOrders );
		subscription.update();
	}
	
}