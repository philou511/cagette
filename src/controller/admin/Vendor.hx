package controller.admin;
import pro.db.VendorStats;
import service.BridgeService;

/**
 * Vendor admin
 */
class Vendor extends controller.Controller
{

	public function new() 
	{
		super();	
	}


	/**
		Vendors admin
	**/
	@tpl('admin/vendor/default.mtt')
	function doDefault() {
		var vendors = [];
		var total = 0;
		var totalCpros = 0;
		var totalActive = 0;
		var defaultType = VTCproSubscriberYearly;

		// form
		var f = new sugoi.form.Form("vendors");
		f.method = GET;
		f.addElement(new sugoi.form.elements.StringInput("companyNumber", "SIRET ou RNA"));
		var data = [
			{label: "Tous", value: "all"},
			{label: "Gratuit", value: VTFree.string()},
			{label: "Invité", value: VTInvited.string()},
			{label: "Invité dans un compte producteur", value: VTInvitedPro.string()},
			{label: "Formule Membre (formé)", value: VTCpro.string()},
			{label: "Cagette Pro test", value: VTCproTest.string()},
			{label: "Compte pédagogique", value: VTStudent.string()},
			{label: "Formule Découverte", value: VTDiscovery.string()},
			{label: "Formule Pro (abo annuel)", value: VTCproSubscriberYearly.string()},
			{label: "Formule Pro (abo mensuel)", value: VTCproSubscriberMontlhy.string()},
		];
		f.addElement(new sugoi.form.elements.StringSelect("type", "Type de producteur", data, defaultType.string(), true, ""));
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
				sql_where_and.push("type=" + Type.enumIndex(t));
			}

			// country
			sql_where_and.push('country="${f.getValueOf("country")}"');

			//SIRET
			if(f.getValueOf("companyNumber")!=null){
				sql_where_and.push('companyNumber="${f.getValueOf("companyNumber")}"');
			}

		} else {
			// default settings
			sql_where_and.push('active=1');
			sql_where_and.push('type=${Type.enumIndex(defaultType)}');
			sql_where_and.push('country="FR"');
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
	
	
	@admin @tpl("admin/vendor/view.mtt")
	function doView(v:db.Vendor) {
		var cpro = pro.db.CagettePro.getFromVendor(v);
		view.vendor = v;
		view.cpro = cpro;

		if (app.params["refresh"] == "1") {
			pro.db.VendorStats.updateStats(v);
			BridgeService.syncVendorToHubspot(v);
		}

		/*if (app.params["disableAccess"] != null) {
			var user = db.User.manager.get(Std.parseInt(app.params["disableAccess"]), false);
			var uc = pro.db.PUserCompany.get(user, cpro, true);
			uc.disabled = true;
			uc.update();
		}
		if (app.params["enableAccess"] != null) {
			var user = db.User.manager.get(Std.parseInt(app.params["enableAccess"]), false);
			var uc = pro.db.PUserCompany.get(user, cpro, true);			
			uc.disabled = false;
			uc.update();
		}*/

		view.stats = pro.db.VendorStats.getOrCreate(v);
		view.courses = hosted.db.CompanyCourse.manager.search($company == cpro, false);
		view.isCproCatalog = function(c:db.Catalog) {
			return connector.db.RemoteCatalog.getFromContract(c) != null;
		}
		view.profession = service.VendorService.getVendorProfessions().find(p -> return p.id == v.profession);
		if (v.activityCode != null) {
			var naf:String = v.activityCode.split(".").join("");
			view.activityCode = service.VendorService.getActivityCodes().find(p -> return p.id == naf);
		}
		view.isCorrectNAF = function(activityCode:String):Bool{
			if(activityCode==null) return true;
			var code = activityCode.split(".")[0].parseInt();
			if(code==null || code==0) return true;
			if( code==1 || code==3 || code==10 || code==11){
				return true;
			}
			return false;
		};

		var res = sys.db.Manager.cnx.request('select * from TmpVendor where vendorId = ${v.id}').results();
		var tmpVendor = res.first();
		view.tmpVendor = tmpVendor;
		
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

	function doBan(v:db.Vendor, args:{?reason:db.Vendor.DisabledReason,?unban:Bool}){

		if(args.unban==true){
			v.lock();
			v.disabled = null;
			v.update();
			throw Ok("/admin/vendor/view/"+v.id,"Producteur débloqué");
		}else{
			v.lock();
			v.disabled = args.reason;
			v.update();
			throw Ok("/admin/vendor/view/"+v.id,"Producteur bloqué");
		}		
	}


	@tpl("form.mtt")
	function doEdit(v:db.Vendor) {
		var form = service.VendorService.getForm(v);
		if (form.isValid()) {
			v.lock();
			service.VendorService.update(v, form.getDatasAsObject(), true);
			v.update();

			throw Ok("/admin/vendor/view/" + v.id, "Producteur mis à jour");
		}
		view.form = form;
	}
	
	
}