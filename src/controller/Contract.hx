package controller;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.IntInput;
import haxe.display.Display.GotoDefinitionResult;
import form.CagetteDatePicker;
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
import service.CatalogService;

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
		throw Redirect("/history");
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
		
		view.title = "Chercher un producteur";
		// view.text = t._("Before creating a record for the vendor you want to work with, let's search our database to check if he's not already referenced.");

		var f = new sugoi.form.Form("defVendor");
		f.addElement(new sugoi.form.elements.StringInput("name",t._("Vendor or farm name"),null,false));
		// f.addElement(new sugoi.form.elements.StringInput("email","Email du producteur",null,false));
		var place = app.getCurrentGroup().getMainPlace();
		if(place!=null){
			f.addElement(new sugoi.form.elements.Checkbox('geoloc','A proximité de "${place.name}" ',true,false));
		}

		//profession
		f.addElement(new sugoi.form.elements.IntSelect('profession',t._("Profession"),sugoi.form.ListData.fromSpod(service.VendorService.getVendorProfessions()),null,false));

		if(f.isValid()){
			
			//look for identical names
			var vendors = service.VendorService.findVendors( {
				name:f.getValueOf('name'),
				email:null/*f.getValueOf('email')*/,
				geoloc : f.getValueOf("geoloc"),
				profession:f.getValueOf("profession"),
				fromLng: if(place!=null) place.lng else null, 
				fromLat: if(place!=null) place.lat else null,
				
			});

			app.setTemplate('contractadmin/defineVendor.mtt');
			view.vendors = vendors;
			// view.email = f.getValueOf('email');
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
				
		var form = VendorService.getForm(new db.Vendor());
				
		if (form.isValid()) {
			var vendor = null;
			try{
				vendor = VendorService.create(form.getDatasAsObject());
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

		var form = CatalogService.getForm(catalog);
		
		if ( form.checkToken() ) {

			form.toSpod( catalog );
			
			try {

				CatalogService.checkFormData(catalog,form);
			
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
	 * Edit a contract/catalog
	 */
	 @logged @tpl("form.mtt")
	 function doEdit( catalog : db.Catalog ) {
		 
		view.category = 'contractadmin';
		if (!app.user.isContractManager( catalog )) throw Error('/', t._("Forbidden action"));

		view.title = t._("Edit catalog \"::contractName::\"", { contractName : catalog.name } );

		var group = catalog.group;
		var currentContact = catalog.contact;
		var previousOrderStartDays = catalog.orderStartDaysBeforeDistrib;
		var previousOrderEndHours = catalog.orderEndHoursBeforeDistrib;
		var messages = new Array<String>() ;

		var form = CatalogService.getForm(catalog);
		
		app.event( EditContract( catalog, form ) );
		
		if ( form.checkToken() ) {

			form.toSpod( catalog );
		
			try {

				CatalogService.checkFormData(catalog,  form );
				catalog.update();

				if(!catalog.group.hasShopMode()){
					
					//Update future distribs start and end orders dates
					var newOrderStartDays = catalog.orderStartDaysBeforeDistrib != previousOrderStartDays ? catalog.orderStartDaysBeforeDistrib : null;
					var newOrderEndHours = catalog.orderEndHoursBeforeDistrib != previousOrderEndHours ? catalog.orderEndHoursBeforeDistrib : null;
					var msg = CatalogService.updateFutureDistribsStartEndOrdersDates( catalog, newOrderStartDays, newOrderEndHours );
					if(msg!=null) messages.push ( msg );  

					//payements : update or create operations
					for ( sub in SubscriptionService.getCatalogSubscriptions(catalog)){
						SubscriptionService.createOrUpdateTotalOperation( sub );
					}

				}
				
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

			} catch ( e : Error ) {
				throw Error( '/contract/edit/' + catalog.id, e.message );
			}
			
			
			var text = "Catalogue mis à jour.";
			if(messages.length > 0){
				text += "<br/>" + messages.join(". ");
				// throw messages;
			} 
			throw Ok( "/contractAdmin/view/" + catalog.id,  text );
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
	 */
	
	function doOrder( catalog : db.Catalog ) {

		if( catalog.group.hasShopMode() ) throw Redirect( '/contract/view/' + catalog.id );
		if( app.user == null ) throw Redirect( '/user/login?__redirect=/contract/order/' + catalog.id );

		if( catalog.isConstantOrders() ) {
			app.setTemplate( 'contract/orderc.mtt' );
		} else {
			app.setTemplate( 'contract/orderv.mtt' );
		}

		var subscriptionService = new SubscriptionService();
		var currentOrComingSubscription = SubscriptionService.getCurrentOrComingSubscription( app.user, catalog );
		var userOrders = new Array<{distrib:db.Distribution, ordersProducts:Array<{order:db.UserOrder, product:db.Product }>, ?isAbsence:Bool}>();
		var products = catalog.getProducts();
		
		var hasComingOpenDistrib = false;

		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

			view.shortDate = Formatting.csaShortDate;
			view.closingDate  = Formatting.csaClosingDate;
			view.json = function(d) return haxe.Json.stringify(d);
			view.multiWeightQuantity  = function( order : db.UserOrder ) {
				return db.UserOrder.manager.count( $subscription == order.subscription && $distribution == order.distribution && $product == order.product && $quantity > 0 );
			}

			// var openDistributions = SubscriptionService.getOpenDistribsForSubscription( app.user, catalog, currentOrComingSubscription );
			// hasComingOpenDistrib = openDistributions.length != 0;

			var distribs = catalog.getDistribs(true);
			// hasComingOpenDistrib = distribs.find(d -> d.orderStartDate.getTime() < Date.now().getTime())!=null;
	
			for ( distrib in distribs ) {

				var data = [];
				for ( product in products ) {

					var orderProduct = { order : null, product : product };
					var order = db.UserOrder.manager.select( $user == app.user && $productId == product.id && $distributionId == distrib.id, true );
					var useOrder = false;

					if ( !app.params.exists("token") ) {
						
						if ( order != null ) {							
							orderProduct.order = order;
						}
					
					} else {

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
								
								order.quantity = Std.parseInt( paramQuantity );
								useOrder = true;
							}
						}
						if ( useOrder ) {							
							orderProduct.order = order;
						}
					}
					data.push( orderProduct );
				}

				userOrders.push( { 
					distrib:distrib,
					ordersProducts:data,
					isAbsence: currentOrComingSubscription==null? false : currentOrComingSubscription.getAbsentDistribIds().has(distrib.id) 
				} );
			}
			
		} else {
			//CSA contracts
			hasComingOpenDistrib = SubscriptionService.getComingOpenDistrib( catalog ) != null;

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
			var pricesQuantitiesByDistrib = new Map< db.Distribution, Array< { productQuantity:Float, productPrice:Float }>>();
			//For const catalogs
			var constOrders = new Array<{ productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool }> (); 

			var firstDistrib = null;
			var varDefaultOrders = new Array<{ productId : Int, quantity : Float, ?userId2 : Int, ?invertSharedOrder : Bool } >();

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
					} else {
						for ( x in userOrder.ordersProducts ) {
							if ( x.product.id == productId ) {
								orderProduct = x;
								break;
							}
						}
					}
				}
				
				if ( orderProduct == null ) throw t._( "Could not find the product ::product:: and delivery ::delivery::", { product : productId, delivery : distribId } );
				
				var quantity = Std.parseInt( qty );				
				
				
				if ( catalog.type == db.Catalog.TYPE_VARORDER ) {

					if ( orderProduct.order != null && orderProduct.order.id != null ) {

						if ( orderProduct.order.distribution.orderEndDate.getTime() > Date.now().getTime() ) {

							varOrdersToEdit.push( { order : orderProduct.order, quantity : quantity } );
							if ( pricesQuantitiesByDistrib[orderProduct.order.distribution] == null ) {
		
								pricesQuantitiesByDistrib[orderProduct.order.distribution] = [];
							}
							pricesQuantitiesByDistrib[orderProduct.order.distribution].push( { productQuantity : quantity, productPrice : orderProduct.order.productPrice } );
						}
					} else {

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
							varDefaultOrders = new Array< { productId:Int, quantity:Float, ?userId2:Int, ?invertSharedOrder:Bool } >();
						}
	
						if( firstDistrib != null && distribution.id == firstDistrib.id ) {
							if ( orderProduct.order != null && orderProduct.order.id != null ) {
								varDefaultOrders.push( { productId : orderProduct.order.product.id, quantity : quantity } );
							} else {
								varDefaultOrders.push( { productId : orderProduct.product.id, quantity : quantity } );
							}
						}
					}

				} else {
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

						var subscriptionIsNew = false;

						if ( currentOrComingSubscription == null ) {
							subscriptionIsNew = true;
							currentOrComingSubscription = subscriptionService.createSubscription( app.user, catalog, varDefaultOrders, app.params.get("absencesNb").parseInt() );
						} else {							
							subscriptionService.updateSubscription( currentOrComingSubscription, currentOrComingSubscription.startDate, currentOrComingSubscription.endDate, varDefaultOrders/*, null, app.params.get("absencesNb").parseInt()*/ );
							if ( catalog.requiresOrdering && currentOrComingSubscription.getDefaultOrders().length == 0 ) {
								SubscriptionService.updateDefaultOrders( currentOrComingSubscription, varDefaultOrders );
							}
						}
						
						var newSubscriptionAbsentDistribs = [];
						if( subscriptionIsNew ) {
							newSubscriptionAbsentDistribs = currentOrComingSubscription.getAbsentDistribs();
						}

						for ( orderToEdit in varOrdersToEdit ) {
							if( newSubscriptionAbsentDistribs.length == 0 || newSubscriptionAbsentDistribs.find( d -> d.id == orderToEdit.order.distribution.id ) == null ) {			
								if( !orderToEdit.order.product.multiWeight ) {
									varOrders.push( OrderService.edit( orderToEdit.order, orderToEdit.quantity ) );
								} else {
									varOrders.push( OrderService.editMultiWeight( orderToEdit.order, orderToEdit.quantity ) );
								}
							}
						}

						for ( orderToMake in varOrdersToMake ) {
							if( newSubscriptionAbsentDistribs.length == 0 || newSubscriptionAbsentDistribs.find( d -> d.id == orderToMake.distribId ) == null ) {
								varOrders.push( OrderService.make( app.user, orderToMake.quantity, orderToMake.product, orderToMake.distribId, null, currentOrComingSubscription ) );
							}
						}
					}
				} catch ( e : Error ) {
					if( e.data == SubscriptionServiceError.CatalogRequirementsNotMet ) {
						hasRequirementsError = true;
						App.current.session.addMessage( e.message, true );
					} else { 
						throw Error( "/contract/order/" + catalog.id, e.message );
					}
				}

			} else {
				
				//Create or edit an existing subscription for the coming distribution
				if( constOrders == null || constOrders.length == 0 ){
					throw Error( sugoi.Web.getURI(), 'Merci de choisir quelle quantité de produits vous désirez' );
				}

				try {
					if ( currentOrComingSubscription == null ) {						
						currentOrComingSubscription = subscriptionService.createSubscription( app.user, catalog, constOrders, app.params.get("absencesNb").parseInt() );
					} else if ( !currentOrComingSubscription.paid() ) {						
						subscriptionService.updateSubscription( currentOrComingSubscription, currentOrComingSubscription.startDate, currentOrComingSubscription.endDate, constOrders/*, null, app.params.get("absencesNb").parseInt()*/ );
					}
				} catch ( e : Error ) {
					throw Error( "/contract/order/" + catalog.id, e.message );
				}
			}

			//Create or update a single order operation for the subscription total orders price
			if ( currentOrComingSubscription != null && catalog.hasPayments ) {
				service.SubscriptionService.createOrUpdateTotalOperation( currentOrComingSubscription );
			}

			if ( !hasRequirementsError ) {
				var msg = "Votre souscription a bien été mise à jour.";
				//message if no payments has been made and there is a catalogMinOrdersTotal
				if(catalog.hasPayments && catalog.catalogMinOrdersTotal > 0){
					if(currentOrComingSubscription.getPaymentsTotal()==0){
						msg += " <b>Pensez à payer votre provision initiale de "+SubscriptionService.getCatalogMinOrdersTotal(catalog,currentOrComingSubscription)+"€</b>";
					}					
				}
				throw Ok( "/contract/order/" + catalog.id, msg );
			}

		}
		
		App.current.breadcrumb = [ { link : "/home", name : "Commandes", id : "home" } ]; 
		view.subscriptionService = SubscriptionService;
		view.catalog = catalog;

		//small balance warning
		/*if ( currentOrComingSubscription != null && catalog.type == db.Catalog.TYPE_VARORDER && catalog.hasPayments ) {
			var balance = currentOrComingSubscription.getBalance();
			var remainingDistribsNb = SubscriptionService.getSubscriptionRemainingDistribsNb( currentOrComingSubscription );
			var averageSpentPerDistrib = SubscriptionService.getDistribOrdersAverageTotal( currentOrComingSubscription );
			if( averageSpentPerDistrib != 0 && remainingDistribsNb != 0 ) {
				var remainingDistribsToZero = Math.floor( balance / averageSpentPerDistrib );
					// si j'ai de la réserve pour moins de 4 distribs,
					// et que ce que j'ai en réserve fait moins que les distribs qu'ils reste à faire
					// et que la souscription a plus de 4 distribs.
				if( remainingDistribsToZero < 4  && remainingDistribsToZero < remainingDistribsNb && SubscriptionService.getSubscriptionDistribsNb( currentOrComingSubscription )>4 ) {
					view.smallBalance = balance < ( remainingDistribsNb * averageSpentPerDistrib ) ? balance : null;
				}
			}
		}*/

		view.currentOrComingSubscription = currentOrComingSubscription;
		view.hasComingOpenDistrib = hasComingOpenDistrib;
		view.catalogDistribsNb = db.Distribution.manager.count( $catalog == catalog );
		view.newSubscriptionDistribsNb = db.Distribution.manager.count( $catalog == catalog && $date >= SubscriptionService.getNewSubscriptionStartDate( catalog ) );
		view.canOrder = if( currentOrComingSubscription == null || !currentOrComingSubscription.paid() ) {
			catalog.isUserOrderAvailable();
		} else {
			false;
		};
		view.userOrders = userOrders;
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
					
					var q = Std.parseInt(param);					
					
					var quantity = Math.abs( q==null?0:q );

					if ( order.distribution.canOrderNow() ) {
						//met a jour la commande
						var o = OrderService.edit(order, quantity);
						if(o!=null) orders_out.push( o );
					}					
				}
			}
			
			app.event(MakeOrder(orders_out));
				
			throw Ok("/history", t._("Your order has been updated"));
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

	/**
		the catalog admin updates absences options
	**/
	@tpl("contractadmin/form.mtt")
	function doAbsences(catalog:db.Catalog){
		view.category = 'contractadmin';
		view.nav.push("absences");
		if (!app.user.isContractManager( catalog )) throw Error('/', t._("Forbidden action"));

		view.title = 'Période d\'absences du contrat \"${catalog.name}\"';

		var form = new sugoi.form.Form("absences");
	
		var html = "<div class='alert alert-warning'><p><i class='icon icon-info'></i> 
		Vous pouvez définir une période pendant laquelle les membres pourront choisir d'être absent.<br/>
		Saisissez la période d'absence uniquement après avoir défini votre planning de distribution définitif sur toute la durée du contrat.<br/>
		<a href='https://wiki.cagette.net/admin:absences' target='_blank'>Consulter la documentation.</a>
		</p></div>";
		
		form.addElement( new sugoi.form.elements.Html( 'absences', html, '' ) );
		form.addElement(new IntInput("absentDistribsMaxNb","Nombre maximum d'absences autorisées",catalog.absentDistribsMaxNb,true));
		var start = catalog.absencesStartDate==null ? catalog.startDate : catalog.absencesStartDate;
		var end = catalog.absencesEndDate==null ? catalog.endDate : catalog.absencesEndDate;
		form.addElement(new CagetteDatePicker("absencesStartDate","Début de la période d'absence",start));
		form.addElement(new CagetteDatePicker("absencesEndDate","Fin de la période d'absence",end));
		
		if ( form.checkToken() ) {
			catalog.lock();
			form.toSpod( catalog );
			var absencesStartDate : Date = form.getValueOf('absencesStartDate');
			var absencesEndDate : Date = form.getValueOf('absencesEndDate');
			catalog.absencesStartDate = new Date( absencesStartDate.getFullYear(), absencesStartDate.getMonth(), absencesStartDate.getDate(), 0, 0, 0 );
			catalog.absencesEndDate = new Date( absencesEndDate.getFullYear(), absencesEndDate.getMonth(), absencesEndDate.getDate(), 23, 59, 59 );
			catalog.update();
		
			try{
				
				CatalogService.checkAbsences(catalog);

			} catch ( e : Error ) {
				throw Error( '/contract/absences/'+catalog.id, e.message );
			}
			
			throw Ok( "/contractAdmin/view/" + catalog.id,  "Catalogue mis à jour." );
		}
		 
		view.form = form;
		view.c = catalog;
		
	}
}
