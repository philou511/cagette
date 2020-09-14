package controller;
import sugoi.Web;
import tink.core.Error;
import service.VendorService;
import service.SubscriptionService;
import tools.DateTool;
import db.MultiDistrib;
import db.Catalog;
import db.UserOrder;
import db.VolunteerRole;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import Common;
import plugin.Tutorial;
import service.OrderService;
import form.CagetteForm;

class Contract extends Controller
{

	public function new() 
	{
		super();
		view.nav = ["contractadmin"];
	}
	
	//retrocompat
	@logged
	public function doDefault(){
		throw Redirect("/account");
	}

	/**
		view catalog infos for shop mode groups
	**/
	@tpl("contract/view.mtt")
	public function doView( catalog : db.Catalog ) {

		if(!catalog.group.hasShopMode()) throw Redirect("/contract/order/"+catalog.id);

		view.category = 'amap';
		view.catalog = catalog;
	
		view.visibleDocuments = catalog.getVisibleDocuments( app.user );
	}
	
	/**
		1- define the vendor
	**/
	@logged @tpl("form.mtt")
	function doDefineVendor(?type=1){
		if (!app.user.canManageAllContracts()) throw Error('/', t._("Forbidden action"));
		
		view.title = t._("Define a vendor");
		view.text = t._("Before creating a record for the vendor you want to work with, let's search our database to check if he's not already referenced.");

		var f = new sugoi.form.Form("defVendor");
		f.addElement(new sugoi.form.elements.StringInput("name",t._("Vendor or farm name"),null,true));
		f.addElement(new sugoi.form.elements.StringInput("email",t._("Vendor email"),null,false));
		//f.addElement(new sugoi.form.elements.IntInput("zipCode",t._("zip code"),null,true));

		if(f.isValid()){
			
			//look for identical names
			var vendors = service.VendorService.findVendors( f.getValueOf('name') , f.getValueOf('email') );

			app.setTemplate('contractadmin/defineVendor.mtt');
			view.vendors = vendors;
			view.email = f.getValueOf('email');
			view.name = f.getValueOf('name');
		}
		
		view.shopMode = app.user.getGroup().hasShopMode();
		view.form = f;
	}

	/**
	  2- create vendor
	**/
	@logged @tpl("form.mtt")
	public function doInsertVendor(email:String,name:String) {
				
		var vendor = new db.Vendor();
		var form = db.Vendor.getForm(vendor);
				
		if (form.isValid()) {
			try{
				form.toSpod(vendor);			
				VendorService.create(vendor);
			}catch(e:Error){
				throw Error(Web.getURI(),e.message);
			}
			
			/*service.VendorService.getOrCreateRelatedUser(vendor);
			service.VendorService.sendEmailOnAccountCreation(vendor,app.user,app.user.getGroup());*/
			
			throw Ok('/contract/insert/'+vendor.id, t._("This supplier has been saved"));
		}else{
			form.getElement("email").value = email;
			form.getElement("name").value = name;
		}

		view.title = t._("Key-in a new vendor");
		//view.text = t._("We will send him/her an email to explain that your group is going to organize orders for him very soon");
		view.form = form;
	}

	/**
		Select CSA Variable / CSA Constant Contract
	**/
	@tpl("contract/insertChoose.mtt")
	function doInsertChoose(vendor:db.Vendor) {

		if (!app.user.canManageAllContracts()) throw Error('/', t._("Forbidden action"));
		view.vendor = vendor;
		
	}
	
	/**
	 * 4 - create the contract
	 */
	@logged @tpl("contract/insert.mtt")
	function doInsert( vendor : db.Vendor, ?type = 1 ) {

		if (!app.user.canManageAllContracts()) throw Error('/', t._("Forbidden action"));
		
		view.title = if(app.getCurrentGroup().hasShopMode()){
			t._("Create a catalog");
		}else if (type==1){
			"Créer un contrat AMAP variable";
		}else{
			"Créer un contrat AMAP classique";
		}		
		var catalog = new db.Catalog();
		catalog.type = type;
		catalog.group = app.user.getGroup();
		catalog.vendor = vendor;

		var form = catalog.getForm();
		
		if ( form.checkToken() ) {

			form.toSpod( catalog );
			
			try {

				catalog.checkFormData( form );
			
				catalog.insert();

				//Let's add the Volunteer Roles for the number of volunteers needed
				service.VolunteerService.createRoleForContract( catalog, form.getValueOf("distributorNum") );
				
				//right
				if ( catalog.contact != null ) {

					var ua = db.UserGroup.get( catalog.contact, app.user.getGroup(), true );
					ua.giveRight(ContractAdmin( catalog.id ));
					ua.giveRight(Messages);
					ua.giveRight(Membership);
					ua.update();
				}
			}
			catch ( e : Error ) {

				throw Error( '/contract/insert/' + vendor.id, e.message );
			}
			
			
			throw Ok( "/contractAdmin/view/" + catalog.id, t._("New catalog created") );
		}
		
		view.form = form;
	}


	/**
	 * Edit a contract 
	 */
	 @logged @tpl("form.mtt")
	 function doEdit( catalog : db.Catalog ) {
		 
		 view.category = 'contractadmin';
		 if (!app.user.isContractManager( catalog )) throw Error('/', t._("Forbidden action"));
 
		 view.title = t._("Edit catalog \"::contractName::\"", { contractName : catalog.name } );
 
		 var group = catalog.group;
		 var currentContact = catalog.contact;

		 var form = catalog.getForm();
		 
		 app.event( EditContract( catalog, form ) );
		 
		 if ( form.checkToken() ) {

			 form.toSpod( catalog );
			
			 try {

				catalog.checkFormData( form );
		 
				catalog.update();
				
				//update rights
				if ( catalog.contact != null && (currentContact==null || catalog.contact.id!=currentContact.id) ) {
					var ua = db.UserGroup.get( catalog.contact, catalog.group, true );
					ua.giveRight(ContractAdmin(catalog.id));
					ua.giveRight(Messages);
					ua.giveRight(Membership);
					ua.update();
					
					//remove rights to old contact
					if (currentContact != null) {
						var x = db.UserGroup.get(currentContact, catalog.group, true);
						if (x != null) {
							x.removeRight(ContractAdmin(catalog.id));
							x.update();
						}
					}
					
				}

			 }
			 catch ( e : Error ) {

				throw Error( '/contract/edit/' + catalog.id, e.message );
			}
			 
			 throw Ok( "/contractAdmin/view/" + catalog.id, t._("Catalog updated") );
		 }
		 
		 view.form = form;
	 }
	
	/**
	 * Delete a contract (... and its products, orders & distributions)
	 */
	@logged
	function doDelete(c:db.Catalog) {
		
		if (!app.user.canManageAllContracts()) throw Error("/contractAdmin", t._("Forbidden access"));
		
		if (checkToken()) {
			c.lock();
			
			//demo contracts
			var isDemoContract = c.vendor.email=="galinette@cagette.net" || c.vendor.email=="jean@cagette.net";

			//check if there is orders in this contract
			var products = c.getProducts();

			var orders = db.UserOrder.manager.search($productId in Lambda.map(products, function(p) return p.id));
			var qt = 0.0;
			for ( o in orders) qt += o.quantity; //there could be "zero c qt" orders
			if (qt > 0 && !isDemoContract) {
				throw Error("/contractAdmin", t._("You cannot delete this catalog because some orders are linked to it."));
			}
			
			//remove admin rights and delete contract	
			if(c.contact!=null){
				var ua = db.UserGroup.get(c.contact, c.group, true);
				if (ua != null) {
					ua.removeRight(ContractAdmin(c.id));
					ua.update();	
				}			
			}
			
			app.event(DeleteContract(c));
			
			c.delete();
			throw Ok("/contractAdmin", t._("Catalog deleted"));
		}
		
		throw Error("/contractAdmin", t._("Token error"));
	}
	
	/**
	 * CSA mode : Make an order by contract
	 * The form is prepopulated if orders have already been made.
	 * 
	 * It should work for constant orders ( will display one column )
	 * or varying orders ( with as many columns as distributions dates )
	 * 
	 */
	
	function doOrder( catalog : db.Catalog ) {

		if( catalog.group.hasShopMode() ) throw Redirect( '/contract/view/' + catalog.id );

		if( app.user == null ) throw Redirect( '/user/login?__redirect=/contract/order/' + catalog.id );

		if( catalog.isCSACatalog() ) {

			app.setTemplate( 'contract/orderc.mtt' );
		}
		else {

			app.setTemplate( 'contract/orderv.mtt' );
		}

		var currentOrComingSubscription = SubscriptionService.getCurrentOrComingSubscription( app.user, catalog );
		var userOrders = new Array< { distrib : db.Distribution, ordersProducts : Array< { order : db.UserOrder, product : db.Product }> } >();
		var products = catalog.getProducts();
		
		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

			var openDistributions : Array<db.Distribution> = SubscriptionService.getOpenDistribsForSubscription( app.user, catalog, currentOrComingSubscription );
	
			for ( distrib in openDistributions ) {

				var data = [];
				for ( product in products ) {

					var orderProduct = { order : null, product : product };
					var order : db.UserOrder = db.UserOrder.manager.select( $user == app.user && $productId == product.id && $distributionId == distrib.id, true );
					var useOrder = false;

					if ( !app.params.exists("token") ) {
						
						if ( order != null ) {
							
							orderProduct.order = order;
						}
					
					}
					else {

						var paramKey = 'd' + distrib.id + '-p' + product.id;
						if( app.params.exists( paramKey ) ) {

							var paramQuantity = app.params.get( paramKey );
							if ( paramQuantity != null && paramQuantity != '' ) {

								if ( order == null ) {
									
									order = new db.UserOrder();
									order.distribution = distrib;
									order.product = product;
									order.productPrice = product.price;
								}
								if ( product.hasFloatQt ) {

									order.quantity = Std.parseFloat( StringTools.replace( paramQuantity, ",", "." ) );
				
								}
								else {
				
									order.quantity = Std.parseInt( paramQuantity );
								}

								useOrder = true;

							}

						}

						if ( useOrder ) {
							
							orderProduct.order = order;
						}

					}

					data.push( orderProduct );
				}

				userOrders.push( { distrib : distrib, ordersProducts : data } );

			}
			
		}
		else {

			var data = [];
			for ( product in products ) {

				var orderProduct = { order : null, product : product };
				if ( currentOrComingSubscription != null ) {

					var subscriptionOrders = SubscriptionService.getCSARecurrentOrders( currentOrComingSubscription, null );
					var order = subscriptionOrders.find( function ( order ) return order.product.id == product.id );
					if ( order != null ) orderProduct.order = order;
				}

				data.push( orderProduct );
			}
			
			userOrders.push( { distrib : null, ordersProducts : data } );
		}

		if ( checkToken() ) {

			if ( !catalog.isUserOrderAvailable() ) throw Error( '/contract/order/' + catalog.id , t._("This catalog is not opened for orders") );
			
			//For variable catalogs
			var varOrders = []; 
			var varOrdersToEdit = [];
			var varOrdersToMake = [];
			var pricesQuantitiesByDistrib = new Map< db.Distribution, Array< { productQuantity : Float, productPrice : Float } > >();
			//For const catalogs
			var constOrders = new Array< { productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool }> (); 

			var firstDistrib = null;
			var varDefaultOrders = new Array< { productId : Int, quantity : Float, ?userId2 : Int, ?invertSharedOrder : Bool } >();

			for ( key in app.params.keys() ) {
				
				if ( key.substr(0, 1) != "d" ) continue;
				var qty = app.params.get( key );
				if ( qty == "" ) continue;
				
				var productId = null;
				var distribId = null;
				var distribution = null;
				try {

					productId = Std.parseInt( key.split("-")[1].substr(1) );
					distribId = Std.parseInt( key.split("-")[0].substr(1) );
					distribution = db.Distribution.manager.get( distribId, false );
				}
				catch ( e:Dynamic ) {

					trace( 'unable to parse key' + key );
				}
				
				var orderProduct = null;
				for ( userOrder in userOrders ) {

					if ( userOrder.distrib != null && userOrder.distrib.id != distribId ) {

						continue;
					}
					else {

						for ( x in userOrder.ordersProducts ) {

							if ( x.product.id == productId ) {

								orderProduct = x;
								break;
							}
						}
					}
				}
				
				if ( orderProduct == null ) throw t._( "Could not find the product ::product:: and delivery ::delivery::", { product : productId, delivery : distribId } );
				
				var quantity = 0.0;
				
				if ( orderProduct.product.hasFloatQt ) {

					var param = StringTools.replace( qty, ",", "." );
					quantity = Std.parseFloat( param );

				}
				else {

					quantity = Std.parseInt( qty );
				}
				
				if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

					if ( orderProduct.order != null && orderProduct.order.id != null ) {

						if ( orderProduct.order.distribution.orderEndDate.getTime() > Date.now().getTime() ) {

							varOrdersToEdit.push( { order : orderProduct.order, quantity : quantity } );
							if ( pricesQuantitiesByDistrib[orderProduct.order.distribution] == null ) {
		
								pricesQuantitiesByDistrib[orderProduct.order.distribution] = [];
							}
							pricesQuantitiesByDistrib[orderProduct.order.distribution].push( { productQuantity : quantity, productPrice : orderProduct.order.productPrice } );

						}
						
					}
					else {

						if ( distribution.orderEndDate.getTime() > Date.now().getTime() ) {

							varOrdersToMake.push( { distribId : distribId, product : orderProduct.product, quantity : quantity } );
							if ( pricesQuantitiesByDistrib[distribution] == null ) {
		
								pricesQuantitiesByDistrib[distribution] = [];
							}
							pricesQuantitiesByDistrib[distribution].push( { productQuantity : quantity, productPrice : orderProduct.product.price } );
					
						}
					}

					if ( catalog.requiresOrdering ) {

						if ( firstDistrib == null && quantity != null && quantity != 0 ) {

							firstDistrib = distribution;
						}
	
						if ( firstDistrib != null && distribution.date.getTime() < firstDistrib.date.getTime() ) {
	
							firstDistrib = distribution;
							varDefaultOrders = new Array< { productId : Int, quantity : Float, ?userId2 : Int, ?invertSharedOrder : Bool } >();
						}
	
						if( firstDistrib != null && distribution.id == firstDistrib.id ) {
	
							if ( orderProduct.order != null && orderProduct.order.id != null ) {
	
								varDefaultOrders.push( { productId : orderProduct.order.product.id, quantity : quantity } );
							}
							else {
	
								varDefaultOrders.push( { productId : orderProduct.product.id, quantity : quantity } );
							}
						}
					}

				}
				else {

					constOrders.push( { productId : orderProduct.product.id, quantity : quantity, userId2 : null, invertSharedOrder : false } );
				}

			}

			var hasRequirementsError = false;
			if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

				if( varOrdersToEdit.length == 0  && varOrdersToMake.length == 0 ) {

					throw Error( sugoi.Web.getURI(), "Merci de choisir quelle quantité de produits vous désirez" );
				}

				
				try {

					//Catalog Constraints to respect
					//We check again that the distrib is not closed to prevent automated orders and actual orders for a given distrib
					if( SubscriptionService.areVarOrdersValid( currentOrComingSubscription, pricesQuantitiesByDistrib ) ) {

						if ( currentOrComingSubscription == null ) {

							currentOrComingSubscription = SubscriptionService.createSubscription( app.user, catalog, varDefaultOrders, Std.parseInt( app.params.get( "absencesNb" ) ) );
						}
						else if ( !currentOrComingSubscription.isValidated ) {
							
							SubscriptionService.updateSubscription( currentOrComingSubscription, currentOrComingSubscription.startDate, currentOrComingSubscription.endDate, varDefaultOrders, null, Std.parseInt( app.params.get( "absencesNb" ) ) );
						}
						else if ( catalog.requiresOrdering && currentOrComingSubscription.getDefaultOrders().length == 0 ) {

							SubscriptionService.updateDefaultOrders( currentOrComingSubscription, varDefaultOrders );
						}

						for ( orderToEdit in varOrdersToEdit ) {

							varOrders.push( OrderService.edit( orderToEdit.order, orderToEdit.quantity ) );
						}

						for ( orderToMake in varOrdersToMake ) {

							varOrders.push( OrderService.make( app.user, orderToMake.quantity, orderToMake.product, orderToMake.distribId, null, currentOrComingSubscription ) );
						}

						//Create order operation only
						if ( app.user.getGroup().hasPayments() ) {

							service.PaymentService.onOrderConfirm( varOrders );
						}

					}

				}
				catch ( e : Error ) {

					if( e.data == SubscriptionServiceError.CatalogRequirementsNotMet ) {

						hasRequirementsError = true;
						App.current.session.addMessage( e.message, true );
					}
					else {

						throw Error( "/contract/order/" + catalog.id, e.message );
					}
				}

			}
			else {
				
				//Create or edit an existing subscription for the coming distribution
				if( constOrders == null || constOrders.length == 0 ){

					throw Error( sugoi.Web.getURI(), 'Merci de choisir quelle quantité de produits vous désirez' );
				}

				try {

					if ( currentOrComingSubscription == null ) {
						
						SubscriptionService.createSubscription( app.user, catalog, constOrders, Std.parseInt( app.params.get( "absencesNb" ) ) );
					}
					else if ( !currentOrComingSubscription.isValidated ) {
						
						SubscriptionService.updateSubscription( currentOrComingSubscription, currentOrComingSubscription.startDate, currentOrComingSubscription.endDate, constOrders, null, Std.parseInt( app.params.get( "absencesNb" ) ) );
					}
					
				}
				catch ( e : Error ) {

					throw Error( "/contract/order/" + catalog.id, e.message );
				}
			}

			if ( !hasRequirementsError ) {

				throw Ok( "/contract/order/" + catalog.id, "Votre souscription a bien été mise à jour");
			}

		}
		
		App.current.breadcrumb = [ { link : "/home", name : "Commandes", id : "home" }, { link : "/home", name : "Commandes", id : "home" } ]; 
		view.subscriptionService = SubscriptionService;
		view.catalog = catalog;
		view.currentOrComingSubscription = currentOrComingSubscription;
		view.newSubscriptionDistribsNb = db.Distribution.manager.count( $catalog == catalog && $date >= SubscriptionService.getNewSubscriptionStartDate( catalog ) );
		view.canOrder = if ( catalog.type == db.Catalog.TYPE_VARORDER ) { true; }
		else {

			if( currentOrComingSubscription == null || !currentOrComingSubscription.isValidated ) {
				
				catalog.isUserOrderAvailable();
			}
			else {
				
				false;
			}
		}
		view.userOrders = userOrders;
		view.absencesDistribDates = Lambda.map( SubscriptionService.getCatalogAbsencesDistribs( catalog, currentOrComingSubscription ), function( distrib ) return StringTools.replace( StringTools.replace( Formatting.dDate( distrib.date ), "Vendredi", "Ven." ), "Mercredi", "Mer." ) );
		var subscriptions = SubscriptionService.getUserCatalogSubscriptions( app.user, catalog );
		view.subscriptions = subscriptions;
		view.visibleDocuments = catalog.getVisibleDocuments( app.user );
		
	}

	
	/**
	 * Edit var orders for a multidistrib in CSA mode.
	 */
	@logged @tpl("contract/editVarOrders.mtt")
	function doEditVarOrders(distrib:db.MultiDistrib) {
		
		if ( app.user.getGroup().hasPayments() || !app.user.getGroup().hasShopMode() ) {
			//when payments are active, the user cannot modify his/her order
			throw Redirect("/");
		}
		
		// cannot edit order if date is in the past
		if (Date.now().getTime() > distrib.getDate().getTime()) {
			
			var msg = t._("This delivery has already taken place, you can no longer modify the order.");
			if (app.user.isContractManager()) msg += t._("<br/>As the manager of the catalog you can modify the order from this page: <a href='/contractAdmin'>Catalog management</a>");
			
			throw Error("/account", msg);
		}
		
		// Il faut regarder le contrat de chaque produit et verifier si le contrat est toujours ouvert à la commande.		
		/*var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

		var cids = Lambda.map(app.user.getGroup().getActiveContracts(true), function(c) return c.id);
		var distribs = db.Distribution.manager.search(($catalogId in cids) && $date >= d1 && $date <=d2 , false);
		var orders = db.UserOrder.manager.search($userId==app.user.id && $distributionId in Lambda.map(distribs,function(d)return d.id)  );*/
		var orders = distrib.getUserBasket(app.user).getOrders(Catalog.TYPE_VARORDER);
		view.orders = service.OrderService.prepare(orders);
		view.date = distrib.getDate();
		
		//form check
		if (checkToken()) {
			
			var orders_out = [];

			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var order = Lambda.find(orders, function(uo) return uo.product.id == pid);
					if (order == null) throw t._("Error, could not find the order");
					
					var q = 0.0;
					if (order.product.hasFloatQt ) {
						param = StringTools.replace(param, ",", ".");
						q = Std.parseFloat(param);
					}else {
						q = Std.parseInt(param);
					}
					
					var quantity = Math.abs( q==null?0:q );

					if ( order.distribution.canOrderNow() ) {
						//met a jour la commande
						var o = OrderService.edit(order, quantity);
						if(o!=null) orders_out.push( o );
					}					
				}
			}
			
			app.event(MakeOrder(orders_out));
				
			throw Ok("/account", t._("Your order has been updated"));
		}
	}

	/**
		the user deletes his subscription
	**/
	function doDeleteSubscription(subscription:db.Subscription){
		if( subscription.user.id!=app.user.id ) throw Error( '/', t._('Access forbidden') );
		
		var subscriptionUser = subscription.user;
	
		try {
			SubscriptionService.deleteSubscription( subscription );
		} catch( error : tink.core.Error ) {
			throw Error( '/contract/order/' + subscription.catalog.id, error.message );
		}
		throw Ok( '/contract/order/' + subscription.catalog.id, 'La souscription a bien été supprimée.' );
		
	}
}
