package controller;
import sugoi.Web;
import tink.core.Error;
import service.VendorService;
import tools.DateTool;
import service.SubscriptionService;
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
		view.hasUserValidatedSubscription = app.user==null ? false : service.SubscriptionService.hasUserValidatedSubscription( app.user, catalog );
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
		3 - Select VARIABLE ORDER / CSA Contract
	**/
	//@tpl("contract/insertChoose.mtt")
	function doInsertChoose(vendor:db.Vendor) {
		throw Redirect("/contract/insert/"+vendor.id);
	}
	
	/**
	 * 4 - create the contract
	 */
	@logged @tpl("contract/insert.mtt")
	function doInsert(vendor:db.Vendor) {
		if (!app.user.canManageAllContracts()) throw Error('/', t._("Forbidden action"));
		
		view.title = t._("Create a catalog");
		
		var catalog = new db.Catalog();

		var customMap = new FieldTypeToElementMap();
		customMap["DDate"] = CagetteForm.renderDDate;
		customMap["DTimeStamp"] = CagetteForm.renderDDate;
		customMap["DDateTime"] = CagetteForm.renderDDate;

		var form = form.CagetteForm.fromSpod( catalog, customMap );
		if ( app.user.getGroup().hasShopMode() ) {

			form.removeElement(form.getElement("orderPreparationHours"));
			form.removeElement(form.getElement("requiresOrdering"));
			form.removeElement(form.getElement("distribMinOrdersTotal"));
			form.removeElement(form.getElement("catalogMinOrdersTotal"));
			form.removeElement(form.getElement("allowedOverspend"));
			form.removeElement(form.getElement("absentDistribsMaxNb"));
			form.removeElement(form.getElement("absencesStartDate"));
			form.removeElement(form.getElement("absencesEndDate"));
			
		}
		else {

			if ( catalog.type == Catalog.TYPE_CONSTORDERS ) {

				form.removeElement(form.getElement("requiresOrdering"));
				form.removeElement(form.getElement("distribMinOrdersTotal"));
				form.removeElement(form.getElement("catalogMinOrdersTotal"));
				form.removeElement(form.getElement("allowedOverspend"));
				
			}

			var catalogTypes = [ { label : 'Contrat AMAP classique', value : 0 }, { label : 'Contrat AMAP variable', value : 1 } ];
			form.addElement( new sugoi.form.elements.IntSelect( 'catalogtype', 'Type de catalogue', catalogTypes, null, true ), 0 );
		}
		form.removeElement(form.getElement("groupId") );
		form.removeElement(form.getElement("type"));
		form.getElement("name").value = "Commande "+vendor.name;
		form.getElement("userId").required = true;
		form.getElement("startDate").value = Date.now();
		form.getElement("endDate").value = DateTools.delta(Date.now(),365.25*24*60*60*1000);
		form.removeElement(form.getElement("vendorId"));
		form.addElement(new sugoi.form.elements.Html("vendorHtml",'<b>${vendor.name}</b> (${vendor.zipCode} ${vendor.city})', t._("Vendor")));
		
		if ( form.checkToken() ) {

			form.toSpod( catalog );
			catalog.group = app.user.getGroup();
			if( !app.user.getGroup().hasShopMode() ) {

				catalog.type = form.getValueOf("catalogtype");
				//catalog.requiresOrdering = form.getValueOf( "requiresordering" );
				// catalog.type = form.getValueOf("csa")==true ? db.Catalog.TYPE_CONSTORDERS : db.Catalog.TYPE_VARORDER;
			}
			else {

				catalog.type = Catalog.TYPE_VARORDER;
			}
			
			catalog.vendor = vendor;
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
 
		 view.title = t._("Edit catalog \"::catalogName::\"", { catalogName : catalog.name } );
 
		 var group = catalog.group;
		 var currentContact = catalog.contact;
		 
		 var customMap = new FieldTypeToElementMap();
		 customMap["DDate"] = CagetteForm.renderDDate;
		 customMap["DTimeStamp"] = CagetteForm.renderDDate;
		 customMap["DDateTime"] = CagetteForm.renderDDate;
 
		 var form = form.CagetteForm.fromSpod( catalog, customMap );
		 //form.removeElement( form.getElement("groupId") );
		 form.removeElement(form.getElement("type"));
		 form.removeElement(form.getElement("distributorNum"));
		 form.getElement("userId").required = true;

		 if ( app.user.getGroup().hasShopMode() ) {

			form.removeElement(form.getElement("orderPreparationHours"));
			form.removeElement(form.getElement("requiresOrdering"));
			form.removeElement(form.getElement("distribMinOrdersTotal"));
			form.removeElement(form.getElement("catalogMinOrdersTotal"));
			form.removeElement(form.getElement("allowedOverspend"));
			form.removeElement(form.getElement("absentDistribsMaxNb"));
			form.removeElement(form.getElement("absencesStartDate"));
			form.removeElement(form.getElement("absencesEndDate"));
			
		}
		else {

			if ( catalog.type == Catalog.TYPE_CONSTORDERS ) {

				form.removeElement(form.getElement("requiresOrdering"));
				form.removeElement(form.getElement("distribMinOrdersTotal"));
				form.removeElement(form.getElement("catalogMinOrdersTotal"));
				form.removeElement(form.getElement("allowedOverspend"));
				
			}

		}
 
		 app.event( EditContract( catalog, form ) );
		 
		 if ( form.checkToken() ) {
			 form.toSpod( catalog );
			 catalog.group = group;
			 
			 //checks & warnings
			 if ( catalog.hasPercentageOnOrders() && catalog.percentageValue==null ) {

				 throw Error( "/contract/edit/" + catalog.id, t._("If you would like to add fees to the order, define a rate (%) and a label.") );
			 }
			 
			 if (catalog.hasStockManagement()) {
				 for (p in catalog.getProducts()) {
					 if (p.stock == null) {
						 app.session.addMessage(t._("Warning about management of stock. Please fill the field \"stock\" for all your products"), true);
						 break;
					 }
				 }
			 }
 
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

		if(catalog.group.hasShopMode()) throw Redirect("/contract/view/"+catalog.id);

		//if user is not logged, need to log-in
		if(app.user==null) throw Redirect('/user/login?__redirect=/contract/order/'+catalog.id);

		if(catalog.isCSACatalog()){
			app.setTemplate("contract/orderc.mtt");
		}else{
			app.setTemplate("contract/orderv.mtt");
		}

		view.visibleDocuments = catalog.getVisibleDocuments( app.user );
		var subscriptions = SubscriptionService.getUserCatalogSubscriptions(app.user,catalog);
		var isUserOrderAvailable = catalog.isUserOrderAvailable();
		var unvalidatedSubscription = subscriptions.find(s -> return !s.isValidated);
		view.subscriptions = subscriptions;		
		view.subscriptionService = SubscriptionService;
		view.unvalidatedSubscription = unvalidatedSubscription;
		view.isUserOrderAvailable = isUserOrderAvailable;		
		view.catalog = catalog;
		view.isCSACatalog = catalog.type == db.Catalog.TYPE_CONSTORDERS;
		view.absentDistribsMaxNb = catalog.absentDistribsMaxNb;
		var subscription = service.SubscriptionService.getUserSubscription( app.user, catalog );
		view.absencesDistribDates = Lambda.array( Lambda.map( SubscriptionService.getCatalogAbsencesDistribsForSubscription( catalog, subscription ), function( distrib ) return Formatting.dDate( distrib.date ) ) );

		view.canOrder = if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
			true;
		}else{
			if(subscriptions.length==0){
				//has no sub
				isUserOrderAvailable;
			}else{
				if(unvalidatedSubscription!=null){
					//has an unvalidated sub
					isUserOrderAvailable;
				}else{
					//has subs, but all are validated
					false;
				}
			}
		}
		

		var distributions = [];
		// If its a varying contract, we display a column by distribution
		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
			distributions = db.Distribution.getOpenDistribs( catalog, subscription );
		}else{
			distributions = [null];
		}
		
		//list of distribs with a list of product and optionnaly an order
		var userOrders = new Array< { distrib : db.Distribution, data : Array< { order : db.UserOrder, product : db.Product }> } >();
		var products = catalog.getProducts();

		if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
			//variable catalog
			for ( d in distributions){
				var data = [];
				for ( p in products) {
					var ua = { order:null, product:p };
					var order = db.UserOrder.manager.select($user == app.user && $productId == p.id && $distributionId==d.id, true);						
					if (order != null) ua.order = order;
					data.push(ua);
				}				
				userOrders.push( { distrib : d, data : data } );
			}
			
		} else {
			//CSA catalog
			var data = [];
			//search for an unvalidated sub
			
			for ( product in products) {

				var orderProduct = { order : null, product : product };
				//var order = db.UserOrder.manager.select( $user == app.user && $productId == product.id, true );
				if ( subscription != null ) {
					var subscriptionOrders = service.SubscriptionService.getSubscriptionOrders( subscription );
					var order = subscriptionOrders.find( function ( order ) return order.product.id == product.id );
					if ( order != null ) orderProduct.order = order;
				}

				data.push( orderProduct );
			}
			
			userOrders.push( { distrib : null, data : data } );
		}


		//TODO

		
		//form check
		if ( checkToken() ) {
			
			if ( !catalog.isUserOrderAvailable() ) throw Error( "/contract/order/"+catalog.id , t._("This catalog is not opened for orders") );
			
			//variable
			var varOrders = []; 
			var varOrdersToEdit = [];
			var varOrdersToMake = [];
			var pricesQuantitiesByDistrib = new Map< db.Distribution, Array< { productQuantity : Float, productPrice : Float } > >();
			//CSA orders
			var constOrders = new Array< { productId : Int, quantity : Float, userId2 : Int, invertSharedOrder : Bool }> (); 

			for ( k in app.params.keys() ) {
				
				if ( k.substr(0, 1) != "d" ) continue;
				var qt = app.params.get( k );
				if ( qt == "" ) continue;
				
				var productId = null;
				var distribId = null;
				var distribution = null;
				try {

					productId = Std.parseInt(k.split("-")[1].substr(1));
					distribId = Std.parseInt(k.split("-")[0].substr(1));
					distribution = db.Distribution.manager.get( distribId, false );
				}
				catch ( e:Dynamic ) {

					trace("unable to parse key "+k);
				}
				
				//find related element in userOrders
				var uo = null;
				for ( x in userOrders ) {
					if (x.distrib!=null && x.distrib.id != distribId) {						
						continue;
					} else {
						for ( a in x.data ){
							if (a.product.id == productId){
								uo = a;
								break;
							}
						}
					}
				}
				
				if (uo == null) throw t._("Could not find the product ::product:: and delivery ::delivery::", { product : productId, delivery : distribId });
				
				var quantity = 0.0;
				
				if ( uo.product.hasFloatQt ) {
					var param = StringTools.replace(qt, ",", ".");
					quantity = Std.parseFloat(param);
				}else {
					quantity = Std.parseInt(qt);
				}
				
				if ( catalog.type == db.Catalog.TYPE_VARORDER ) {
				
					if ( uo.order != null ) {

						// varOrders.push( OrderService.edit(uo.order, quantity));
						varOrdersToEdit.push( { order : uo.order, quantity : quantity });
						if ( pricesQuantitiesByDistrib[uo.order.distribution] == null ) {
	
							pricesQuantitiesByDistrib[uo.order.distribution] = [];
						}
						pricesQuantitiesByDistrib[uo.order.distribution].push( { productQuantity : quantity, productPrice : uo.order.productPrice } );
					}
					else {

						// varOrders.push( OrderService.make(app.user, quantity, uo.product, distribId));
						varOrdersToMake.push( { distribId : distribId, product : uo.product, quantity : quantity } );
						if ( pricesQuantitiesByDistrib[distribution] == null ) {
	
							pricesQuantitiesByDistrib[distribution] = [];
						}
						pricesQuantitiesByDistrib[distribution].push( { productQuantity : quantity, productPrice : uo.product.price } );
					}
				} else {
					constOrders.push( { productId : uo.product.id, quantity : quantity, userId2 : null, invertSharedOrder : false } );
				}

			}

			
			if ( catalog.type == db.Catalog.TYPE_CONSTORDERS ) {
				
				//create or edit subscription
				if(constOrders==null || constOrders.length==0){
					throw Error(sugoi.Web.getURI(),"Merci de choisir quelle quantité de produits vous désirez");
				}

				try {

					var pendingSubscription = service.SubscriptionService.getUserSubscription( app.user, catalog, false );
					if ( pendingSubscription != null ) {

						service.SubscriptionService.updateSubscription( pendingSubscription, pendingSubscription.startDate, pendingSubscription.endDate, constOrders,
						[Std.parseInt(app.params.get( "absence0" )), Std.parseInt(app.params.get( "absence1" )), Std.parseInt(app.params.get( "absence2" )), Std.parseInt(app.params.get( "absence3" )) ] );

					}
					else {
						
						service.SubscriptionService.createSubscription( app.user, catalog, constOrders, Std.parseInt( app.params.get( "absences" ) ) );
					}
				}
				catch ( e : Dynamic ) {

					throw Error( "/contract/order/" + catalog.id, e.message );
				}
			}
			else {

				if( varOrdersToEdit.length == 0  && varOrdersToMake.length == 0 )	{

					throw Error( sugoi.Web.getURI(), "Merci de choisir quelle quantité de produits vous désirez" );
				}

				var allOrdersAreValid = true;
				try {

					for ( distrib in pricesQuantitiesByDistrib.keys() ) {

						if ( !service.SubscriptionService.areDistribVarOrdersValid( subscription, distrib, pricesQuantitiesByDistrib[ distrib ] ) ) {
	
							allOrdersAreValid = false; 
							break;
						}
					}

				}
				catch ( e : Dynamic ) {

					throw Error( "/contract/order/" + catalog.id, e.message );
				}

				if( allOrdersAreValid ) {

					for ( orderToEdit in varOrdersToEdit ) {

						varOrders.push( OrderService.edit( orderToEdit.order, orderToEdit.quantity ) );
					}

					for ( orderToMake in varOrdersToMake ) {

						varOrders.push( OrderService.make( app.user, orderToMake.quantity, orderToMake.product, orderToMake.distribId, null, subscription ) );
					}

					//Create order operation only
					if ( app.user.getGroup().hasPayments() ) {

						service.PaymentService.onOrderConfirm( varOrders );
					}

				}

			}

			throw Ok( "/contract/order/" + catalog.id, t._("Your order has been updated") );

		}
		
		view.userOrders = userOrders;
		
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
}
