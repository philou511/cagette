package controller;
import sugoi.db.Variable;
import sugoi.form.elements.StringInput;
import thx.semver.Version;

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
	
	/**
	 * First install 
	 */
	@tpl("form.mtt")
	public function doFirstInstall(){
		view.title = "Installation de Cagette.net";

			var f = new sugoi.form.Form("c");
			f.addElement(new StringInput("amapName", "Nom de votre groupement","",true));
			f.addElement(new StringInput("userFirstName", "Votre prénom","",true));
			f.addElement(new StringInput("userLastName", "Votre nom de famille","",true));

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
				amap.flags.set(db.Amap.AmapFlags.IsAmap);
				amap.insert();
				
				var ua = new db.UserAmap();
				ua.user = user;
				ua.amap = amap;
				ua.rights = [db.UserAmap.Right.AmapAdmin,db.UserAmap.Right.Membership,db.UserAmap.Right.Messages,db.UserAmap.Right.ContractAdmin(null)];
				ua.insert();
				
				//example datas
				var place = new db.Place();
				place.name = "Place du marché";
				place.amap = amap;
				place.address1 = "Place Jules Verne";
				place.zipCode = "00000";
				place.city = "St Martin de la Cagette";
				place.insert();
				
				var vendor = new db.Vendor();
				vendor.amap = amap;
				vendor.name = "Jean Martin EURL";
				vendor.insert();
				
				var contract = new db.Contract();
				contract.name = "Contrat Maraîcher Exemple";
				contract.amap  = amap;
				contract.type = 0;
				contract.vendor = vendor;
				contract.startDate = Date.now();
				contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
				contract.contact = user;
				contract.distributorNum = 2;
				contract.insert();
				
				var p = new db.Product();
				p.name = "Gros panier de légumes";
				p.price = 15;
				p.contract = contract;
				p.insert();
				
				var p = new db.Product();
				p.name = "Petit panier de légumes";
				p.price = 10;
				p.contract = contract;
				p.insert();
			
				var uc = new db.UserContract();
				uc.user = user;
				uc.product = p;
				uc.paid = true;
				uc.quantity = 1;
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
				
				throw Ok("/", "Groupe et utilisateur 'admin' créé. Votre email est 'admin@cagette.net' et votre mot de passe est 'admin'");
			}	
			
			view.form= f;
	}
	
	/**
	 * get version status
	 */
	private function getVersionStatus(){
		
		
		var out = {parameter:"version", valid:false, message:""};
		
		var v = Variable.get("version");
		if (v == null || v=="") {
			Variable.set("version", App.VERSION.toString());
			v = App.VERSION.toString();
		}
		
		var v :thx.semver.Version = thx.semver.Version.stringToVersion(v);
		
		if (v.lessThan(App.VERSION)){
			
			//need update !
			out.valid = false;
			out.message = "Vous devez mettre à jour votre base de données vers la version "+App.VERSION.toString()+"";
			
		}else{
			out.valid = true;
			out.message = "Version actuelle "+v.toString()+"";
		}
		
		return out;
		
	}
	
	/**
	 * perform migrations from a version to another
	 */
	@admin
	public function doUpdateversion(){
		
		var log = [];
		
		var currentVersion = thx.semver.Version.stringToVersion(Variable.get("version"));
		
		//Migrations to 0.9.2
		if (currentVersion.lessThan( thx.semver.Version.arrayToVersion([0,9,2]) )){
			
			log.push("Installation du dictionnaire de produits (taxonomie)");
			_0_9_2_installTaxonomy();
			
			log.push("Amélioration du stockage des commandes");
			_0_9_2_dbMigration();
			
			sugoi.db.Variable.set("version", "0.9.2");
		}
		
		//Migrations to 1.0.0
		//...
		
		throw Ok("/install","Les opérations de mise à jour suivantes on été faites : <ul>"+Lambda.map(log,function(x) return "<li>"+x+"</li>").join("")+"</ul>");
		
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
	
}