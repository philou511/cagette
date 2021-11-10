package controller.admin;
import sugoi.Web;
import pro.db.VendorStats;

import sugoi.db.Variable;
import db.TxpProduct;
import db.BufferedJsonMail;
import hosted.db.GroupStats;
import tools.Timeframe;
import service.GraphService;
import db.Catalog;
import db.MultiDistrib;
import haxe.web.Dispatch;
import Common;

class Admin extends Controller {
	public function new() {
		super();
		view.category = 'admin';

		// trigger a "Nav" event
		var nav = new Array<Link>();
		var e = Nav(nav, "admin");
		app.event(e);
		view.nav = e.getParameters()[0];
	}

	@tpl("admin/default.mtt")
	function doDefault() {
		view.now = Date.now();
		view.ip = Web.getClientIP();
	}

	@tpl("admin/emails.mtt")
	function doEmails(?args:{?reset:BufferedJsonMail}) {
		if (args != null && args.reset != null) {
			args.reset.lock();
			args.reset.tries = 0;
			args.reset.update();
		}

		var emails:Array<Dynamic> = service.BridgeService.call("/mail/getUnsentMails");

		var browse = function(index:Int, limit:Int) {
			var filtered = [];
			for (i in 0...limit) {
				if (i + index < emails.length) {
					filtered.push(emails[i + index]);
				}
			}
			return filtered;
		}

		var count = emails.length;
		view.browser = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.num = count;
	}

	@tpl("form.mtt")
	function doSmtp() {
		var f = new sugoi.form.Form("emails");
		var data = [{label: "SMTP", value: "smtp"}, {label: "Mandrill API", value: "mandrill"},];

		var mailer = sugoi.db.Variable.get("mailer") == null ? "smtp" : sugoi.db.Variable.get("mailer");
		var host = sugoi.db.Variable.get("smtp_host") == null ? App.config.get("smtp_host") : sugoi.db.Variable.get("smtp_host");
		var port = sugoi.db.Variable.get("smtp_port") == null ? App.config.get("smtp_port") : sugoi.db.Variable.get("smtp_port");
		var user = sugoi.db.Variable.get("smtp_user") == null ? App.config.get("smtp_user") : sugoi.db.Variable.get("smtp_user");
		var pass = sugoi.db.Variable.get("smtp_pass") == null ? App.config.get("smtp_pass") : sugoi.db.Variable.get("smtp_pass");

		f.addElement(new sugoi.form.elements.StringSelect("mailer", "Mailer", data, mailer));
		f.addElement(new sugoi.form.elements.StringInput("smtp_host", "host", host));
		f.addElement(new sugoi.form.elements.StringInput("smtp_port", "port", port));
		f.addElement(new sugoi.form.elements.StringInput("smtp_user", "user", user));
		f.addElement(new sugoi.form.elements.StringInput("smtp_pass", "pass", pass));

		if (f.isValid()) {
			for (k in ["mailer", "smtp_host", "smtp_port", "smtp_user", "smtp_pass"]) {
				sugoi.db.Variable.set(k, f.getValueOf(k));
			}
			throw Ok("/admin/emails", t._("Configuration updated"));
		}

		view.title = t._("Email service configuration");
		view.form = f;
	}
	
	function doVendor(d:haxe.web.Dispatch) {
		d.dispatch(new controller.admin.Vendor());
	}

	// function doPlugins(d:Dispatch) {
	// 	d.dispatch(new controller.admin.Plugins());
	// }

	/**
		export taxo as CSV
	**/
	@tpl("admin/taxo.mtt")
	function doTaxo() {
		var categs = db.TxpCategory.manager.search(true, {orderBy: displayOrder});
		view.categ = categs;

		if (app.params.get("csv") == "1") {
			var data = new Array<Array<String>>();
			for (c in categs) {
				data.push([c.name]);
				for (c2 in c.getSubCategories()) {
					data.push(["", c2.name]);
					for (p in c2.getProducts()) {
						data.push(["", "", Std.string(p.id), p.name]);
					}
				}
			}
			sugoi.tools.Csv.printCsvDataFromStringArray(data, [], "categories.csv");
		}
	}

	@admin
	function doMigrateRights() {
		// populate UserGroup.rights2 field
		for (ua in db.UserGroup.manager.search($rights2 == null, {limit: 5000})) {
			Sys.print(ua.user.getName() + "@" + ua.group.name + " = " + ua.sync() + "<br>");
		}

		Sys.print("Reste encore " + db.UserGroup.manager.count($rights2 == null) + " userGroup à migrer");
	}

	/**
		merge TxpProduct categs
	**/
	@admin @tpl('form.mtt')
	function doMergeCategs() {
		var f = new sugoi.form.Form("merge");
		var data = [];
		for (c in TxpProduct.manager.search(true, {orderBy: name})) {
			data.push({label: c.name + " #" + c.id, value: c.id});
		}
		f.addElement(new sugoi.form.elements.IntSelect("toreplace", "Fusionner", data));
		f.addElement(new sugoi.form.elements.IntSelect("by", "dans", data));
		f.addElement(new sugoi.form.elements.Checkbox("delete", "supprimer la première catégorie", true));

		if (f.isValid()) {
			var oldCateg = TxpProduct.manager.get(f.getValueOf("toreplace"));
			var newCateg = TxpProduct.manager.get(f.getValueOf("by"));

			for (p in db.Product.manager.search($txpProduct == oldCateg, true)) {
				p.txpProduct = newCateg;
				p.update();
			}

			for (p in pro.db.PProduct.manager.search($txpProduct == oldCateg, true)) {
				p.txpProduct = newCateg;
				p.update();
			}

			if (f.getValueOf("delete") == true && oldCateg.countProducts() == 0) {
				oldCateg.delete();
			}

			throw Ok("/admin/taxo", "Catégories fusionnées");
		}

		view.form = f;
		view.title = "Fusion de categories de niveau 3";
	}

	/**
	 *  Display errors logged in DB
	 */
	@tpl("admin/errors.mtt")
	function doErrors(args:{?user:Int, ?like:String, ?empty:Bool}) {
		view.now = Date.now();

		view.u = args.user != null ? db.User.manager.get(args.user, false) : null;
		view.like = args.like != null ? args.like : "";

		var sql = "";
		if (args.user != null)
			sql += " AND uid=" + args.user;
		// if( args.like!=null && args.like != "" ) sql += " AND error like "+sys.db.Manager.cnx.quote("%"+args.like+"%");
		if (args.empty) {
			sys.db.Manager.cnx.request("truncate table Error");
		}

		var errorsStats = sys.db.Manager.cnx.request("select count(id) as c, DATE_FORMAT(date,'%y-%m-%d') as day from Error where date > NOW()- INTERVAL 1 MONTH "
			+ sql
			+ " group by day order by day")
			.results();
		view.errorsStats = errorsStats;

		view.browser = new sugoi.tools.ResultsBrowser(sugoi.db.Error.manager.unsafeCount("SELECT count(*) FROM Error WHERE 1 " + sql), 20,
			function(start, limit) {
				return sugoi.db.Error.manager.unsafeObjects("SELECT * FROM Error WHERE 1 " + sql + " ORDER BY date DESC LIMIT " + start + "," + limit, false);
			});
	}

	@tpl("admin/graph.mtt")
	function doGraph(?key:String, ?month:Int, ?year:Int) {
		if (month == null) {
			var now = Date.now();
			year = now.getFullYear();
			month = now.getMonth();
		}

		if (key == null) {
			// display graphs index
			return;
		}

		var from = new Date(year, month, 1, 0, 0, 0);
		var to = new Date(year, month + 1, 0, 23, 59, 59);

		var data = GraphService.getRange(key, from, to);

		var averageValue = 0.0;
		var total = 0.0;
		var estimatedTotal = 0.0;

		for (d in data)
			total += d.value;
		averageValue = total / data.length;
		estimatedTotal = total + ((31 - data.length) * averageValue);

		view.data = data;
		view.averageValue = Formatting.formatNum(averageValue);
		view.total = Formatting.formatNum(total);
		view.estimatedTotal = Formatting.formatNum(estimatedTotal);
		view.key = key;
		view.year = year;
		view.month = month;
		view.from = from;
		view.to = to;
	}

	@tpl("admin/stats.mtt")
	function doStats(?month:Int, ?year:Int) {
		var now = Date.now();
		if (month == null) {
			year = now.getFullYear();
			month = now.getMonth();
		}
		var from = new Date(year, month, 1, 0, 0, 0);
		var to = new Date(year, month + 1, 0, 23, 59, 59);
		view.year = year;
		view.month = month;
		view.from = from;
		view.to = to;

		view.newVendors = db.Vendor.manager.count($cdate >= from && $cdate < to);
		view.activeVendors = sys.db.Manager.cnx.request("SELECT count(v.id) FROM Vendor v, VendorStats vs where vs.vendorId=v.id and vs.active=1")
			.getIntResult(0);

		view.activeVendorsByType = sys.db.Manager.cnx.request('SELECT count(v.id) as count, vs.type
		FROM Vendor v, VendorStats vs 
		WHERE vs.vendorId=v.id AND active=1
		group by vs.type
		order by type')
			.results();

		view.newVendorsByType = sys.db.Manager.cnx.request('SELECT count(v.id) as count, vs.type
		FROM Vendor v, VendorStats vs 
		WHERE vs.vendorId=v.id AND cdate > "${from.toString()}" and cdate <= "${to.toString()}"
		group by vs.type
		order by type')
			.results();

		view.activeGroups = GroupStats.manager.count($active);
		view.activeUsers = sys.db.Manager.cnx.request('SELECT sum(gs.membersNum) FROM `Group` g, GroupStats gs where gs.groupId=g.id and gs.active=1')
			.getIntResult(0);
		view.newUsers = sys.db.Manager.cnx.request('SELECT count(id) FROM `User` where cdate > "${from.toString()}" and cdate <= "${to.toString()}"')
			.getIntResult(0);
		view.newGroups = db.Group.manager.count($cdate >= from && $cdate < to);
	}

	public static function addUserToGroup(email:String, group:db.Group) {
		var user = db.User.manager.search($email == email).first();
		if (user != null) {
			var usergroup = new db.UserGroup();
			usergroup.user = user;
			usergroup.group = group;
			usergroup.insert();
		}
	}

	/**
		clean datas to prepare a dataset
	**/
	public function doDataset() {
		if (!App.config.DEBUG && App.config.HOST.substr(0, 3) != "pp.") {
			Sys.print("Interdit dans cet environnement");
			return;
		}

		// delete old distribs.
		MultiDistrib.manager.delete($distribStartDate < DateTools.delta(Date.now(), -1000 * 60 * 60 * 24 * 360 * 2));

		// delete old messages
		// db.Message.manager.delete( $date < DateTools.delta(Date.now(),-1000 * 60 * 60 * 24 * 360 * 2) );

		// delete old contracts
		Catalog.manager.delete($endDate < DateTools.delta(Date.now(), -1000 * 60 * 60 * 24 * 360));

		// delete small groups
		for (g in db.Group.manager.all(true)) {
			if (g.getMembersNum() < 30) {
				if (g.name.indexOf("GT") == -1) {
					g.delete();
				}
			}

			if (g.getActiveContracts().length == 0) {
				if (g.name.indexOf("GT") == -1) {
					g.delete();
				}
			}
		}

		// delete cagette pro
		#if plugins
		pro.db.CagettePro.manager.delete($training == true);
		#end

		// delete unlinked vendors
		for (v in db.Vendor.manager.all(true)) {
			if (db.Catalog.manager.select($vendor == v, false) == null) {
				v.delete();
			}
		}
	}

	function doLastCproTest() {
		// cagette pro test par date de creation du cpro
		var vendors = db.Vendor.manager.unsafeObjects("SELECT v.*,cpro.cdate as cprocdate FROM CagettePro cpro, Vendor v WHERE v.id=cpro.vendorId and isTest=1 order by cpro.cdate DESC",
			false);
		Sys.print("<h2>Derniers Cagette Pro test</h2>");
		Sys.print('<p>${vendors.length} producteurs</p>');
		Sys.print('<table class="table"><tr><th>Producteur</th><th>Bloqué</th><th>Inscription</th></tr>');
		for (v in vendors) {
			var cpro = pro.db.CagettePro.getFromVendor(v);
			var blocked = cpro.getUserCompany().exists(uc -> uc.disabled);

			Sys.print('<tr><td><a href="/admin/vendor/view/${v.id}" target="_blank">${v.id} - ${v.name}</a></td>');
			Sys.print('<td>${blocked?"OUI":"NON"}</a></td>');
			Sys.print('<td>${untyped v.cprocdate}</a></td>');
			Sys.print("</tr>");
		}
		Sys.print('</table>');
	}

	function doGroupStats() {
		/*Caractérisation des groupes ( condition : les groupes actifs) :, 
			mode du groupe, 
			nombre de membres, 
			réglage des inscriptions, 
			nombre de produits différents vendus sur un an, 
			nombre de producteurs par type (formés, invités...), 
			bouléen sur utilisation des stocks dans un des catalogues, 
			CA réalisé, 
			nombre de distributions au cours des 12 derniers mois, 
			a activé la gestion des paiements ou pas, 
			modalités de paiement le cas échéant
		 */

		var sql = "SELECT g.*,h.membersNum,h.cproContractNum,h.contractNum";
		sql += " FROM `Group` g LEFT JOIN  GroupStats gs ON g.id=gs.groupId WHERE gs.active=1";
		sql += " ORDER BY g.id ASC";

		var groups = db.Group.manager.unsafeObjects(sql, false);
		var headers = [
			"id", "name", "mode", "membersNum", "inscriptions", "productNum", "vendorNum", "cproCatalogNum", "catalogNum", "useStocks", "turnover23months",
			"distribNum12months", "payments"
		];

		var data = [];
		var now = Date.now();
		for (g in groups) {
			var catalogs = g.getActiveContracts();
			var cids = catalogs.map(c -> c.id);
			var vendors = tools.ObjectListTool.deduplicate(catalogs.map(c -> c.vendor));
			var from = DateTools.delta(now, -1000.0 * 60 * 60 * 24 * 365);
			var to = now;
			var distributions = MultiDistrib.getFromTimeRange(g, from, to);
			// var turnOver = 0.0;
			// for( d in distributions){
			// 	turnOver += d.getTotalIncome();
			// }

			data.push({
				id: g.id,
				name: g.name,
				mode: g.hasShopMode() ? "BOUTIQUE" : "AMAP",
				membersNum: untyped g.membersNum,
				inscriptions: Std.string(g.regOption),
				productNum: db.Product.manager.count($catalogId in cids),
				vendorNum: vendors.length,
				cproCatalogNum: untyped g.cproContractNum,
				catalogNum: untyped g.contractNum,
				useStocks: db.Product.manager.count(($catalogId in cids) && $active == true && $stock > 0) > 0,
				// turnover12months:Math.round(turnOver),
				distribNum12months: distributions.length,
				payments: g.allowedPaymentsType2
			});
		}

		sugoi.tools.Csv.printCsvDataFromObjects(data, headers, "stats_groupes");
		// var t = new sugoi.helper.Table();
		// Sys.print(t.toString(data));
	}

	/**
		edit general messages on homepage
	**/
	@tpl('form.mtt')
	function doMessages() {
		var homeVendorMessage = Variable.get("homeVendorMessage");
		var homeGroupAdminMessage = Variable.get("homeGroupAdminMessage");

		var f = new sugoi.form.Form("msg");
		f.addElement(new sugoi.form.elements.TextArea("homeVendorMessage", "Accueil producteurs", homeVendorMessage));
		f.addElement(new sugoi.form.elements.TextArea("homeGroupAdminMessage", "Accueil admin de groupes", homeGroupAdminMessage));

		if (f.isValid()) {
			Variable.set("homeVendorMessage", f.getValueOf("homeVendorMessage"));
			Variable.set("homeGroupAdminMessage", f.getValueOf("homeGroupAdminMessage"));
			throw Ok("/admin/messages", "Messages mis à jour");
		}

		view.title = "Messages";
		view.form = f;
	}

	function doGroups() {
		for (g in db.Group.manager.all(true)) {
			g.update();
			Sys.println(g.name + "<br/>");
		}
	}

	/*function doTerraLibra(){
		var v = db.Vendor.manager.get(12535,false);
		var catalogs = v.getActiveContracts();
		var groups = catalogs.map(c -> c.group);
		for( g in groups){
			Sys.println("<h2>"+g.name+"</h2>");
			Sys.println("<table border='1'>");
			for( ve in g.getVendors()) {

				var vs = VendorStats.getOrCreate(ve);
				Sys.println('<tr> <td>${ve.id}</td> <td>${ve.name}</td> <td>${vs.type}</td> <td>${vs.shopTurnover12months}€</td></tr>');

			}
			Sys.println("</table>");
		}
	}*/

	@tpl('admin/process.mtt')
	function doProcess() {}
}
