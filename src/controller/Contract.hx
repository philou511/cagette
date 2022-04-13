package controller;
import Common;
import db.Catalog;
import db.MultiDistrib;
import db.UserOrder;
import db.VolunteerRole;
import form.CagetteDatePicker;
import form.CagetteForm;
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
			} catch ( e : Error ) {
				throw Error( '/contract/insert/' + vendor.id, e.message );
			}
			
			
			throw Ok( "/contractAdmin/view/" + catalog.id, t._("New catalog created") );
		}
		
		view.form = form;
	}
}