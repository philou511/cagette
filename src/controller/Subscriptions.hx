package controller;
import tink.core.Error;
using Lambda;

class Subscriptions extends controller.Controller
{
	public function new()
	{
		super();		
	}

	
	//  View all the subscriptions for a catalog
	@tpl("contractadmin/subscriptions.mtt")
	function doDefault( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogSubscriptions = db.Subscription.manager.search( $catalogId == catalog.id,false ).array();
		catalogSubscriptions.sort( function(b, a) {
		
			return  a.user.getName() < b.user.getName() ? 1 : -1;
		} );

		view.catalog = catalog;
		view.group = db.Group.manager.get( catalog.group.id );
		view.c = catalog;
		view.subscriptions = catalogSubscriptions;

		view.dateToString = function( date : Date ) {

			return DateTools.format( date, "%d/%m/%Y");
		}
		view.subscriptionService = service.SubscriptionService;
		view.nav.push( 'subscriptions' );

		//generate a token
		checkToken();
	}
	
	@tpl("form.mtt")
	public function doPrevEdit( subscription : db.Subscription ) {

		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );

		var form = new sugoi.form.Form( 'editsubscription' );
		var startDatePicker = new sugoi.form.elements.DatePicker( 'startDate', 'Date de début', subscription.startDate );
		startDatePicker.format = 'LL';
		form.addElement( startDatePicker );
		var endDatePicker = new sugoi.form.elements.DatePicker( 'endDate', 'Date de fin', subscription.endDate );
		endDatePicker.format = 'LL';
		form.addElement( endDatePicker );

		if ( form.isValid() ) {

			try {

				service.SubscriptionService.updateSubscription( subscription, form.getValueOf( 'startDate' ), form.getValueOf( 'endDate' ) );

			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription pour ' + subscription.user.getName() + ' a bien été mise à jour.' );
		}
	
		view.form = form;
		view.title = 'Modification de dates de la souscription pour ' + subscription.user.getName();
		view.c = subscription.catalog;
		view.catalog = subscription.catalog;
		view.nav.push( 'subscriptions' );
	}


	public function doDelete( subscription : db.Subscription ) {
		
		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
		
		var subscriptionUser = subscription.user;
		if ( checkToken() ) {

			try {

				service.SubscriptionService.deleteSubscription( subscription );

			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription pour ' + subscriptionUser.getName() + ' a bien été supprimée.' );
			
		}

		throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, t._("Token error") );
	}


	@tpl("form.mtt")
	public function doPrevInsert( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var subscription = new db.Subscription();
		var form = new sugoi.form.Form( 'newsubscription' );
		form.addElement( new sugoi.form.elements.IntSelect( 'userId', 'Membre', app.user.getGroup().getMembersFormElementData(), null, true ) );
		form.addElement( new sugoi.form.elements.Html( "html", "<hr/>" ) );
		form.addElement( new sugoi.form.elements.Html( "qty", "Quantité" ) );
		var catalogProducts = catalog.getProducts();
		for ( product in catalogProducts ) {

			form.addElement( new sugoi.form.elements.IntInput( "product" + product.id, product.name + " " + product.price + " €", 0, true ) );
		}
		form.addElement( new sugoi.form.elements.Html( "html", "<hr/>" ) );
		var startDatePicker = new sugoi.form.elements.DatePicker( 'startDate', 'Date de début', catalog.startDate.getTime() > Date.now().getTime() ? catalog.startDate : Date.now() );
		startDatePicker.format = 'LL';
		form.addElement( startDatePicker );
		var endDatePicker = new sugoi.form.elements.DatePicker( 'endDate', 'Date de fin', catalog.endDate );
		endDatePicker.format = 'LL';
		form.addElement( endDatePicker );

		if ( form.isValid() ) {

			try {
				
				form.toSpod( subscription );			
				service.SubscriptionService.createSubscription( subscription.user, catalog, subscription.startDate, subscription.endDate );
				var ordersData = new Array< { id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int } >();
				for ( product in catalogProducts ) {

					var quantity = form.getValueOf( 'product' + product.id );
					if ( quantity != 0 ) {

						ordersData.push( { id : null, productId : product.id, qt : quantity, paid : false, invertSharedOrder : false, userId2 : null } );
					}
					
				}
				service.OrderService.createOrUpdateOrders( db.User.manager.get( form.getValueOf( 'userId' ) ), null, catalog, ordersData );

			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/' + catalog.id, 'La souscription pour ' + subscription.user.getName() + ' a bien été ajoutée.' );
		}
	
		view.form = form;
		view.title = 'Nouvelle souscription pour ' + catalog.name;
		view.c = catalog;
		view.catalog = catalog;
		view.nav.push( 'subscriptions' );
	}

	@tpl("contractadmin/editsubscription.mtt")
	public function doInsert( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogProducts = catalog.getProducts();

		if ( checkToken() ) {

			try {
				
				var userId = Std.parseInt( app.params.get( "user" ) );
				if ( userId == null || userId == 0 ) {

					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, 'Veuillez sélectionner un membre.' );
				}
				var user = db.User.manager.get( userId );
				if ( user == null ) {

					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, t._( "Unable to find user #::num::", { num : userId } ) );
				}
				if ( !user.isMemberOf( catalog.group ) ) {

					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, user + " ne fait pas partie de ce groupe" );
				}

				var startDate = Date.fromString( app.params.get( "startdate" ) );
				var endDate = Date.fromString( app.params.get( "enddate" ) );
				if ( startDate == null || endDate == null ) {

					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, "Vous devez sélectionner une date de début et de fin pour la souscription." );
				}
				
				var ordersData = new Array< { id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int } >();
				for ( product in catalogProducts ) {

					var quantity : Float = Std.parseFloat( app.params.get( 'quantity' + product.id ) );
					var user2 : db.User = null;
					var userId2 : Int = Std.parseInt( app.params.get( 'user2' + product.id ) );
					var invert = false;
					if ( userId2 != null && userId2 != 0 ) {

						user2 = db.User.manager.get( userId2 );
						if ( user2 == null ) {

							throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, t._( "Unable to find user #::num::", { num : userId2 } ) );
						}
						if ( !user2.isMemberOf( catalog.group ) ) {

							throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, user + " ne fait pas partie de ce groupe." );
						}
						if ( user.id == user2.id ) {
							
							throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, "Vous ne pouvez pas alterner avec la personne qui a la souscription." );
						}

						invert = app.params.get( 'invert' + product.id ) == "true";

					}

					if ( quantity != 0 ) {

						ordersData.push( { id : null, productId : product.id, qt : quantity, paid : false, invertSharedOrder : invert, userId2 : userId2 } );
					}
					
				}

				if ( ordersData.length == 0 ) {

					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, "Vous devez entrer au moins une quantité pour un produit." );
				}

				var subscription = new db.Subscription();
				subscription.user = user;
				subscription.catalog = catalog;
				subscription.startDate = startDate;
				subscription.endDate = endDate;
				service.SubscriptionService.createSubscription( user, catalog, startDate, endDate );
				service.OrderService.createOrUpdateOrders( user, null, catalog, ordersData );

				throw Ok( '/contractAdmin/subscriptions/' + catalog.id, 'La souscription pour ' + user.getName() + ' a bien été ajoutée.' );

			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, error.message );
			}

		}
	
		view.title = 'Nouvelle souscription';
		view.c = catalog;
		view.catalog = catalog;
		view.showmember = true;
		view.members = app.user.getGroup().getMembersFormElementData();
		view.products = catalogProducts;
		view.startdate = catalog.startDate.getTime() > Date.now().getTime() ? catalog.startDate : Date.now();
		view.enddate = catalog.endDate;
		view.nav.push( 'subscriptions' );

	}

	@tpl("contractadmin/editsubscription.mtt")
	public function doEdit( subscription : db.Subscription ) {

		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogProducts = subscription.catalog.getProducts();

		if ( checkToken() ) {

			var startDate = Date.fromString( app.params.get( "startdate" ) );
			var endDate = Date.fromString( app.params.get( "enddate" ) );
			if ( startDate == null || endDate == null ) {

				throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, "Vous devez sélectionner une date de début et de fin pour la souscription." );
			}

			try {

				service.SubscriptionService.updateSubscription( subscription, startDate, endDate );

			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription pour ' + subscription.user.getName() + ' a bien été mise à jour.' );
		}
	
		view.title = 'Modification de la souscription pour ' + subscription.user.getName();
		view.c = subscription.catalog;
		view.catalog = subscription.catalog;
		view.showmember = false;
		view.members = app.user.getGroup().getMembersFormElementData();
		view.products = catalogProducts;
		view.getProductOrder = function( productId : Int ) {

			return service.SubscriptionService.getSubscriptionOrders( subscription ).find( function( order ) return order.product.id == productId );
		};
		view.startdate = subscription.startDate;
		view.enddate = subscription.endDate;
		view.nav.push( 'subscriptions' );
	}


}
