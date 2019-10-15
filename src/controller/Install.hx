package controller;
import sugoi.db.Variable;
import sugoi.form.elements.StringInput;
//import thx.semver.Version;
import service.VolunteerService;
import Common;

/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Install extends controller.Controller
{
	/**
	 * checks if its a first install or an update
	 */
	@tpl("install/default.mtt")
	public function doDefault() {
		if (db.User.manager.get(1) == null) {
						
			throw Redirect("/install/firstInstall");
			
		}else {
			//throw Error("/", "L'utilisateur admin a déjà été créé. Essayez de vous connecter avec admin@cagette.net, mot de passe : admin");
			
			var status = new Array<{parameter:String,valid:Bool,message:String}>(); 
			
			status.push(getVersionStatus());
			
			view.status = status;
		}
	}

	public function doDiagnostics(){

		var webroot = sugoi.Web.getCwd();

		if(!sys.FileSystem.exists(webroot+"file")){
			Sys.println("no File directory : created");
			sys.FileSystem.createDirectory(webroot+"file");
		} 
		if(!sys.FileSystem.exists(webroot+"file/.htaccess")){
			Sys.println("no .htaccess file in 'File' directory");
		} 
		if(!sys.FileSystem.exists(webroot+"../tmp")) {
			Sys.println("no tmp directory : created");
			sys.FileSystem.createDirectory(webroot+"../tmp");
		}

	}
	
	/**
	 * First install 
	 */
	@tpl("form.mtt")
	public function doFirstInstall(){
		view.title = "Installation de Cagette.net";

			var f = new sugoi.form.Form("c");
			f.addElement(new StringInput("amapName", t._("Name of your group"),"",true));
			f.addElement(new StringInput("userFirstName", t._("Your firstname"),"",true));
			f.addElement(new StringInput("userLastName", t._("Your lastname"),"",true));

			if (f.checkToken()) {
	
				var user = new db.User();
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				user.email = "admin@cagette.net";
				user.setPass("admin");
				user.insert();
			
				var amap = new db.Amap();
				amap.name = f.getValueOf("amapName");
				amap.contact = user;

				amap.flags.set(db.Amap.AmapFlags.HasMembership);
				//amap.flags.set(db.Amap.AmapFlags.IsAmap);
				amap.insert();
				
				var ua = new db.UserAmap();
				ua.user = user;
				ua.amap = amap;
				ua.rights = [Right.GroupAdmin,Right.Membership,Right.Messages,Right.ContractAdmin(null)];
				ua.insert();
				
				//example datas
				var place = new db.Place();
				place.name = t._("Marketplace");
				place.amap = amap;
				place.address1 = t._("Place Jules Verne");
				place.zipCode = "00000";
				place.city = t._("St Martin de la Cagette");
				place.insert();
				
				var vendor = new db.Vendor();
				vendor.name = t._("Jean Martin EURL");
				vendor.email = "jean.martin@cagette.net";
				vendor.zipCode = "00000";
				vendor.city = "Martignac";
				vendor.insert();
				
				var contract = new db.Contract();
				contract.name = t._("Vegetables Contract Example");
				contract.amap  = amap;
				contract.type = 0;
				contract.vendor = vendor;
				contract.startDate = Date.now();
				contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
				contract.contact = user;
				contract.distributorNum = 2;
				contract.insert();
				
				var p = new db.Product();
				p.name = t._("Big basket of vegetables");
				p.price = 15;
				p.vat = 5;
				p.contract = contract;
				p.insert();
				
				var p = new db.Product();
				p.name = t._("Small basket of vegetables");
				p.price = 10;
				p.vat = 5;
				p.contract = contract;
				p.insert();
			
				var uc = new db.UserContract();
				uc.user = user;
				uc.product = p;
				uc.paid = true;
				uc.quantity = 1;
				uc.productPrice = 10;
				uc.insert();
				
				var d = new db.Distribution();
				d.contract = contract;
				d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
				d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
				d.place = place;
				d.insert();
				
				App.current.user = null;
				App.current.session.setUser(user);
				App.current.session.data.amapId  = amap.id;
				
				throw Ok("/", t._("Group and user 'admin' created. Your email is 'admin@cagette.net' and your password is 'admin'"));
			}	
			
			view.form= f;
	}
	
	/**
	 * get version status
	 */
	private function getVersionStatus(){
		
		
		var out = {parameter:"version", valid:false, message:""};
		
		/*var v = Variable.get("version");
		if (v == null || v=="") {
			Variable.set("version", App.VERSION.toString());
			v = App.VERSION.toString();
		}
		
		var v :thx.semver.Version = thx.semver.Version.stringToVersion(v);
		
		if (v.lessThan(App.VERSION)){
			
			//need update !
			out.valid = false;
			out.message = t._("You must update your database to version ") +App.VERSION.toString()+"";
			
		}else{
			out.valid = true;
			out.message = t._("Current version") +v.toString()+"";
		}*/
		
		return out;
		
	}
	
	/**
	 * perform migrations from a version to another
	 */
	@admin
	public function doUpdateversion(){
		
		var log = [];
		
		/*var currentVersion = thx.semver.Version.stringToVersion(Variable.get("version"));
		
		//Migrations to 0.9.2
		if (currentVersion.lessThan( thx.semver.Version.arrayToVersion([0,9,2]) )){
			
			log.push(t._("Installation of the dictionnary of products (taxonomy)"));
			_0_9_2_installTaxonomy();
			
			log.push(t._("Improvement on saving orders"));
			_0_9_2_dbMigration();
			
			sugoi.db.Variable.set("version", "0.9.2");
		}*/
		
		//Migrations to 1.0.0
		//...
		
		throw Ok("/install", t._("Following update have been performed:<ul>")+Lambda.map(log,function(x) return "<li>"+x+"</li>").join("")+"</ul>");
		
	}
	
	@admin
	function _0_9_2_installTaxonomy(){
		
		db.TxpCategory.manager.delete(true);
		db.TxpSubCategory.manager.delete(true);
		db.TxpProduct.manager.delete(true);
		
		var taxo = sys.io.File.getContent(sugoi.Web.getCwd() + "../data/productTaxonomy.json");
		var taxo = haxe.Json.parse(taxo);
		
		var categories :  Array<Dynamic> = taxo.categories;
		var subcategories : Array<Dynamic> = taxo.subCategories;
		var products : Array<Dynamic> = taxo.products;
		
		for ( c in categories){
			var cat = new db.TxpCategory();
			cat.id = c.id;
			cat.name = c.name;
			cat.insert();
		}
		
		for ( sc in subcategories){
			var scat = new db.TxpSubCategory();
			scat.id = sc.id;
			scat.name = sc.name;
			scat.category = db.TxpCategory.manager.get(Std.parseInt(sc.category));
			scat.insert();
			
		}
		
		for ( p in products){
			var pro = new db.TxpProduct();
			pro.name = p.name;
			pro.id = p.id;
			pro.category = db.TxpCategory.manager.get(Std.parseInt(p.category));
			pro.subCategory = db.TxpSubCategory.manager.get(Std.parseInt(p.subCategory));
			pro.insert();
		}
		
	}
	
	@admin
	function _0_9_2_dbMigration(){
		
		//recompute prices on orders
		for ( order in db.UserContract.manager.all(true)){
			order.productPrice = order.product.price;
			order.feesRate = order.product.contract.percentageValue;
			order.update();
		}
		
		
		//activate payment orders
		for ( a in db.Amap.manager.all(true)){
			a.allowedPaymentsType = ["cash", "transfer", "check"];
			a.update();
		}
		
	}

	/**
	migrate to multidistribs
	**/
	@admin 
	function doMigrateMultidistribs(){

		//MIGRATE to the new multidistrib Db architecture
		for( d in db.Distribution.manager.search($multiDistrib==null,{orderBy:-date,limit:10000},true)){

			//look for an existing md 3 hours around
			var from = DateTools.delta(d.date,1000.0*60*60*-3);
			var end = DateTools.delta(d.date,1000.0*60*60*3);
			if(d.contract==null) {
				trace(d.id+" has no contract<br/>");
				if(App.config.DEBUG) d.delete();
				continue;
			}
			if(d.date==null) {
				trace(d.id+" has no date<br/>");
				if(App.config.DEBUG) d.delete();
				continue;
			}
			var mds = db.MultiDistrib.manager.search($distribStartDate>=from && $distribStartDate<end && $place==d.place,true);
			if(mds.length>1) trace('too many mds !'+mds.length);
			var md : db.MultiDistrib = null;
			if(mds.length==0){
				
				//Create it
				md = new db.MultiDistrib();
				md.place = d.place;
				md.group = d.place.amap;
				md.distribStartDate = d.date;
				md.distribEndDate = d.end;
				md.orderStartDate = d.orderStartDate;
				md.orderEndDate = d.orderEndDate;
				md.insert();

			}else{
				md = mds.first();
			}

			//null identical fields
			/*
			if(md.distribStartDate.getTime()==d.date.getTime()) d.date = null;
			if(md.distribEndDate.getTime()==d.end.getTime()) d.end = null;
			if(md.orderStartDate!=null && md.orderStartDate.getTime()==d.orderStartDate.getTime()) d.orderStartDate = null;
			if(md.orderEndDate!=null && md.orderEndDate.getTime()==d.orderEndDate.getTime()) d.orderEndDate = null;			
			*/

			//bind to it
			d.multiDistrib = md;
			d.update();

			trace(d.toString()+"<br/>");
		}
	}
	
	/**
		migrate to new duty period mgmt
	**/
	@admin 
	function doMigrateDutyPeriods(){
		
		//update group params
		Sys.print("update group params and create roles.");
		var a = new db.Amap();

		for ( g in db.Amap.manager.all(true)){

			g.volunteersMailContent = a.volunteersMailContent;
			g.alertMailContent = a.alertMailContent;
		
			g.volunteersMailDaysBeforeDutyPeriod = 4;
			g.vacantVolunteerRolesMailDaysBeforeDutyPeriod = 7;
			g.daysBeforeDutyPeriodsOpen = 60;
			g.update();

			//create volunteers rôles
			for( c in g.getActiveContracts()){
				service.VolunteerService.createRoleForContract(c,c.distributorNum);
			}
		}

		//check all rôles for each MD
		Sys.print("check roles for multidistribs.");
		for(md in db.MultiDistrib.manager.all(true)){
			var roles = [];
			var allRoles = VolunteerService.getRolesFromGroup(md.group);
			///general roles
			//var generalRoles = Lambda.filter(allRoles, function(role) return role.contract == null);		
			//for( cr in generalRoles) roles.push(cr);
			//contract roles
			for ( distrib in md.getDistributions() ) {
				var cid = distrib.contract.id;
				var contractRoles = Lambda.filter(allRoles, function(role) return role.contract!=null && role.contract.id == cid);
				for( cr in contractRoles) roles.push(cr);
			}

			md.lock();
			md.volunteerRolesIds = Lambda.map(roles,function(r) return r.id).join(",");
			md.update();
		}

		Sys.print("migrate volunteer assignements.");
		//migre les inscriptions aux distribs
		for ( g in db.Amap.manager.all()){
			for( c in g.getActiveContracts()){
				var roles = Lambda.array(db.VolunteerRole.manager.search($contract==c));
				for ( d in c.getDistribs(false)){

					for( i in 1...5){

						var uid = Reflect.field(d,'distributor'+i+'Id');
						if( uid!=null && roles[i-1]!=null ){
							var user = db.User.manager.get(uid,false);
							try{
								//may fail for same volunteer on same md
								service.VolunteerService.addUserToRole(user,d.multiDistrib,roles[i-1]);
							}catch(e:Dynamic){}
						}

					}

				}
			}

		}
	}	
	
}