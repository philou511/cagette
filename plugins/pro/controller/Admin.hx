package pro.controller;

import service.DistributionService;
import db.User;
import haxe.DynamicAccess;
import db.MultiDistrib;
import crm.CrmService;
import db.Group.BetaFlags;
import tools.DateTool;
import pro.db.PUserCompany;
import tink.core.Error;
import service.SubscriptionService;
import service.VendorService;
import connector.db.RemoteCatalog;
import hosted.db.CompanyCourse;
import pro.payment.MangopayECPayment;
import pro.db.CagettePro;
import haxe.Json;
import db.Subscription;
import db.Operation;
import form.CagetteForm;
import db.Vendor;
import pro.db.VendorStats;
import tools.ObjectListTool;
import sugoi.tools.Csv;
import sugoi.form.Form;
import Common;
import mangopay.Mangopay;
import db.UserGroup;

using Std;

class Admin extends controller.Controller {
	public function new() {
		super();

		view.nav = nav("admin");
	}

	/**
		Vendors admin
	**/
	@tpl('plugin/pro/admin/default.mtt')
	function doDefault() {
		var vendors = [];
		var total = 0;
		var totalCpros = 0;
		var totalActive = 0;

		// form
		var f = new sugoi.form.Form("vendors");
		f.method = GET;
		var data = [
			{label: "Tous", value: "all"},
			{label: "Gratuit", value: VTFree.string()},
			{label: "Invité", value: VTInvited.string()},
			{label: "Invité dans un Cagette pro", value: VTInvitedPro.string()},
			{label: "Cagette Pro formé", value: VTCpro.string()},
			{label: "Cagette Pro en test", value: VTCproTest.string()},
			{label: "Cagette Pro pédagogique", value: VTStudent.string()},
			// {label:"Cagette Pro inscrit à une formation",value:"prostudent"},
			{label: "Cagette Découverte", value: VTDiscovery.string()},
		];
		f.addElement(new sugoi.form.elements.StringSelect("type", "Type de producteur", data, VTCproTest.string(), true, ""));
		f.addElement(new sugoi.form.elements.StringInput("zipCodes", "Saisir des numéros de département séparés par des virgules ou laisser vide."));
		f.addElement(new sugoi.form.elements.StringSelect("country", "Pays", db.Place.getCountries(), "FR", true, ""));
		var data = [
			{label: "Actifs", value: "active"},
			{label: "Inactifs", value: "inactive"},
			{label: "Tous", value: "all"}
		];
		f.addElement(new sugoi.form.elements.StringSelect("active", "Actifs ou pas", data, "active", true, ""));
		var data = [
			{label: "Tableau", value: "table"},
			{label: "Emails", value: "emails"},
			{label: "CSV", value: "csv"}
		];
		f.addElement(new sugoi.form.elements.StringSelect("output", "Sortie", data, "table", true, ""));

		var sql_select = "SELECT v.*,s.active,s.type,s.turnoverTotal,s.turnover90days";
		var sql_where_or = [];
		var sql_where_and = [];
		var sql_end = "ORDER BY SUBSTRING(v.zipCode,0,2),v.name ASC";
		var sql_from = ["Vendor v LEFT JOIN  VendorStats s ON v.id=s.vendorId "];

		if (f.isValid()) {
			// filter by zip codes
			var zipCodes:Array<Int> = f.getValueOf("zipCodes") != null ? f.getValueOf("zipCodes").split(",").map(Std.parseInt) : [];
			if (zipCodes.length > 0) {
				for (zipCode in zipCodes) {
					var min = zipCode * 1000;
					var max = zipCode * 1000 + 999;
					sql_where_or.push('(v.zipCode>=$min and v.zipCode<=$max)');
				}
			}

			// active
			switch (f.getValueOf("active")) {
				case "active":
					sql_where_and.push("active=1");
				case "inactive":
					sql_where_and.push("active=0");
				default:
			}

			// type
			if (f.getValueOf("type") != "all") {
				var t:VendorType = Type.createEnum(VendorType, f.getValueOf("type"));
				/*switch(t){
					case "cpro" : sql_where_and.push("type=0");
					case "free" : sql_where_and.push("type=1");
					case "invited" : sql_where_and.push("type=2");
					case "cprotest" : sql_where_and.push("v.isTest=1");
					default :
				}*/
				sql_where_and.push("type=" + Type.enumIndex(t));
			}

			// country
			sql_where_and.push('country="${f.getValueOf("country")}"');
		} else {
			// default settings
			sql_where_and.push("active=1");
			sql_where_and.push("type=" + Type.enumIndex(VTCproTest));
		}

		// QUERY
		if (sql_where_and.length == 0)
			sql_where_and.push("true");
		if (sql_where_or.length == 0)
			sql_where_or.push("true");
		var sql = '$sql_select FROM ${sql_from.join(", ")} WHERE (${sql_where_or.join(" OR ")}) AND ${sql_where_and.join(" AND ")} $sql_end';
		for (v in db.Vendor.manager.unsafeObjects(sql, false)) {
			vendors.push(v);
		}

		view.form = f;

		// remove trainee accounts
		/*for( v in vendors.copy()){
			if(v.name.indexOf("(formation)")>-1) vendors.remove(v);
		}*/

		for (v in vendors) {
			// refresh active
			if (app.params.exists("force")) {
				pro.db.VendorStats.updateStats(v);
			} else {
				// force creation of vendorStats
				VendorStats.getOrCreate(v);
			}

			if (untyped v.active)
				totalActive++;
			if (untyped v.type == 0)
				totalCpros++;
		}

		// TOTALS
		total = vendors.length;
		view.total = total;
		view.vendors = vendors;
		view.totalCpros = totalCpros;
		view.totalActive = totalActive;

		switch (f.getValueOf("output")) {
			case "table":

			case "emails":
				app.setTemplate(null);
				Sys.println("<html><body>");
				for (v in vendors)
					Sys.println('${v.email}<br/>');
				Sys.println('<hr/><a href="${makeMailtoLink(vendors)}">Leur Ecrire</a>');
				Sys.println("</body></html>");

			case "csv":
				var headers = [
					"id", "name", "email", "phone", "address1", "address2", "zipCode", "city", "active", "type"
				];
				var data = [];
				for (v in vendors) {
					var active:Bool = untyped v.active;
					var type:Int = untyped v.type;
					data.push({
						id: v.id,
						name: v.name,
						email: v.email,
						phone: v.phone,
						address1: v.address1,
						address2: v.address2,
						zipCode: v.zipCode,
						city: v.city,
						active: switch (active) {
							case true: "OUI";
							case false: "NON";
						},
						type: switch (type) {
							case 0: "cpro";
							case 1: "gratuit";
							case 2: "invité";
							default: "?";
						},
					});
				}

				sugoi.tools.Csv.printCsvDataFromObjects(data, headers, "producteurs");
		}
	}

	/**
		make a link to write to vendors
	**/
	function makeMailtoLink(vendors:Array<db.Vendor>) {
		var l = "mailto:?subject=Une%20formation%20Cagette%20Pro%20s'organise%20pr%C3%A8s%20de%20chez%20vous";

		// dedup on mail
		var vendors2 = new Map<String, db.Vendor>();
		for (v in vendors)
			vendors2.set(v.email, v);
		var vendors2 = Lambda.array(vendors2);

		for (v in vendors2) {
			if (sugoi.form.validators.EmailValidator.check(v.email)) {
				l += "&bcc=" + v.email;
			}
		}
		return l;
	}

	/**
		Deduplicate Vendors
	**/
	@tpl('plugin/pro/admin/deduplicate.mtt')
	function doDeduplicate() {
		var sql = "SELECT MAX(id) as id,MAX(name) as name,MAX(email) as email,COUNT(id) as duplicates,MAX(zipCode) as zipCode from Vendor GROUP BY email HAVING duplicates>2 ORDER BY duplicates DESC ";
		var res = sys.db.Manager.cnx.request(sql).results();
		view.vendors = res;
		var d = 0;
		for (r in res)
			d += r.duplicates - 1;
		view.duplicates = d;
		view.unlinkedVendors = db.Vendor.manager.count($user == null);
	}

	@tpl('plugin/pro/admin/dedupInfo.mtt')
	function doDedupInfo(email:String) {
		var vendors = db.Vendor.manager.search($email == email, true);

		view.vendors = vendors;
		var isCpro = function(v:db.Vendor) {
			return pro.db.CagettePro.manager.select($vendor == v) != null;
		};
		view.isCpro = isCpro;

		if (checkToken()) {
			var survivorId = Std.parseInt(app.params.get("vid"));
			var type = app.params.get("type") == "formation" ? "formation" : "master";
			if (survivorId == null)
				throw "no vid";
			var survivor = Lambda.find(vendors, function(v) return v.id == survivorId);
			var lastContract = null;
			for (v in vendors) {
				// hey, do not delete the survivor
				if (v.id == survivorId)
					continue;
				if (v.status == "formation" && type == "master")
					continue;
				if (v.status == "master")
					continue;
				if (v.status != "formation" && type == "formation")
					continue; // on efface que les comptes formation

				if (isCpro(v))
					throw "cant delete a vendor linked to a cpro";

				for (contract in db.Catalog.manager.search($vendor == v, true)) {
					contract.vendor = survivor;
					contract.update();

					if (contract.contact != null) {
						lastContract = contract;
					}
				}

				v.delete();
			}

			/*survivor.lock();
				survivor.status = "master";
				survivor.update(); */

			service.VendorService.getOrCreateRelatedUser(survivor);
			if (lastContract != null && lastContract.contact != null) {
				service.VendorService.sendEmailOnAccountCreation(survivor, lastContract.contact, lastContract.group);
			}

			throw Ok("/p/pro/admin/deduplicate", survivor.name + " a été dédupliqué");
		}
	}

	@tpl('plugin/pro/admin/dedupInfoByName.mtt')
	function doFindduplicatesbyname(name:String) {
		view.vendors = VendorService.findVendors(name);
	}

	@tpl('plugin/pro/admin/dedupInfoByZip.mtt')
	function doFindduplicatesbyzip(zip:String) {
		view.vendors = db.Vendor.manager.search($zipCode == zip, false);
	}

	@tpl('plugin/pro/admin/nullEmailVendors.mtt')
	function doNullEmailVendors() {
		view.vendors = db.Vendor.manager.search($email == null, false);
		view.getStats = pro.db.VendorStats.getOrCreate;
	}

	// Autolink Cpro to vendors
	function doLinkcprotovendors() {
		/*for( c in pro.db.CagettePro.manager.search($vendor==null)){

				var contract = null;

				//do not take a PVendor catalog
				for( catalog in c.getCatalogs()){
					if(catalog.vendor==null){
						
						for(rc in connector.db.RemoteCatalog.getFromCatalog(catalog)){
							if(rc!=null){
								var c = rc.getContract();
								if(c==null) {
									//OK !!!
									contract = c;
									break;
								}

							} 
						}
					}

					if(contract!=null) break;
				}
				
				var vendor = null;
				if(contract==null) {
					// make a vendor from the company
					vendor = new db.Vendor();
					vendor.name = c.name;
					vendor.email = c.email;
					vendor.phone = c.phone;
					vendor.address1 = c.address1;
					vendor.address2 = c.address2;
					vendor.zipCode = c.zipCode;
					vendor.city = c.city;
					vendor.image = c.image;
					vendor.desc = c.desc;
					vendor.linkText = c.linkText;
					vendor.linkUrl = c.linkUrl;
					vendor.insert();

				}else{
					vendor = contract.vendor;
				}


					c.vendor = vendor;
					c.update();

					vendor.lock();
					if(vendor.status!=null) throw 'vendor ${vendor.name} should have null status';
					vendor.status = c.training ? "formation" : "master";
					vendor.update();

					Sys.println('OK ${c.name} -> ${vendor.name}');

			}

			//migrate PVendor to PvendorCompany
			for( pv in Lambda.array(pro.db.PVendor.manager.all(true)).copy() ){
				var v = null;
				//finds master to reuse
				var vendors = db.Vendor.manager.search($status=="master" && $email==pv.email);
				if(vendors.length>0){
					v = vendors.first();
					
				}else{
					vendors = db.Vendor.manager.search($email==pv.email);
					v = vendors.first();
					if(v==null) continue;
					v.lock();
					v.status = "master";
					v.update();
				}

				pro.db.PVendorCompany.make(v,pv.company);

				//update catalogs
				for( cat in pro.db.PCatalog.manager.search($old_vendor==pv,true)){

					cat.vendor = v;
					cat.update();

				}

				pv.delete();
				if(v==null) continue;
				if(pv.company==null) continue;
				Sys.println(v.name+' -> linked to company -> '+pv.company.name);

			}


			//mark vendors with status "formation"
			for( c in pro.db.CagettePro.manager.all(true)){

				if(c.training){
					var v = c.vendor;
					if(v==null) continue;
					v.lock();
					v.status = "formation" ;
					if(v.name.indexOf("(formation)")==-1) v.name = v.name+" (formation)";
					v.update();

					//loop on catalogs
					for( cat in c.getCatalogs()){
						for( rc in connector.db.RemoteCatalog.getFromCatalog(cat)){
							var cont = rc.getContract();
							if(cont==null) continue;
							var v = cont.vendor;
							v.lock();
							v.status = "formation" ;
							if(v.name.indexOf("(formation)")==-1) v.name = v.name+" (formation)";
							v.update();

						}
					}

				}else{

					c.vendor.lock();
					c.vendor.status = "master";
					c.vendor.update();

					//loop on catalogs
					for( cat in c.getCatalogs()){
						for( rc in connector.db.RemoteCatalog.getFromCatalog(cat)){
							var cont = rc.getContract();
							if(cont==null) continue;
							var v = cont.vendor;
							v.lock();
							v.status = null ;
							v.name = StringTools.replace(v.name," (formation)",'');
							v.update();

						}
					}


				}

				

		}*/
	}

	@admin @tpl('plugin/pro/admin/vendor.mtt')
	function doVendor(v:db.Vendor) {
		var cpro = pro.db.CagettePro.getFromVendor(v);
		view.vendor = v;
		view.cpro = cpro;

		if (app.params["refresh"] == "1") {
			pro.db.VendorStats.updateStats(v);
			CrmService.syncToHubspot(v);
		}

		if (app.params["disableAccess"] != null) {
			var user = db.User.manager.get(Std.parseInt(app.params["disableAccess"]), false);
			var uc = PUserCompany.get(user, cpro, true);
			uc.disabled = true;
			uc.update();
		}
		if (app.params["enableAccess"] != null) {
			var user = db.User.manager.get(Std.parseInt(app.params["enableAccess"]), false);
			var uc = PUserCompany.get(user, cpro, true);
			crm.CrmService.syncToSiB(uc.user, true, "vendor_unlock");
			uc.disabled = false;
			uc.update();
		}

		view.stats = pro.db.VendorStats.getOrCreate(v);
		view.courses = hosted.db.CompanyCourse.manager.search($company == cpro, false);
		view.isCproCatalog = function(c:db.Catalog) {
			return connector.db.RemoteCatalog.getFromContract(c) != null;
		}
		view.profession = VendorService.getVendorProfessions().find(p -> return p.id == v.profession);
		if (v.activityCode != null) {
			var naf:String = v.activityCode.split(".").join("");
			view.activityCode = VendorService.getActivityCodes().find(p -> return p.id == naf);
		}

		view.editLink = "https://app.cagette.net/vendorNoAuthEdit/"
			+ v.id
			+ "/"
			+ haxe.crypto.Md5.encode(App.config.KEY + "_updateWithoutAuth_" + v.id);
	}

	@tpl("form.mtt")
	function doEditVendor(v:db.Vendor) {
		var form = VendorService.getForm(v);
		if (form.isValid()) {
			v.lock();
			VendorService.update(v, form.getDatasAsObject(), true);
			v.update();

			throw Ok("/p/pro/admin/vendor/" + v.id, "Producteur mis à jour");
		}
		view.form = form;
	}

	/**
	 * Massive import of groups from CSV
	 */
	@admin @tpl('plugin/pro/admin/import.mtt')
	function doImportGroup(?args:{confirm:Bool}) {
		var csv = new sugoi.tools.Csv();
		var step = 1;
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 4);

		// on recupere le contenu de l'upload
		if (request.get("file") != null) {
			csv.setHeaders([
				"Nom de Groupe", "Prénom", "Nom", "email", "téléphone", "Prénom", "Nom", "email", "téléphone", "Nom", "Adresse 1", "Adresse 2", "code postal",
				"ville", "Catalogue", "ouverture com.", "fermeture com.", "livraison debut", "livraison fin"
			]);

			var datas = csv.importDatas(request.get("file"));
			datas.shift();
			datas.shift();

			app.session.data.csvImportedData = datas;
			view.datas = datas;
			csv.step = 2;
		}

		var admins = ["francois@alilo.fr", "sebastien@alilo.fr"];

		if (args != null && args.confirm) {
			var i:Iterable<Dynamic> = cast app.session.data.csvImportedData;
			for (p in i) {
				/*mettre seb et françois en adhérent
					mettre le producteur en membre dans le groupe et lui donner accès à son contrat
					ouvrir l’abonnement à 100 adhérents avec expiration au 2016-12-31
				 */

				// group
				var group = new db.Group();
				group.name = p[0];
				// group.flags.set(db.Group.GroupFlags.IsAmap);
				group.flags.set(db.Group.GroupFlags.ShopMode);
				group.regOption = Open;
				group.insert();

				// main contact
				if (p[1] != null) {
					if (!sugoi.form.validators.EmailValidator.check(p[3]))
						throw 'email ${p[3]} is incorrect}]';
					var contact = service.UserService.getOrCreate(p[1], p[2], p[3]);
					if (contact.phone == null) {
						contact.phone = p[4];
						contact.update();
					}
					group.contact = contact;

					// membership and right
					var ua = contact.makeMemberOf(group);
					ua.giveRight(Right.GroupAdmin);
				}

				// hosting
				/*var h = hosted.db.Hosting.get(group.id, true);
					if (h.aboType == null || h.aboType < 1){
						h.aboEnd = Date.fromString("2016-12-31 00:00:00");
						h.aboType = 1;
						h.cdate = Date.now();
						h.update();
				}*/

				// contract coordinator
				var contact = service.UserService.getOrCreate(p[5], p[6], p[7]);
				if (contact.phone == null) {
					contact.phone = p[8];
					contact.update();
				}

				contact.makeMemberOf(group);

				// if no main contact
				if (p[1] == null) {
					group.contact = contact;
				}

				group.update();

				// contract
				var catalog = pro.db.PCatalog.manager.get(p[14].parseInt());
				var contract = pro.service.PCatalogService.linkCatalogToGroup(catalog, group, contact.id).getContract();

				// access to admins and vendor
				for (a in admins) {
					var u = db.User.manager.select($email == a, false);
					u.makeMemberOf(group);
				}
				for (x in catalog.company.getUsers()) {
					var ua = x.makeMemberOf(group);
					ua.giveRight(Right.ContractAdmin(contract.id));
				}

				// place
				var place = new db.Place();
				place.name = p[9];
				place.address1 = p[10];
				place.address2 = p[11];
				place.zipCode = p[12];
				place.city = p[13];
				place.group = group;
				place.insert();

				// distrib
				var d = new db.Distribution();
				d.catalog = contract;
				d.orderStartDate = Date.fromString(p[15]);
				d.orderEndDate = Date.fromString(p[16]);
				d.date = Date.fromString(p[17]);
				d.end = Date.fromString(p[18]);
				d.place = place;
				d.insert();
			}

			view.numImported = app.session.data.csvImportedData.length;
			app.session.data.csvImportedData = null;
			csv.step = 3;
		}

		if (csv.step == 1) {
			// reset import when back to import page
			app.session.data.csvImportedData = null;
		}

		view.csv = csv;
	}

	@admin
	function doBasketFixes() {
		/*
			vérifie la cohérence des datas des paniers
			- tout doit etre du meme user
			- tout doit etre pour la même multidistrib

			Les peuple avec les champs "user" et "multidistrib"
		 */
		/*var lastId:Int = sugoi.db.Variable.getInt("basketFixCounter");
			if(lastId==null) lastId = 0;
			Sys.print("<h2>Start from "+lastId+"</h2>"); */

		Sys.print("<h2>Still " + db.Basket.manager.count($multiDistrib == null) + " non migrated baskets</h2>");

		// Populate md and user field in baskets
		var baskets = db.Basket.manager.search($multiDistrib == null, {limit: 10000}, true);
		for (b in baskets) {
			// lastId = b.id;
			var ok = true;

			// check orders are for the same user and same md
			var orders = Lambda.array(b.getOrders());

			if (orders.length == 0) {
				b.delete();
				continue;
			}

			for (o in orders) {
				if (o == null)
					throw "null order in " + orders;
				if (o.user.id != orders[0].user.id)
					throw "various users in basket " + b.id;

				if (o.distribution == null) {
					Sys.print('basket#${b.id} : $o has null distrib, its from a ${o.product.catalog.type} type<br/>');
					Sys.print('date : ' + b.cdate + '<br/>');
					Sys.print('all orders are : ' + orders + '<br/>');
					ok = false;

					// fix : effacer les commandes avec qt zero, puisque la distrib derrière a été effacée
					for (ord in orders) {
						if (ord.quantity == 0) {
							ord.lock();
							ord.delete();
						}
					}

					// fix : si c'est un contrat AMAP, ça n'a rien à faire dans un basket.
					for (ord in orders) {
						if (ord.product.catalog.type == db.Catalog.TYPE_CONSTORDERS) {
							ord.lock();
							ord.basket = null;
							ord.update();
						}
					}

					// fix : c'est une commande d'un groupe pédagogique
					// dont la distrib a été effacée sauvagement au moment de la coupure du compte pedago
					for (ord in orders) {
						if (ord.product.catalog.vendor.status == "formation") {
							ord.lock();
							ord.delete();
						}
					}

					break;
				}

				if (o.distribution.multiDistrib == null) {
					Sys.print('basket#${b.id} : $o has null multidistrib, its from a ${o.product.catalog.type} type<br/>');
					Sys.print('date : ' + b.cdate + '<br/>');
					Sys.print('all orders are : ' + orders + '<br/>');
					ok = false;
					break;
				}

				if (o.distribution.multiDistrib.id != orders[0].distribution.multiDistrib.id) {
					Sys.print("various multidistrib in basket " + b.id + "<br/>");
					Sys.print('date : ' + b.cdate + '<br/>');
					Sys.print('all orders are : <br/>');
					for (o in orders) {
						if (o.distribution == null || o.distribution.multiDistrib == null)
							continue;
						Sys.print(o + " , MD = " + o.distribution.multiDistrib + " , producteur = " + o.distribution.catalog.vendor.name + "<br/>");
					}
					ok = false;

					// FIX IT
					var ordersByMd = new Map<Int, Array<db.UserOrder>>();
					for (o in orders) {
						if (o.distribution == null)
							continue;
						if (ordersByMd[o.distribution.multiDistrib.id] == null)
							ordersByMd[o.distribution.multiDistrib.id] = [];
						ordersByMd[o.distribution.multiDistrib.id].push(o);
					}
					var user = orders[0].user;

					for (mdid in ordersByMd.keys()) {
						var md = db.MultiDistrib.manager.get(mdid, false);
						var basket = new db.Basket();
						basket.insert();
						for (ord in ordersByMd[mdid]) {
							ord.lock();
							ord.basket = basket;
							ord.update();
						}
					}

					break;
				}
			}

			if (ok) {
				b.multiDistrib = orders[0].distribution.multiDistrib;
				b.user = orders[0].user;
				b.update();
				Sys.print("--------- updated basket " + b.id + "<br/>");
			}
		}

		// sugoi.db.Variable.set("basketFixCounter",lastId);
	}

	@admin @tpl('plugin/pro/admin/siret.mtt')
	function doSiret() {
		var badVendors = db.Vendor.manager.unsafeCount("SELECT count(v.id) FROM Vendor v, VendorStats vs where v.id=vs.vendorId and vs.active=1 and v.companyNumber is null");
		var total = db.Vendor.manager.unsafeCount("SELECT count(v.id) FROM Vendor v, VendorStats vs where v.id=vs.vendorId and vs.active=1");
		view.badVendors = badVendors;
		view.total = total;

		if (app.params["type"] == "good") {
			view.vendors = db.Vendor.manager.unsafeObjects("SELECT v.* FROM Vendor v, VendorStats vs where v.id=vs.vendorId and vs.active=1 and v.companyNumber is not null",
				false);
		}

		if (app.params["type"] == "bad") {
			view.vendors = db.Vendor.manager.unsafeObjects("SELECT v.* FROM Vendor v, VendorStats vs where v.id=vs.vendorId and vs.active=1 and v.companyNumber is null",
				false);
		}

		view.type = app.params["type"];

		// view.vendors = db.Vendor.manager.search($isTest,{orderBy:-id});
	}

	/**
		Vendors to delete
	**/
	function doListVendorsToDelete() {
		var cdate = DateTools.delta(Date.now(), -1000 * 60 * 60 * 24 * 30);
		// vendors created since more than 1 month
		for (v in db.Vendor.manager.search($cdate < cdate)) {
			if (v.getContracts().length == 0) {
				Sys.println('Vendor <a href="/p/pro/admin/vendor/${v.id}">${v.name}</a> has no catalogs ! <br/>');
			} else if (v.email == null) {
				Sys.println('Vendor <a href="/p/pro/admin/vendor/${v.id}">${v.name}</a> has no email ! <br/>');
			}
		}
	}

	/**
		@fbarbut
		2020-05-05
		- Fix missing remoteId in Mgp refunds
		- Spot "wrong" manually made mangopay payments
	**/
	function doFixGroupOps(group:db.Group) {
		// fix missing remoteOpId in MGP refunds
		var print = controller.Cron.print;
		print("<h1>Fix remoteId in refunds</h1>");
		for (op in db.Operation.manager.search($type == Payment && $group == group && $amount < 0, true)) {
			if (op.getPaymentType() != MangopayECPayment.TYPE)
				continue;
			var infos = op.getPaymentData();
			if (infos.remoteOpId == null) {
				// print(infos);
				print("==========");

				op.amount = Math.round(op.amount * 100) / 100;
				print('#${op.id} name : ${op.name}, amount : ${op.amount}, date : ${op.date}');

				// find refund
				var orderOp = op.relation;
				for (payment in orderOp.getRelatedPayments()) {
					if (payment.type == Payment && op.getPaymentType() == MangopayECPayment.TYPE) {
						var payinId = Std.parseInt(payment.getPaymentData().remoteOpId);
						if (payinId == null)
							continue;
						for (refund in Mangopay.getPayInRefunds(payinId)) {
							print("found refund : " + (refund.CreditedFunds.Amount / 100) + ", id : " + refund.Id);
							if (refund.CreditedFunds.Amount / 100 + op.amount == 0) {
								print("fix it");
								op.setPaymentData({type: MangopayECPayment.TYPE, remoteOpId: refund.Id.string()});
								op.update();
							}
						}
					}
				}
			}
		}

		print("<h1>Spot wrong MGP payments</h1>");
		for (op in db.Operation.manager.search($type == Payment && $group == group, false)) {
			if (op.getPaymentType() != MangopayECPayment.TYPE)
				continue;
			var infos = op.getPaymentData();
			if (infos.remoteOpId == null) {
				print("=========");
				print('<a href="/db/Operation/edit/${op.id}" target="_blank">#${op.id}</a>, name : ${op.name}, amount : ${op.amount}, date : ${op.date}');
				print(infos);
			}
		}
	}

	/**
		find groups with test cpros
	**/
	function doFindGroupsWithTestCpros() {
		/*var out = new Map<Int,{
			id:Int,
			groupName:String,


		}>();*/

		var groups = [];
		for (vs in VendorStats.manager.search($type == VTCproTest, false)) {
			var v = vs.vendor;
			var cpro = CagettePro.getFromVendor(v);

			for (c in cpro.getClients())
				groups.push(c);
		}

		groups = ObjectListTool.deduplicate(groups);

		var data = new Array<{
			id:Int,
			name:String,
			groupLeader:String,
			email:String,
			invitedVendors:Int,
			proVendors:Int,
			testProVendors:Int
		}>();

		for (g in groups) {
			var invitedVendors = 0;
			var proVendors = 0;
			var testCproVendors = 0;
			for (c in g.getActiveContracts()) {
				var rc = RemoteCatalog.getFromContract(c);

				if (rc == null) {
					invitedVendors++;
				} else {
					// var cpro = rc.getCatalog().company;
					if (c.vendor.isTest) {
						testCproVendors++;
					} else {
						proVendors++;
					}
				}
			}

			data.push({
				id: g.id,
				name: g.name,
				groupLeader: g.contact != null ? g.contact.getName() : "",
				email: g.contact != null ? g.contact.email : "",
				invitedVendors: invitedVendors,
				proVendors: proVendors,
				testProVendors: testCproVendors
			});
		}

		sugoi.tools.Csv.printCsvDataFromObjects(data, [
			"id",
			"name",
			"groupLeader",
			"email",
			"invitedVendors",
			"proVendors",
			"testProVendors"
		], "Groupes avec Cpro Test");
	}

	@admin
	function doMigrateOperations() {
		// 2020-07-31 : refacto payment ops
		/*var from = Date.fromString(app.params.get("from"));
			var to = Date.fromString(app.params.get("to"));

			for( op in db.Operation.manager.search($date >= from && $date < to && $data2 ==null ,true)){
				try{

					switch(op.type){
						case VOrder:
							var data :VOrderInfos = op.data;
							var basket = db.Basket.manager.get(data.basketId);
							// on peut migrer une op si le basket n'existe plus, pas la peine d'essayer de fixer un autre problème.
							
							if(basket!=null){
								op.basket = basket;
								op.setData({basketId:basket.id});
								Sys.print('Op ${op.id} OK<br/>');
							}else{
								op.setData({basketId:null});
								Sys.print('Warning "basket null" avec op <a href="http://localhost/db/Operation/edit/${op.id}">#${op.id}</a><br>');
							}
							try{

								op.update();
							}catch(e:Error){}
							
						
						case COrder :
							//delete this, it it exists its shit
							op.delete();	

						case Payment :
							var data :PaymentInfos = op.data;
							op.setData({type:data.type,remoteOpId:data.remoteOpId});
							op.update();
						case Membership :
							var data :MembershipInfos = op.data;
							op.setData({year:data.year});
							op.update();
					}

				}catch(e:Dynamic){

					Sys.print('Erreur "$e" avec op <a href="http://localhost/db/Operation/edit/${op.id}">#${op.id}</a><br>');

				}
				
		}*/
	}

	/**
		check and recompute payments ops
	**/
	@admin @tpl('plugin/pro/admin/checkOperations.mtt')
	function doCheckOperations(group:db.Group,from:Date,to:Date,?autoFix=false) {

		// var g = db.Group.manager.get(6598);
		var out = [];

		// for ( md in db.MultiDistrib.getFromTimeRange(g,new Date(2021,3,1,0,0,0), new Date(2021,11,30,0,0,0))){
		for ( md in db.MultiDistrib.getFromTimeRange(group,from,to) ){
			
			var msgs = [];
			for( b in md.getBaskets()){
				
				var op = b.getOrderOperation(false);
				var ordersTotal = Formatting.cleanFloat(0 - b.getOrdersTotal());
				var opAmount = Formatting.cleanFloat(op.amount);

				if(autoFix){
					if(!group.hasShopMode()) throw "cette page ne marche que pour les groupes en mode boutique";
					service.PaymentService.onOrderConfirm( b.getOrders() );
				}else{
					if(op==null){
						msgs.push('${b.user.getName()} , total commande : ${ordersTotal} != aucune operation');
						
					} else if( ordersTotal != opAmount ){
						msgs.push('${b.user.getName()} , total commande : ${ordersTotal} != opération : ${opAmount}');
						if(autoFix) service.PaymentService.onOrderConfirm( b.getOrders() );
					}
				}
			}

			out.push({
				md : md.toString(),
				messages : msgs
			});
		}

		if(autoFix) {			
			throw Ok('/p/pro/admin/checkOperations/${group.id}/$from/$to',"Operations corrigées");
		}

		view.mds = out;
		view.group = group;
		view.from = from;
		view.to = to;

	}

	@admin
	function doPreprod() {
		for (u in db.User.manager.all(true)) {
			u.flags.unset(HasEmailNotif4h);
			u.flags.unset(HasEmailNotif24h);
			u.flags.unset(HasEmailNotifOuverture);
			u.update();
		}
	}

	/**
	 * Create a cagette pro account
	 */
	function doCreateCpro(vendor:db.Vendor) {
		if (pro.db.CagettePro.getFromVendor(vendor) != null)
			throw Error("/p/pro/admin/vendor/" + vendor.id, vendor.name + " a deja un cagette Pro");

		vendor.lock();

		var cpro = new pro.db.CagettePro();
		cpro.vendor = vendor;
		cpro.insert();

		vendor.isTest = false;
		vendor.update();

		// user
		var user = service.UserService.getOrCreate("", "", vendor.email);

		// access
		var uc = new pro.db.PUserCompany();
		uc.company = cpro;
		uc.user = user;
		uc.insert();

		VendorStats.updateStats(vendor);

		throw Ok("/p/pro/admin/vendor/" + vendor.id, "Compte Cagette Pro créé");
	}

	function doCproTest(vendor:db.Vendor) {
		vendor.lock();

		var cpro = pro.db.CagettePro.getFromVendor(vendor);

		if (cpro == null) {
			cpro = new pro.db.CagettePro();
			cpro.vendor = vendor;
			cpro.insert();

			// user
			var user = service.UserService.getOrCreate("", "", vendor.email);

			// access
			var uc = new pro.db.PUserCompany();
			uc.company = cpro;
			uc.user = user;
			uc.insert();
		}

		vendor.isTest = true;
		vendor.update();

		VendorStats.updateStats(vendor);

		throw Ok("/p/pro/admin/vendor/" + vendor.id, "Compte passé en Cagette Pro Test");
	}

	@tpl("form.mtt")
	public function doNewVendor() {
		var vendor = new db.Vendor();
		var form = CagetteForm.fromSpod(vendor);

		if (form.isValid()) {
			form.toSpod(vendor);
			vendor.insert();

			/*service.VendorService.getOrCreateRelatedUser(vendor);
				service.VendorService.sendEmailOnAccountCreation(vendor,app.user,app.user.getAmap()); */

			throw Ok('/p/pro/admin/vendor/' + vendor.id, t._("This supplier has been saved"));
		}

		view.title = t._("Key-in a new vendor");
		// view.text = t._("We will send him/her an email to explain that your group is going to organize orders for him very soon");
		view.form = form;
	}

	@admin @tpl('plugin/pro/admin/import.mtt')
	function doImportUsersCustom() {
		var csv = new sugoi.tools.Csv();
		csv.step = 1;
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 4);

		// on recupere le contenu de l'upload
		if (request.get("file") != null) {
			csv.setHeaders([
				"groupName",
				"firstName",
				"lastName",
				"email",
				"phone",
				"address1",
				"address2",
				"zipCode",
				"city"
			]);
			var datas = csv.importDatasAsMap(request.get("file"));

			for (d in datas) {
				// generate email if needed
				if (d["email"] == null)
					d["email"] = d["lastName"].toLowerCase() + Std.random(100) + "@vrac-asso.org";

				var group = db.Group.manager.select($name.like(d["groupName"]));

				if (group == null) {
					throw "not found group named '" + d["groupName"] + "'";
				}

				if (group.name.toLowerCase() != d["groupName"].toLowerCase()) {
					throw group.name;
				}

				var u = db.User.manager.select($email == d["email"] || $email2 == d["email"], true);
				if (u == null) {
					u = new db.User();
					u.firstName = d["firstName"];
					u.lastName = d["lastName"];
					u.email = d["email"];
					u.address1 = d["address1"];
					u.address2 = d["address2"];
					u.zipCode = d["zipCode"];
					u.city = d["city"];
					u.countryOfResidence = "FR";
					u.flags = sys.db.Types.SFlags.ofInt(0);
					u.insert();
				}
				u.makeMemberOf(group);
			}
			csv.step = 3;
		}
		view.csv = csv;
	}

	/**
	 * Massive import of groups from CSV FOR CORTO/Givrés/VRAC
	 */
	@admin @tpl('plugin/pro/admin/import.mtt')
	function doImportGroupCustom(?args:{confirm:Bool}) {
		var csv = new sugoi.tools.Csv();
		csv.step = 1;
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 4);

		// on recupere le contenu de l'upload
		if (request.get("file") != null) {
			csv.setHeaders([
				"groupName",
				"placeName",
				"address",
				"zipCode",
				"city",
				"lastName",
				"firstName",
				"email"
			]);
			var datas = csv.importDatasAsMap(request.get("file"));
			app.session.data.csvImportedData = datas;
			view.datas = datas;
			csv.step = 2;
		}

		if (args != null && args.confirm) {
			var i:Array<Map<String, Dynamic>> = cast app.session.data.csvImportedData;
			var group = null;
			var contract = null;
			var place = null;
			var line = 0;
			for (p in i) {
				line++;
				if (p["groupName"] != null) {
					// create group
					group = new db.Group();
					group.name = p["groupName"];
					//group.flags.set(db.Group.GroupFlags.HasMembership);
					group.image = sugoi.db.File.manager.get(60865,false);
					group.flags.set(db.Group.GroupFlags.ShopMode);				
					group.flags.unset(db.Group.GroupFlags.CagetteNetwork);			
					group.regOption = Closed;
					group.groupType = db.Group.GroupType.GroupedOrders;
					// group.membershipRenewalDate = new Date(2017, 8, 1, 0, 0, 0);
					group.txtIntro = "VRAC est une association qui favorise le développement de groupements d’achats dans les quartiers de la géographie prioritaire de l'agglomération lyonnaise. En proposant des produits de consommation courante bio et /ou locaux, issus de l'agriculture paysanne, l'association participe à rendre accessible une alimentation durable pour tous. Ainsi, VRAC permet aux habitants de ces quartiers de s’inscrire dans un mode de consommation  responsable, qui repose sur le collectif et les dynamiques locales pour faire face à la précarité et proposer un autre rapport à la consommation, à la santé et à l’image de soi.";
					group.insert();

					var contact = null;

					// main contact
					if (p["firstName"] != null) {
						if (!sugoi.form.validators.EmailValidator.check(p["email"]))
							throw 'email ${p["email"]} is incorrect}]';
						contact = service.UserService.getOrCreate(p["firstName"], p["lastName"], p["email"]);
						group.contact = contact;

						// membership and right
						var ua = contact.makeMemberOf(group);
						ua.giveRight(Right.GroupAdmin);
					}

					// contract coordinator
					// var contact2 = db.User.getOrCreate(p["firstName2"], p["lastName2"], p["email2"]);
					// if (contact2.phone == null) {
					// 	contact2.phone = p["phone2"];
					// 	contact2.update();
					// }
					// contact2.makeMemberOf(group);

					// if (p["firstName"] == null){
					// group.contact = contact2;
					// }else{
					// group.contact = contact;
					// }

					group.update();

					// contract
					var catTQ = pro.db.PCatalog.manager.get(App.config.DEBUG ? 197 : 1395);
					var catTHQ = pro.db.PCatalog.manager.get(App.config.DEBUG ? 198 : 1462);

					if (group.name.indexOf("THQ") > -1) {
						pro.service.PCatalogService.linkCatalogToGroup(catTHQ, group, group.contact.id);
					} else {
						pro.service.PCatalogService.linkCatalogToGroup(catTQ, group, group.contact.id);
					}

					/*var catalogId = Std.parseInt(p["catalog"]);
						if ( catalogId == 0 || catalogId == null ) throw "catalog is null : " + p;
						var catalog = pro.db.PCatalog.manager.get(catalogId);
						contract = pro.service.PCatalogService.linkCatalogToGroup(catalog, group, contact.id).getContract();

						if(catalog.company.image!=null){
							group.image = catalog.company.image;
							group.update();
					}*/

					// access to admins and vendor
					// for ( a in admins){
					// 	var u = db.User.manager.select($email == a, false);
					// 	u.makeMemberOf(group);
					// }

					/*for ( x in catalog.company.getUsers()){
						var um = x.makeMemberOf(group);
						um.giveRight(Right.Membership);
						um.giveRight(Right.Messages);
						um.giveRight(Right.GroupAdmin);
						um.giveRight(Right.ContractAdmin());
					}*/

					// place
					place = new db.Place();
					place.name = p["placeName"];
					place.address1 = p["address"];
					// place.address2 = p["address2"];
					place.zipCode = p["zipCode"];
					place.city = p["city"];
					place.group = group;
					place.insert();

					// distrib
					// var d = new db.Distribution();
					// d.contract = contract;
					// d.orderStartDate = Date.fromString(p["ordersStartDate"]);
					// d.orderEndDate = Date.fromString(p["ordersEndDate"]);
					// d.date = Date.fromString(p["deliveryStartDate"]);
					// d.end = Date.fromString(p["deliveryEndDate"]);
					// d.place = place;
					// d.insert();

					/*try{
							group.contact.sendInvitation(group);
						}catch(e:Dynamic){
							trace(group.contact.name);
							trace(e);
					}*/
				}
			} // end for

			view.numImported = app.session.data.csvImportedData.length;
			app.session.data.csvImportedData = null;
			csv.step = 3;
		}

		if (csv.step == 1) {
			// reset import when back to import page
			app.session.data.csvImportedData = null;
		}

		view.csv = csv;
	}

	/**
		Duplicate a group
	**/
	@admin
	@tpl('plugin/pro/form.mtt')
	function doDuplicate() {
		var f = new sugoi.form.Form("g");

		// get client list
		var data = [];
		var gids = tools.ObjectListTool.getIds(hosted.db.Hosting.manager.search($active, false));
		var groups = db.Group.manager.search($id in gids, false);

		for (g in groups) {
			data.push({label: "#" + g.id + " " + g.name, value: g.id});
		}

		f.addElement(new sugoi.form.elements.IntSelect("group", "Choisissez un groupe à dupliquer", cast data, true));

		if (f.isValid()) {
			var s = new pro.service.ProGroupService();
			var x = db.Group.manager.get(f.getValueOf("group"));
			s.duplicateGroup(x, true, x.name + "(copy)", x.getMainPlace().name);

			throw Ok("/", "Groupe dupliqué");
		}

		view.form = f;
		view.title = "Dupliquer un groupe";
	}

	/**
		delete/disable a vendor
	**/
	function doDelete(vendor:db.Vendor, action:String) {
		switch (action) {
			case "disable":
				var cpro = CagettePro.getFromVendor(vendor);
				if (cpro == null)
					throw "is not cpro";

				for (cat in cpro.getCatalogs()) {
					for (rc in connector.db.RemoteCatalog.getFromCatalog(cat)) {
						if (rc.getContract() != null) {
							throw Error("/p/pro/admin/vendor/" + vendor.id, "Ce Cagette Pro a encore des catalogues reliés à des groupes");
						}
					}
				}

				for (uc in pro.db.PUserCompany.getUsers(cpro)) {
					uc.lock();
					uc.delete();
				}

				cpro.lock();
				cpro.vendor.user = null;
				cpro.disabled = true;
				cpro.update();

				VendorStats.updateStats(vendor);

				throw Ok("/p/pro/admin/vendor/" + vendor.id, "Cagette Pro désactivé");

			case "deleteCpro":
				var cpro = CagettePro.getFromVendor(vendor);
				if (cpro == null)
					throw "is not cpro";

				for (cat in cpro.getCatalogs()) {
					for (rc in connector.db.RemoteCatalog.getFromCatalog(cat)) {
						if (rc.getContract() != null) {
							throw Error("/p/pro/admin/vendor/" + vendor.id, "Ce Cagette Pro a encore des catalogues reliés à des groupes");
						}
					}
				}

				cpro.lock();
				cpro.delete();

				VendorStats.updateStats(vendor);

				throw Ok("/p/pro/admin/vendor/" + vendor.id, "Cagette Pro désactivé");

			case "delete":
				if (vendor.getContracts().length > 0) {
					throw Error("/p/pro/admin/vendor/" + vendor.id, "Ce producteur a encore des catalogues dans des groupes");
				} else {
					vendor.lock();
					vendor.delete();

					throw Ok("/p/pro/admin/", "Producteur effacé");
				}
		}
	}

	/**
	 * ADMIN : Transform a contract to a catalog
	 */
	@admin @tpl('form.mtt')
	public function doContractToCatalog(?catalog:db.Catalog, ?cagettePro:pro.db.CagettePro) {
		var f = new sugoi.form.Form("contract");
		view.title = "Importer un catalogue groupe dans un cagette pro";
		if (catalog != null && cagettePro != null) {
			/*f.addElement(new sugoi.form.elements.IntInput("cid",catalog.name+" dans le groupe "+catalog.group.name,catalog.id,true));
				f.addElement(new sugoi.form.elements.IntInput("companyId",cagettePro.vendor.name,cagettePro.id,true)); */

			view.text = 'Voulez vous importer ce catalogue <b>${catalog.name}</b><br/> dans le Cagette Pro <b>${cagettePro.vendor.name}</b> ?';

			if (f.isValid()) {
				for (p in catalog.getProducts(false)) {
					// product
					var pp = new pro.db.PProduct();
					pp.name = p.name;

					// créé une ref si existe pas...
					if (p.ref == null || p.ref == "") {
						p.ref = p.name.toUpperCase().substr(0, 4);
					}
					pp.ref = p.ref;
					pp.image = p.image;
					pp.desc = p.desc;
					pp.company = cagettePro;
					pp.unitType = p.unitType;
					pp.active = p.active;
					pp.organic = p.organic;
					pp.txpProduct = p.txpProduct;
					pp.insert();

					// create one offer
					var off = new pro.db.POffer();
					off.price = p.price;
					off.vat = p.vat;
					if (pp.ref != null) {
						off.ref = pp.ref + "-1";
					}
					off.product = pp;
					off.quantity = p.qt;
					off.active = p.active;
					off.insert();
				}
				throw Ok("/p/pro/admin/vendor/" + catalog.vendor.id, "Catalogue copié");
			}
		} else {
			f.addElement(new sugoi.form.elements.IntInput("cid", "ID du catalogue", null, true));
			f.addElement(new sugoi.form.elements.IntInput("companyId", "ID du Cagette Pro", null, true));

			if (f.isValid()) {
				var cid = f.getElement("cid").getValue();
				var companyId:Int = f.getValueOf("companyId");
				var company = pro.db.CagettePro.manager.get(companyId, false);
				var contract = db.Catalog.manager.get(cid, false);

				if (company == null)
					throw "Ce compte Cagette Pro n'existe pas";
				if (contract == null)
					throw "Ce contrat n'existe pas";

				throw Redirect("/p/pro/admin/contractToCatalog/" + contract.id + "/" + company.id);
			}
		}

		view.form = f;
	}

	/**
		Move a Cpro Catalog (and its products and offers) from one company to another
	**/
	@admin @tpl("form.mtt")
	function doMoveCatalog() {
		var f = new sugoi.form.Form("movecata");
		f.addElement(new sugoi.form.elements.IntInput("catalogId", "ID du catalogue cpro à déplacer", null, true));
		f.addElement(new sugoi.form.elements.IntInput("vid", "ID du producteur (qui doit avoir Cagette Pro) qui va recevoir le catalogue", null, true));

		if (f.isValid()) {
			var catalog = pro.db.PCatalog.manager.get(f.getValueOf("catalogId"));
			var vendor = db.Vendor.manager.get(f.getValueOf("vid"));
			var company = pro.db.CagettePro.getFromVendor(vendor);

			for (p in catalog.getProducts()) {
				p.product.lock();
				p.product.company = company;
				p.product.update();
			}

			catalog.company = company;
			catalog.update();

			throw Ok("/p/pro/admin/moveCatalog", "Le catalogue \"" + catalog.name + "\" a été déplacé chez \"" + company.vendor.name + "\"");
		}

		view.form = f;
	}

	/**
		Copy products from a cpro to another
	**/
	@admin @tpl("form.mtt")
	function doCopyProducts() {
		var f = new sugoi.form.Form("movecata");
		f.addElement(new sugoi.form.elements.IntInput("sourcevid", "ID du producteur Cagette Pro source", null, true));
		f.addElement(new sugoi.form.elements.IntInput("desvid", "ID du producteur Cagette Pro destination", null, true));

		if (f.isValid()) {
			var vendor = db.Vendor.manager.get(f.getValueOf("sourcevid"));
			var company = pro.db.CagettePro.getFromVendor(vendor);

			var destVendor = db.Vendor.manager.get(f.getValueOf("desvid"));
			var destCompany = pro.db.CagettePro.getFromVendor(destVendor);

			for (product in company.getProducts()) {
				var p2 = new pro.db.PProduct();
				for (key in [
					"name", "ref", "txpProduct", "desc", "imageId", "active", "unitType", "organic", "variablePrice", "multiWeight"
				]) {
					Reflect.setProperty(p2, key, Reflect.getProperty(product, key));
				}
				p2.company = destCompany;
				p2.insert();

				for (off in product.getOffers()) {
					var off2 = new pro.db.POffer();
					for (key in ["name", "ref", "imageId", "quantity", "price", "vat", "active"]) {
						Reflect.setProperty(off2, key, Reflect.getProperty(off, key));
					}
					off2.product = p2;
					off2.insert();
				}
			}

			throw Ok("/p/pro/admin/copyProducts", "Les produits de  \"" + vendor.name + "\" a été copiés chez \"" + destVendor.name + "\"");
		}

		view.form = f;
	}

	/**
		envoi du mail aux producteur pour qu'il remplissent leurs infos légales.
	**/
	function doSendLegalInfosMail() {
		for (v in db.Vendor.manager.unsafeObjects("SELECT v.* FROM Vendor v, VendorStats vs where v.id=vs.vendorId and vs.active=1 and v.companyNumber is null and disabled is null",
			false)) {
			var vs = VendorStats.getOrCreate(v);

			if (vs.type == VTStudent)
				continue;
			if (v.disabled != null)
				continue;
			if (v.email == null)
				continue;

			Sys.println('send to <a href="/p/pro/admin/vendor/${v.id}">${v.name}</a><br/>');

			var m = new sugoi.mail.Mail();
			m.setSender(App.config.get("default_email"), "Cagette.net");
			m.setRecipient(v.email);
			m.setReplyTo("support@cagette.net", "Cagette.net");
			m.setSubject("Important : mise en conformité des comptes producteurs sur Cagette.net");
			var link = "http://app.cagette.net/vendorNoAuthEdit/"
				+ v.id
				+ "/"
				+ haxe.crypto.Md5.encode(App.config.KEY + "_updateWithoutAuth_" + v.id);

			m.setHtmlBody(app.processTemplate("plugin/pro/mail/vendorLegalInfos.mtt", {vendor: v, link: link, type: vs.type.getIndex()}));
			App.sendMail(m);
		}
	}

	/**
		block "covid" cpro tests on 2020-10-01
	**/
	/*function doBlockCproTest(){
		var data = sys.io.File.getContent(sugoi.Web.getCwd() + "../data/cpro_test_a_bloquer.csv");
		var csv = new sugoi.tools.Csv();
		csv.setHeaders(["email","id","firstname","lastname","company","city"]);

		var print = function(str:String){
			Sys.println(str + "<br />");
		};

		print("<html><body>");

		for(l in csv.importDatasAsMap(data)){
			var user = db.User.manager.get(Std.parseInt(l["id"]),false);

			if(user==null){
				print("!!! user is null "+Std.string(l));
				continue;
			} 
			if(user.email!=l["email"]){
				print("!!! mail is not the same :  "+user.email+" != "+l["email"]);
				continue;
			}
			var companies = PUserCompany.getCompanies(user).array();
			if(companies.length>1){
				print("!!! user has many cpros  :  "+companies);
				continue;
			}
			if(companies.length==0){
				print("!!! user has no cpros");
				continue;
			}

			var cpro = companies[0];
			for( uc in cpro.getUserCompany()){
				uc.lock();
				uc.disabled = true;
				uc.update();
				print("OK "+uc.user.email+" has no more acces to "+cpro.vendor.name+ " #"+cpro.vendor.id);
			}

		}

		print("</body></html>");
	}*/
	public function doTimeSlotsStats() {
		var distribs = db.MultiDistrib.manager.search($orderEndDate > Date.fromString("2021-01-01")
			&& $orderEndDate < Date.fromString("2021-06-01")
			&& $slots != null);

		var nbDefaultSM = 0;
		var nnSoloSM = 0;
		var nbInvalid = 0;
		var invalids = [];
		for (distrib in distribs) {
			var slotsMode = distrib.slotsMode;

			if (slotsMode == "solo-only") {
				nnSoloSM += 1;
			} else if (slotsMode == "default") {
				nbDefaultSM += 1;
			} else {
				nbInvalid += 1;
				invalids.push(slotsMode);
			}
		}

		json({
			"nb Distribs": distribs.length,
			nbDefaultSM: nbDefaultSM,
			nnSoloSM: nnSoloSM,
			nbInvalid: nbInvalid,
			invalids: invalids
		});
	}

	@admin
	public function doTimeSlotsSync() {
		var limit = app.params.get("limit") != null ? Std.parseInt(app.params.get("limit")) : 500;
		var offset = app.params.get("offset") != null ? Std.parseInt(app.params.get("offset")) : 0;
		var sql = "SELECT * FROM MultiDistrib 
			WHERE slots IS NOT NULL 
			AND slots != 'n' 
			LIMIT "+limit+" OFFSET "+offset+" ";
		var distribs = db.MultiDistrib.manager.unsafeObjects(sql, true);

		// if (distribs.length == 0) {
		// 	Sys.print("no distribs");
		// 	return;
		// }
		
		var parsed = [];
		var slotsNull = [];
		var slotsLength0 = [];
		var others = [];

		for (distrib in distribs) {
			if (distrib.slots != null && distrib.slots.length > 0) {
				// distrib.lock();
				var slots:Array<Dynamic> = [];
				for (slot in distrib.slots) {
					var selectedUserIds = slot.selectedUserIds;
					if (distrib.inNeedUserIds != null) {
						for (inNeedUserId in distrib.inNeedUserIds.keys()) {
							selectedUserIds.push(inNeedUserId);
						}
					}
					slots.push({
						id: slot.id,
						selectedUserIds: selectedUserIds,
						registeredUserIds: slot.registeredUserIds,
						start: DateTool.toJs(slot.start),
						end: DateTool.toJs(slot.end),
					});
				};
				distrib.timeSlots = Json.stringify(slots);
				distrib.update();
				parsed.push(distrib);
			} else {
				if (distrib.slots == null) {
					slotsNull.push(distrib);
				} else if (distrib.slots.length == 0) {
					slotsLength0.push(distrib);
				} else {
					others.push(distrib);
				}
			}
		}

		Sys.print(Json.stringify({
			v: 5,
			infos: {
				nbDistribs: distribs.length,
				nbParsed: parsed.length,
				// parsed: parsed,
				nbSlotsNull: slotsNull.length,
				// slotsNull: slotsNull,
				nbSlotsLength0: slotsLength0.length,
				// slotsLength0: slotsLength0,
				nbOthers: others.length
				// others: others
			},
			sql: sql,
			offset: offset,
			nextHttp: "http://" + App.config.HOST + "/p/pro/admin/timeSlotsSync?limit="+limit+"&offset="+(offset + limit),
			nextHttps: "https://" + App.config.HOST + "/p/pro/admin/timeSlotsSync?limit="+limit+"&offset="+(offset + limit)
		}));
	}

	public function doTimeSlotsSyncInfo() {
		var now = Date.fromString("2020-01-01");

		var sql = "SELECT * FROM MultiDistrib 
		WHERE slots IS NOT NULL
		AND timeSlots IS NOT NULL 
		AND slotsMode <> 'y7:default'
		AND inNeedUserIds <> 'qh'
		AND distribStartDate > '"+ now + "' ";
		var distribs = db.MultiDistrib.manager.unsafeObjects(sql, false);

		var res = [];

		for (distrib in distribs) {
			var it = distrib.inNeedUserIds.keys();
			while (it.hasNext()) {
				var userId = it.next();

				var user = User.manager.get(userId);

				res.push({
					distribId: distrib.id,
					distribStartDate: distrib.distribStartDate,
					userId: userId,
					email: user.email
				});
			}
		}

		Sys.print(Json.stringify({
			status: "success",
			sql: sql,
			nbDistribsToProcess: distribs.length,
			res: res,
		}));
	}

	function doTest() {
		var offset = app.params.get("offset");

		Sys.print(Json.stringify({
			status: "succes",
			offset: offset,
		}));
	}


	/**
		2021-07-05
		trouver combien de producteurs sont dans les amaps ET dans les groupes en mode boutique
	**/
	function doAmapStats(){

		var out = {
			onlyShop:0,
			onlyAMAP:0,
			both:0
		};

		for ( vs in VendorStats.manager.search($active==true,false)){
			var v = vs.vendor;

			var groups = v.getActiveContracts().map( c -> c.group ).array();
			groups = ObjectListTool.deduplicate(groups);

			var groupTypes = {
				amap:0,
				shop:0
			};

			for( g in groups ){

				if(g.hasShopMode()){
					groupTypes.shop++;
				}else{
					groupTypes.amap++;
				}
			}

			if(groupTypes.amap==0 && groupTypes.shop>0){
				out.onlyShop++;
			}else if ( groupTypes.shop==0 && groupTypes.amap>0 ){
				out.onlyAMAP++;
			}else if ( groupTypes.shop>0 && groupTypes.amap>0 ){
				out.both++;
			}

		}

		Sys.print(Json.stringify(out));

	}

	/**
		stats pour https://docs.google.com/spreadsheets/d/131YGMLCBD22JFgANv6Y2QjYKncHvd_lpaG8_ujSlh4c/edit#gid=404041288
	**/
	function doCastats(?to:Date){

		var from = new Date(2020,5,1,0,0,0);
		if(to==null) to = new Date(2020,6,1,0,0,0);

		var turnovers = [];

		var createdFrom = new Date(2020,5,1,0,0,0);
		var createdTo = new Date(2020,5,30,23,59,59);

		for( v in Vendor.manager.search($cdate>=createdFrom && $cdate<createdTo ,false)){

			var vs = VendorStats.getOrCreate(v);
			if(vs.type==VendorType.VTCpro) continue;
			if(vs.type==VendorType.VTStudent) continue;
			if(vs.type==VendorType.VTCproStudent) continue;
			if(vs.type==VendorType.VTDiscovery) continue;

			var cids = v.getContracts().array().map(v -> v.id);
			var turnover = 0.0;
			for( d in db.Distribution.manager.search($date >= from && $date < to && ($catalogId in cids), false)){
				turnover += d.getTurnOver();
			}

			turnovers.push( Math.round(turnover) );
		}

		//besoin de compter les producteurs par tranche de c.a
		var vendors = new Map<String,Int>();
		vendors.set("0-250",0);
		vendors.set("250-500",0);
		vendors.set("500-750",0);
		vendors.set("750-1000",0);
		vendors.set("1000-1250",0);
		vendors.set("1250-1500",0);
		vendors.set("1500-1750",0);
		vendors.set("1750-2000",0);
		vendors.set("2000-3000",0);
		vendors.set("3000-5000",0);
		vendors.set("5000-10000",0);
		vendors.set("10000-20000",0);
		vendors.set("20000-30000",0);
		vendors.set("30000-40000",0);
		vendors.set("40000",0);

		// var inc = function(k:String){
		// 	var v = vendors.get(k);
		// 	vendors.get
		// }

		for( t in turnovers){

			if(t< 250){
				vendors["0-250"]++;
			}else if (t >= 250 && t< 500){
				vendors["250-500"]++;
			}else if (t >= 500 && t< 750){
				vendors["500-750"]++;
			}else if (t >= 750 && t< 1000){
				vendors["750-1000"]++;
			}else if (t >= 1000 && t< 1250){
				vendors["1000-1250"]++;
			}else if (t >= 1250 && t< 1500){
				vendors["1250-1500"]++;
			}else if (t >= 1500 && t< 1750){
				vendors["1500-1750"]++;
			}else if (t >= 1750 && t< 2000){
				vendors["1750-2000"]++;
			}else if (t >= 2000 && t< 3000){
				vendors["2000-3000"]++;
			}else if (t >= 3000 && t< 5000){
				vendors["3000-5000"]++;
			}else if (t >= 5000 && t< 10000){
				vendors["5000-10000"]++;
			}else if (t >= 10000 && t< 20000){
				vendors["10000-20000"]++;
			}else if (t >= 20000 && t< 30000){
				vendors["20000-30000"]++;
			}else if (t >= 30000 && t< 40000){
				vendors["30000-40000"]++;
			}else if (t >= 40000){
				vendors["40000"]++;
			}
		}

		Sys.print("from "+from.toString()+" to "+to.toString()+"<br/>");
		Sys.print("<table>");

		var keys = [];
		for( k in vendors.keys()){
			keys.push(k);
		}

		keys.sort(function(a,b){
			return a.split("-")[0].parseInt() - b.split("-")[0].parseInt();
		});

		for( k in keys ){
			Sys.print("<tr>");
			Sys.print("<td>"+k+"</td><td>"+vendors[k]+"</td>");
			Sys.print("</tr>");
		}

		Sys.print("</table>");




	}
}
