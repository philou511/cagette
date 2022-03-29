package controller;
import sugoi.form.elements.Html;
import service.PaymentService;
import sugoi.Web;
import payment.Check;
import sugoi.db.Cache;
import db.Catalog;
import db.Operation.OperationType;
import service.SubscriptionService;
import tink.core.Error;

class Subscriptions extends controller.Controller
{
	public function new(){
		super();		
	}
	
	/**
		View all the subscriptions for a catalog
	**/
	@tpl("contractadmin/subscriptions.mtt")
	function doDefault( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogSubscriptions = SubscriptionService.getCatalogSubscriptions(catalog);

		//subs sorting
		var orderBy = app.params.get("orderBy");
		if(orderBy=="userName" || orderBy==null){
			catalogSubscriptions.sort( (a,b) -> a.user.lastName > b.user.lastName ? 1 : -1);
			orderBy = "userName";
		}
		view.orderBy = orderBy;
	
		view.catalog = catalog;
		view.c = catalog;
		view.subscriptions = catalogSubscriptions;
		if ( catalog.hasPayments ) {
			view.negativeBalanceCount = catalogSubscriptions.count( function( subscription ) { return  subscription.getBalance() < 0; } );
		} else {
			view.negativeBalanceCount = catalogSubscriptions.count( function( subscription ) { return  !subscription.paid(); } );
			/*view.negativeBalanceCount = catalogSubscriptions.count( s -> s.getBalance() < 0 );

			catalogSubscriptions.sort(function(a,b){
				if( a.user.lastName > b.user.lastName ){
					return 1;
				}else{
					return -1;
				}
			});

		} else {
			view.negativeBalanceCount = catalogSubscriptions.count( s ->  !s.paid() );

			//sort by validation, then username
			catalogSubscriptions.sort(function(a,b){
				if( (a.paid()?"1":"0")+a.user.lastName > (b.paid()?"1":"0")+b.user.lastName ){
					return 1;
				}else{
					return -1;
				}
			});
			*/
		}
		
		view.dateToString = function( date : Date ) {
			return DateTools.format( date, "%d/%m/%Y");
		}
		view.subscriptionService = SubscriptionService;
		view.nav.push( 'subscriptions' );

		//generate a token
		checkToken();
	}
	
	public function doDelete( subscription : db.Subscription ) {
		
		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
		
		var subscriptionUser = subscription.user;
		if ( checkToken() ) {
			try {
				SubscriptionService.deleteSubscription( subscription );
			} catch( error : Error ) {
				throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, error.message );
			}
			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription pour ' + subscriptionUser.getName() + ' a bien été supprimée.' );
		}
		throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, t._("Token error") );
	}

	@tpl("contractadmin/editsubscription.mtt")
	public function doInsert( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var subscriptionService = new SubscriptionService();
		subscriptionService.adminMode = true;

		var catalogProducts = catalog.getProducts();

		var startDateDP = new form.CagetteDatePicker("startDate","Date de début", SubscriptionService.getNewSubscriptionStartDate( catalog ) );
		view.startDate = startDateDP;
		var endDateDP = new form.CagetteDatePicker("endDate","Date de fin",catalog.endDate);
		view.endDate = endDateDP;

		if ( checkToken() ) {

			try {				
				var userId = Std.parseInt( app.params.get( "user" ) );
				if ( userId == null || userId == 0 ) {
					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, 'Veuillez sélectionner un membre.' );
				}
				var user = db.User.manager.get( userId, false );
				if ( user == null ) {
					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, t._( "Unable to find user #::num::", { num : userId } ) );
				}
				if ( !user.isMemberOf( catalog.group ) ) {
					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, user + " ne fait pas partie de ce groupe" );
				}
				
				startDateDP.populate();
				endDateDP.populate();
				var startDate = startDateDP.getValue();
				var endDate = endDateDP.getValue();

				if ( startDate == null || endDate == null ) {
					throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, "Vous devez sélectionner une date de début et de fin pour la souscription." );
				}
				
				var ordersData = new Array<CSAOrder>();
				for ( product in catalogProducts ) {

					var quantity : Float = 0;
					var qtyParam = app.params.get( 'quantity' + product.id );
					if ( qtyParam != "" ) quantity = Std.parseFloat( qtyParam );
					var user2 : db.User = null;
					var userId2 : Int = null;
					if( catalog.type == Catalog.TYPE_CONSTORDERS ) {
						userId2 = Std.parseInt( app.params.get( 'user2' + product.id ) );
					}
					var invert = false;
					if ( userId2 != null && userId2 != 0 ) {

						user2 = db.User.manager.get( userId2, false );
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
						if( catalog.type == Catalog.TYPE_CONSTORDERS ) {
							ordersData.push( { 
								productId : product.id,
								productPrice : product.price,
								quantity : quantity,
								userId2 : userId2,
								invertSharedOrder : invert
							});
						} else {
							ordersData.push( { productId : product.id, productPrice : product.price, quantity : quantity } );
						}
					}					
				}

				var absencesNb = Std.parseInt( app.params.get( 'absencesNb' ) );				
				subscriptionService.createSubscription( user, catalog, ordersData, null, absencesNb, startDate, endDate );
				throw Ok( '/contractAdmin/subscriptions/' + catalog.id, 'La souscription pour ' + user.getName() + ' a bien été ajoutée.' );

			} catch( error : Error ) {
				throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, error.message );
			}

		}
			
		view.edit = false;
		view.canOrdersBeEdited = true;
		view.c = catalog;
		view.catalog = catalog;
		view.members = app.user.getGroup().getMembersFormElementData();
		view.products = catalogProducts;
		view.subscriptionService = SubscriptionService;

		view.nav.push( 'subscriptions' );
	}

	/**
		An admin user edits a subscription
	**/
	@tpl("contractadmin/editsubscription.mtt")
	public function doEdit( subscription:db.Subscription ) {

		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogProducts = subscription.catalog.getProducts();

		var startDateDP = new form.CagetteDatePicker("startDate","Date de début",subscription.startDate);
		var endDateDP = new form.CagetteDatePicker("endDate","Date de fin",subscription.endDate);
		view.endDate = endDateDP;
		view.startDate = startDateDP;

		var subscriptionService = new service.SubscriptionService();
		subscriptionService.adminMode = true;
		

		if ( checkToken() ) {

			try {
				startDateDP.populate();
				endDateDP.populate();
				var startDate = startDateDP.getValue();
				var endDate = endDateDP.getValue();
				subscription.lock();

				if ( startDate == null || endDate == null ) {
					throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, "Vous devez sélectionner une date de début et de fin pour la souscription." );
				}

				var ordersData = new Array<CSAOrder>();
				
				//get orders from the form ( constant order, ou default order is catalog.requiresOrdering)
				for ( product in catalogProducts ) {

					var quantity : Float = 0;
					var qtyParam = app.params.get( 'quantity' + product.id );
					if ( qtyParam != "" ) quantity = Std.parseFloat( qtyParam );
					var user2 : db.User = null;
					var userId2 : Int = null;
					if( subscription.catalog.type == Catalog.TYPE_CONSTORDERS ) {							
						userId2 = Std.parseInt( app.params.get( 'user2' + product.id ) );
					}
					var invert = false;
					if ( userId2 != null && userId2 != 0 ) {

						user2 = db.User.manager.get( userId2, false );
						if ( user2 == null ) {
							throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, t._( "Unable to find user #::num::", { num : userId2 } ) );
						}

						if ( !user2.isMemberOf( subscription.catalog.group ) ) {
							throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, subscription.user + " ne fait pas partie de ce groupe." );
						}

						if ( subscription.user.id == user2.id ) {
							throw Error( '/contractAdmin/subscriptions/edit/' + subscription.id, "Vous ne pouvez pas alterner avec la personne qui a la souscription." );
						}

						invert = app.params.get( 'invert' + product.id ) == "true";
					}

					if ( quantity!=null && quantity > 0 ) {
						if( subscription.catalog.type == Catalog.TYPE_CONSTORDERS ) {
							ordersData.push( { 
								productId : product.id,
								productPrice : product.price,
								quantity : quantity,
								userId2 : userId2,
								invertSharedOrder : invert
							} );
						} else {
							ordersData.push( { productId : product.id, productPrice: product.price,  quantity : quantity } );
						}
					}						
				}

				subscriptionService.updateSubscription( subscription, startDate, endDate, ordersData);				
				// subscriptionService.setAbsencesNb( subscription, app.params.get('absencesNb').parseInt() );
				subscription.update();

			} catch( error : Error ) {				
				throw Error( '/contractAdmin/subscriptions/edit/${subscription.id}', error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/${subscription.catalog.id}', 'La souscription de ${subscription.user.getName()} a bien été mise à jour.' );
		}

		view.edit = true;
		// view.canOrdersBeEdited = canOrdersBeEdited;
		view.c = subscription.catalog;
		view.catalog = subscription.catalog;
		view.members = app.user.getGroup().getMembersFormElementData();
		view.products = catalogProducts;
		view.getProductOrder = function( productId : Int ) {		
			return SubscriptionService.getCSARecurrentOrders( subscription, null ).find( function( order ) return order.product.id == productId );
		};
		view.startdate = subscription.startDate;
		view.enddate = subscription.endDate;
		view.subscription = subscription;
		view.nav.push( 'subscriptions' );
		view.subscriptionService = SubscriptionService;
		// view.absencesDistribs = Lambda.map( SubscriptionService.getAbsencesDistribs( subscription.catalog, subscription ), function( distrib ) return { label : Formatting.hDate( distrib.date, true ), value : distrib.id } );
		view.canAbsencesBeEdited = SubscriptionService.canAbsencesBeEdited( subscription.catalog );
		view.absentDistribs = subscription.getAbsentDistribs();
		// if ( subscription.catalog.type == Catalog.TYPE_VARORDER || !subscription.paid() ) {
		// 	view.absencesDistribDates = Lambda.map( SubscriptionService.getAbsencesDistribs( subscription.catalog, subscription ), function( distrib ) return Formatting.dDate( distrib.date ) );
		// }

	}


	public function doMarkAsPaid( subscription : db.Subscription ) {
		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
		try {
			SubscriptionService.markAsPaid( subscription );
		} catch( error : Error ) {
			throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, error.message );
		}
		throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription de ' + subscription.user.getName() + ' a bien été validée.' );
	}

	@admin
	public function doUnmarkAsPaid( subscription : db.Subscription ) {

		if( checkToken() ) {

			SubscriptionService.markAsPaid( subscription, false );
			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'Souscription dévalidée' );
		}

	}

	@tpl("contractadmin/subscriptionpayments.mtt")
	public function doPayments( subscription : db.Subscription ) {

		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
		if ( !subscription.catalog.hasPayments ) throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La gestion des paiements n\'est pas activée.' );

		//Let's do an update just in case the total operation is not coherent
		view.subscriptionTotal = SubscriptionService.createOrUpdateTotalOperation( subscription );

		var user = subscription.user;
		var payments = db.Operation.manager.search( $user == user && $subscription == subscription && $type == Payment, { orderBy : -date }, false );
		
		view.payments = payments;
		view.member = user;
		view.subscription = subscription;
		
		view.nav.push( 'subscriptions' );
		view.c = subscription.catalog;
		
		checkToken();
	}

	@tpl("contractadmin/subscriptionbalancetransfer.mtt")
	public function doBalanceTransfer( subscription : db.Subscription ) {

		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
		if ( !subscription.catalog.hasPayments ) throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La gestion des paiements n\'est pas activée.' );

		if ( subscription.getBalance() <= 0 ) throw Error( '/contractAdmin/subscriptions/payments/' + subscription.id, 'Le solde doit être positif pour pouvoir le transférer sur une autre souscription.' );
		var subscriptionsChoices = SubscriptionService.getUserVendorNotClosedSubscriptions( subscription );
		if ( subscriptionsChoices.length == 0  ) throw Error( '/contractAdmin/subscriptions/payments/' + subscription.id, 'Ce membre n\'a pas d\'autre souscription. Veuillez en créer une nouvelle avec le même producteur.' );

		if ( checkToken() ) {
			try {
				var subscriptionId = Std.parseInt( app.params.get( 'subscription' ) );
				if ( subscriptionId == null ) throw Error( '/contractAdmin/subscriptions/balanceTransfer/' + subscription.id, "Vous devez sélectionner une souscription." );

				var selectedSubscription = db.Subscription.manager.get( subscriptionId );
				SubscriptionService.transferBalance( subscription, selectedSubscription );
				
			} catch( error : Error ) {
				throw Error( '/contractAdmin/subscriptions/balanceTransfer/' + subscription.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/payments/' + subscription.id, 'Le transfert a bien été effectué.' );
		}

		view.title = "Report de solde pour " + subscription.user.getName();
		view.c = subscription.catalog;
		view.subscriptions = subscriptionsChoices;
		view.nav.push( 'subscriptions' );
	}


	/**
		user can edit his absences.
		The user can't change his absence number.
	**/
	@logged @tpl("form.mtt")
	function doAbsences( subscription:db.Subscription, ?args:{returnUrl:String} ) {

		if( subscription.catalog.group.hasShopMode() ) throw Redirect( "/contract/view/" + subscription.catalog.id );
		if ( !app.user.canManageContract(subscription.catalog) && !(app.user.id==subscription.user.id) ){
			throw Error( '/', t._('Access forbidden') );
		} 

		var subService = new SubscriptionService();
		if ( args != null && args.returnUrl != null ) {
			App.current.session.data.absencesReturnUrl = args.returnUrl;
		}
		if( !SubscriptionService.canAbsencesBeEdited( subscription.catalog ) ) {
			throw Redirect( App.current.session.data.absencesReturnUrl );
		}
		
		var absenceDistribs = subscription.getAbsentDistribs();
		var possibleAbsences = subscription.getPossibleAbsentDistribs();
		var now = Date.now().getTime();
		possibleAbsences = possibleAbsences.filter(d -> d.orderEndDate.getTime() > now);
		var lockedDistribs = absenceDistribs.filter( d -> d.orderEndDate.getTime() < now);	//absences that are not editable anymore
		
		var form = new sugoi.form.Form("subscriptionAbsences");		
		var possibleAbsencesData = possibleAbsences.map( d -> { label : Formatting.hDate(d.date,true), value : d.id } );
		for ( i in 0...subscription.getAbsencesNb() ) {
			if( lockedDistribs.has(absenceDistribs[i]) ){
				//absence cannot be modified anymore, too late !
				form.addElement(new sugoi.form.elements.Html('absenceLocked',Formatting.dDate(absenceDistribs[i].date)+" (trop tard pour changer)","Je serai absent(e) le :"));
			}else{
				form.addElement(new sugoi.form.elements.IntSelect( "absentDistrib" + i, "Je serai absent(e) le :", possibleAbsencesData, absenceDistribs[i].id, true ));
			}			
		}
		
		if ( form.checkToken() ) {

			try {
				var absentDistribIds = lockedDistribs.map(d->d.id);
				for ( i in 0...absenceDistribs.length ) {				
					if(form.getElement('absentDistrib' + i)!=null){
						absentDistribIds.push( form.getValueOf( 'absentDistrib' + i ) );	
					}					
				}
				subService.updateAbsencesDates( subscription, absentDistribIds );				
			} catch( error:Error ) {
				throw Error( '/subscriptions/absences/' + subscription.id, error.message );
			}

			throw Ok( App.current.session.data.absencesReturnUrl, 'Les dates d\'absences ont bien été mises à jour.' );
		}

		view.form = form;
		view.text = '<b>${subscription.getAbsencesNb()}</b> absences autorisées dans la période du <b>${DateTools.format( subscription.catalog.absencesStartDate, "%d/%m/%Y" )}</b> au <b>${DateTools.format( subscription.catalog.absencesEndDate, "%d/%m/%Y")}</b>';
		view.title = "Absences de "+subscription.user.getName()+" pour le contrat \""+subscription.catalog.name+"\"";
		
	}
	
	@admin
	public function doUnmarkAll(catalog : db.Catalog){

		for ( subscription in SubscriptionService.getCatalogSubscriptions(catalog) ) {
			SubscriptionService.markAsPaid( subscription, false );
		}
		throw Ok("/contractAdmin/subscriptions/"+catalog.id,'Souscriptions dévalidées');
	}

	/**
	 * inserts a payment for a CSA contract
	 */
	@tpl('form.mtt')
	public function doInsertPayment( subscription : db.Subscription ) {
		
		if (!app.user.isContractManager()) throw Error("/", t._("Action forbidden"));	
		var t = sugoi.i18n.Locale.texts;

		var group = subscription.catalog.group;
		if(group.hasShopMode()){ throw Error("/","accès interdit"); }
		
		var returnUrl = '/contractAdmin/subscriptions/payments/${subscription.id}';
		var form = new sugoi.form.Form("payement");

		form.addElement( new sugoi.form.elements.Html( "subscription", '<div class="control-label" style="text-align:left;"> ${ subscription.catalog.name } - ${ subscription.catalog.vendor.name } </div>', 'Souscription' ) );
		
		form.addElement(new sugoi.form.elements.StringInput("name", t._("Label||label or name for a payment"), "Paiement", false));
		var amount:Float = null;
		if(subscription.getBalance()<0) amount = Math.abs(subscription.getBalance());
		form.addElement(new sugoi.form.elements.FloatInput("amount", t._("Amount"), amount, true));
		form.addElement(new form.CagetteDatePicker("date", t._("Date"), Date.now(), sugoi.form.elements.NativeDatePicker.NativeDatePickerType.date, true));
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, group);
		var out = [];
		var selected = null;
		for (paymentType in paymentTypes){
			out.push({label: paymentType.name, value: paymentType.type});
			if(paymentType.type==Check.TYPE) selected=Check.TYPE;
		}
		form.addElement(new sugoi.form.elements.StringSelect("Mtype", t._("Payment type"), out, selected, true));
		
		if (form.isValid()){

			var operation = new db.Operation();
			form.toSpod(operation);
			operation.type = db.Operation.OperationType.Payment;			
			operation.setPaymentData({type:form.getValueOf("Mtype")});
			operation.group = group;
			operation.user = subscription.user;
			operation.subscription = subscription;
			operation.pending = false;
			operation.insert();
			service.PaymentService.updateUserBalance( subscription.user, group );
			throw Ok( returnUrl, t._("Payment recorded") );
		}
		
		view.title = t._("Record a payment for ::user::",{user:subscription.user.getCoupleName()}) ;
		view.form = form;
	}

	@tpl("contractadmin/masspayments.mtt")
	function doMassPayments(catalog:db.Catalog){

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );
		var catalogSubscriptions = SubscriptionService.getCatalogSubscriptions(catalog);

		view.catalog = catalog;
		view.c = catalog;
		view.subscriptions = catalogSubscriptions;
		catalogSubscriptions.sort(function(a,b){
			if( a.user.lastName > b.user.lastName ){
				return 1;
			}else{
				return -1;
			}
		});
		
		var paymentTypes = service.PaymentService.getPaymentTypes(PCManualEntry, catalog.group);
		var out = [];
		var selected = null;
		for (paymentType in paymentTypes){
			out.push({label: paymentType.name, value: paymentType.type});
			if(paymentType.type==Check.TYPE) selected=Check.TYPE;
		}
		view.paymentTypes = out;
		view.selected = selected;
		view.dateToString = Formatting.shortDate;
		view.subscriptionService = SubscriptionService;
		view.nav.push( 'subscriptions' );

		if(checkToken()){
			
			var params = Web.getParams();
			for( sub in catalogSubscriptions.copy()){
				var amount = params.get('sub${sub.id}_amount').parseFloat();
				if(amount!=null && amount>0){
					
					var paymentType = params.get('sub${sub.id}_paymentType');
					var label = params.get('sub${sub.id}_label');

					var op = PaymentService.makePaymentOperation(sub.user,catalog.group,paymentType,amount,label);
					op.subscription = sub;
					op.update();

				}else{
					catalogSubscriptions.remove(sub);
				}
			}

			throw Ok(sugoi.Web.getURI(),catalogSubscriptions.length+" paiements saisis, les soldes ont été mis à jour.");

		}

	}

}