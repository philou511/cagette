package controller;
import sys.db.Types.SSerialized;
import Common;
import db.Catalog;
import db.MultiDistrib;
import db.UserOrder;
import db.VolunteerRole;
import form.CagetteDatePicker;
import form.CagetteForm;
import haxe.display.Display.GotoDefinitionResult;
import plugin.Tutorial;
import service.CatalogService;
import service.OrderService;
import service.SubscriptionService;
import service.VendorService;
import sugoi.Web;
import sugoi.form.Form;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.Input;
import sugoi.form.elements.IntInput;
import sugoi.form.elements.Selectbox;
import tink.core.Error;
import tools.DateTool;

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

			if(f.getValueOf('name')==null && (f.getElement("geoloc")==null || f.getValueOf("geoloc")==false) && f.getValueOf("profession")==null){
				throw Error('/contract/defineVendor/','Vous devez au moins rechercher par nom ou par profession');
			}
			
			//look for identical names
			var vendors = service.VendorService.findVendors( {
				name:f.getValueOf('name'),
				email:null/*f.getValueOf('email')*/,
				geoloc : f.getElement("geoloc")==null ? false : f.getValueOf("geoloc"),
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
	  2- invite a vendor

	  a Vendor can be specified if we invite a invited vendor to open a discovery vendor
	**/
	@logged @tpl("contractadmin/inviteVendor.mtt")
	public function doInviteVendor(?vendor:db.Vendor) {
		view.groupId = app.user.getGroup().id;
		if(vendor!=null) view.vendor = vendor;
	}

	/**
	  2- create vendor
	**/
	@logged @tpl("form.mtt")
	public function doInsertVendor(?name:String) {
		if(app.user.getGroup().hasShopMode()) throw Error("/", t._("Access forbidden"));

		var form = VendorService.getForm(new db.Vendor());
				
		if (form.isValid()) {
			var vendor = null;
			try{
				vendor = VendorService.create(form.getDatasAsObject());
			}catch(e:Error){
				throw Error(Web.getURI(),e.message);
			}
			
			throw Ok('/contract/insert/'+vendor.id, t._("This supplier has been saved"));
		}else{
			form.getElement("name").value = name;
		}

		view.title = t._("Key-in a new vendor");
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
	 @tpl("contract/order.mtt")
	function doOrder( catalog : db.Catalog ) {
		view.catalog = catalog;
		view.userId = app.user.id;

		var sub = SubscriptionService.getCurrentOrComingSubscription(app.user,catalog);
		view.subscriptionId = sub==null ? null : sub.id;
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
