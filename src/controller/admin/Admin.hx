package controller.admin;
import Common;
import db.BufferedJsonMail;
import db.Catalog;
import db.MultiDistrib;
import db.TxpProduct;
import haxe.web.Dispatch;
import hosted.db.GroupStats;
import mangopay.db.MangopayGroupPayOut;
import pro.db.VendorStats;
import service.GraphService;
import sugoi.Web;
import sugoi.db.Variable;
import sys.FileSystem;
import tools.ObjectListTool;
import tools.Timeframe;

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

	@tpl('admin/basket.mtt')
	function doBasket(basket:db.Basket){
		view.basket = basket;
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
	
	function doVendor(d:haxe.web.Dispatch) {
		d.dispatch(new controller.admin.Vendor());
	}

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

	/*function doVendorNum(){
		//nbre de vendor actifs dans des groupes qui ont eu des payout mangopay en octobre
		var vendorsNum = 0;
		var payoutNum = 0;
		var vendors = [];
		var mds = db.MultiDistrib.manager.search($distribStartDate >= Date.fromString("2021-10-01 00:00:00") && $distribStartDate < Date.fromString("2021-11-01 00:00:00"));
		Sys.print('<h3>${mds.length} distribs</h3>');
		for( md in mds ){

			var payout = MangopayGroupPayOut.get(md);
			if(payout==null) continue;
			payoutNum++;

			Sys.print('distrib ${md.id} of ${md.group.name} : ${md.distribStartDate.toString()}<br/>');
			var distribVendors = md.getVendors();
			vendorsNum += distribVendors.length;
			for( v in distribVendors) vendors.push(v);
		}
		Sys.print('estimation à ${vendorsNum} payouts pour chaque prod à chaque distrib<br/>');
		Sys.print('${payoutNum} payouts mgp');
		vendors = ObjectListTool.deduplicate(vendors);
		Sys.print('${vendors.length} vendors actifs');

	}*/


	/**
		Stats sur les groupes actifs
	**/
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
				payments: g.allowedPaymentsType
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

	@tpl("admin/group/default.mtt")
	function doGroups() {

		var groups = [];
		var total = 0;
		var totalActive = 0;
		var defaultType = "all";

		// form
		var f = new sugoi.form.Form("groups");
		f.method = GET;
		f.addElement(new sugoi.form.elements.StringInput("groupName", "Nom du groupe"));
		var data = [
			{label: "Tous", value: "all"},
			{label: "Mode marché", value: "shopMode"},
			{label: "Mode AMAP", value: "CSAMode"},
			
		];
		f.addElement(new sugoi.form.elements.StringSelect("type", "Type de groupe", data, defaultType, true, ""));
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
			{label: "CSV", value: "csv"}
		];
		f.addElement(new sugoi.form.elements.StringSelect("output", "Sortie", data, "table", true, ""));

		var sql_select = "SELECT g.*,gs.active,gs.membersNum,gs.contractNum,p.name as pname, p.address1,p.address2,p.zipCode,p.country,p.city";
		var sql_where_or = [];
		var sql_where_and = [];
		var sql_end = "ORDER BY g.id ASC";
		var sql_from = ["`Group` g LEFT JOIN  GroupStats gs ON g.id=gs.groupId LEFT JOIN Place p ON g.placeId=p.id"];

		if (f.isValid()) {
			// filter by zip codes
			var zipCodes:Array<Int> = f.getValueOf("zipCodes") != null ? f.getValueOf("zipCodes").split(",").map(Std.parseInt) : [];
			if (zipCodes.length > 0) {
				for (zipCode in zipCodes) {
					var min = zipCode * 1000;
					var max = zipCode * 1000 + 999;
					sql_where_or.push('(p.zipCode>=$min and p.zipCode<=$max)');
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
				var type = f.getValueOf("type");
				switch(type){
					case "marketMode","shopMode" : sql_where_and.push("g.flags&2 != 0");
					case "CSAMode" : sql_where_and.push("g.flags&2 = 0");
					default : throw "unknown type";
				}
			}

			// country
			sql_where_and.push('p.country="${f.getValueOf("country")}"');

			//group name
			if(f.getValueOf("groupName")!=null){
				sql_where_and.push('g.name like "%${f.getValueOf("groupName")}%"');
			}

		} else {
			// default settings
			sql_where_and.push('active=1');
			// sql_where_and.push('type=${Type.enumIndex(defaultType)}');
			sql_where_and.push('p.country="FR"');
		}

		// QUERY
		if (sql_where_and.length == 0)
			sql_where_and.push("true");
		if (sql_where_or.length == 0)
			sql_where_or.push("true");
		var sql = '$sql_select FROM ${sql_from.join(", ")} WHERE (${sql_where_or.join(" OR ")}) AND ${sql_where_and.join(" AND ")} $sql_end';
		for (g in db.Group.manager.unsafeObjects(sql, false)) {
			groups.push(g);
		}

		view.form = f;

		for (g in groups) {
			if (untyped g.active) totalActive++;
			total++;
		}

		// TOTALS
		total = groups.length;
		view.total = total;
		view.groups = groups;
		view.totalActive = totalActive;

		switch (f.getValueOf("output")) {
			case "table":

			case "csv":
				var headers = [
					"id", "name","mode","placeName", "address1", "address2", "zipCode", "city", "active", "url",
					"contactName","contactEmail","contactPhone","membersNum","contractNum"
				];
				var data = [];
				for (g in groups) {
					var active:Bool = untyped g.active;
					var contact = g.contact;
					data.push({
						id: g.id,
						name: g.name,
						mode : g.hasShopMode() ? "Marché" : "AMAP",
						placeName : untyped g.pname,
						address1 : untyped g.address1,
						address2 : untyped g.address2,
						zipCode : untyped g.zipCode,
						city : untyped g.city,
						active: switch (active) {
							case true: "OUI";
							case false: "NON";
						},
						url:"https://app.cagette.net/group/"+g.id,
						contactName : contact!=null ? contact.getName() : "",
						contactEmail: contact!=null ? contact.email : "",
						contactPhone: contact!=null ? contact.phone : "",
						membersNum : untyped g.membersNum,
						contractNum : untyped g.contractNum			
					});
				}

				sugoi.tools.Csv.printCsvDataFromObjects(data, headers, "groupes");
		}
	}
	
	@tpl('admin/news.mtt')
	function doNews() {}

	function doTestMails(?args:{tpl:String}){

		//list existing mail templates
		var dirs = [
			Web.getCwd()+"/../lang/master/tpl/mail/",
			Web.getCwd()+"/../lang/master/tpl/plugin/pro/who/mail/",
			Web.getCwd()+"/../lang/master/tpl/plugin/pro/mail/"
		];
		var tpls = [];

		for( dir in dirs){
			var files = FileSystem.readDirectory(dir);
			for(file in files) tpls.push(dir+file);	
		}

		Sys.print("<ul>");
		for(tpl in tpls){
			var i = tpl.indexOf("/lang/master/tpl/") + "/lang/master/tpl/".length;
			tpl = tpl.substr(i);
			Sys.print('<li><a href="/admin/testMails?tpl=$tpl">$tpl</a></li>');
		} 
		Sys.print("</ul>");
		
		var group = db.Group.manager.select(true,false);
		var user = db.User.manager.select(true,false);
		var d = db.Distribution.manager.select(true,false);
		var contract = d.catalog;
		var catalog = d.catalog;


		if(args!=null && args.tpl!=null){
			var res = App.current.processTemplate(args.tpl, {
				group:group,
				user:user,
				d:d,
				catalog:catalog,
				contract:contract,
				text:"Lorem Ipsum"
			} );
			Sys.print(res);
		}

	}

	public function doUpdate(){

		for(g in db.Group.manager.search(true,false)){

			var gs = hosted.db.GroupStats.getOrCreate(g.id,true);
			gs.updateStats();
			Sys.print(g.name+" #"+g.id+" <br/>");

		}

	}

	@tpl('admin/settings.mtt')
	function doSettings(){}
}
