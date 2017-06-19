package test;
import Common;
/**
 * CAGETTE.NET TEST SUITE
 * @author fbarbut
 */
class TestSuite
{

	static function main() {
		
		initDB();
		initDatas();
		
		var r = new haxe.unit.TestRunner();
		r.add(new test.TestOrders());
		r.add(new test.TestReports());
		r.run();
	}
	
	static function initDB(){
		
		var cnx = sys.db.Mysql.connect({
		   host : "localhost",
		   port : null,
		   user : "cagette",
		   pass : "cagette",
		   database : "test",
		   socket : null,
		});
		
		sys.db.Manager.cnx = cnx;
		
		sys.db.Manager.initialize();
	
		//sugoi tables
		createTable(sugoi.db.Cache.manager);
		createTable(sugoi.db.Error.manager);
		createTable(sugoi.db.File.manager);
		createTable(sugoi.db.Session.manager);
		createTable(sugoi.db.Variable.manager);
		
		//cagette
		createTable(db.User.manager);
		createTable(db.Amap.manager);
		createTable(db.UserContract.manager);
		createTable(db.Contract.manager);
		createTable(db.Product.manager);
		createTable(db.Vendor.manager);
		createTable(db.Place.manager);
		createTable(db.Distribution.manager);
		createTable(db.Basket.manager);
	}
	
	static function createTable( m  ){
		if ( sys.db.TableCreate.exists(m) ){
			sys.db.Manager.cnx.request("DROP TABLE "+m.dbInfos().name+";");
		}
		Sys.println("Creating table "+ m.dbInfos().name);
		sys.db.TableCreate.create(m);
		
	}
	
	static function initDatas(){
		
		var f = new db.User();
		f.firstName = "François";
		f.lastName = "Barbut";
		f.email = "francois@alilo.fr";
		f.insert();
		
		var u = new db.User();
		u.firstName = "Seb";
		u.lastName = "Zulke";
		u.email = "sebastien@alilo.fr";
		u.insert();		
		
		initApp(u);
		
		var a = new db.Amap();
		a.name = "AMAP du Jardin public";
		a.contact = f;
		a.insert();
		
		var place = new db.Place();
		place.name = "Place du village";
		place.insert();
		
		var v = new db.Vendor();
		v.name = "La ferme de la Galinette";
		v.insert();
		
		var c = new db.Contract();
		c.name = "Contrat AMAP Légumes";
		c.vendor = v;
		c.amap = a;
		c.type = db.Contract.TYPE_CONSTORDERS;
		c.insert();
		
		var p = new db.Product();
		p.name = "Panier Légumes";
		p.price = 13;
		p.contract = c;
		p.insert();
		
		//varying contract for strawberries with stock mgmt
		var c = new db.Contract();
		c.name = "Commande fruits";
		c.vendor = v;
		c.flags.set(db.Contract.ContractFlags.StockManagement);
		c.type = db.Contract.TYPE_VARORDER;
		c.amap = a;
		c.insert();
		
		var p = new db.Product();
		p.name = "Fraises";
		p.qt = 1;
		p.unitType = Common.UnitType.Kilogram;
		p.price = 10;
		p.organic = true;
		p.contract = c;
		p.stock = 8;
		p.insert();
		
		var p = new db.Product();
		p.name = "Pommes";
		p.qt = 1;
		p.unitType = Common.UnitType.Kilogram;
		p.price = 6;
		p.organic = true;
		p.contract = c;
		p.stock = 12;
		p.insert();
		
		var d = new db.Distribution();
		d.date = new Date(2017, 5, 1, 19, 0, 0);
		d.contract = c;
		d.place = place;
		d.insert();
		
		//second group
		var a = new db.Amap();
		a.name = "Les Locavores affamés";
		a.contact = f;
		a.insert();
		
		var place = new db.Place();
		place.name = "Rue Saucisse";
		place.insert();
		
		var v = new db.Vendor();
		v.name = "La ferme de la courgette enragée";
		v.insert();
		
		var c = new db.Contract();
		c.name = "Commande Legumes";
		c.vendor = v;
		c.amap = a;
		c.type = db.Contract.TYPE_VARORDER;
		c.insert();
		
		var p = new db.Product();
		p.name = "Courgettes";
		p.qt = 1;
		p.unitType = Common.UnitType.Kilogram;
		p.price = 3.5;
		p.organic = true;
		p.contract = c;
		p.insert();
		
		var p = new db.Product();
		p.name = "Carottes";
		p.qt = 1;
		p.unitType = Common.UnitType.Kilogram;
		p.price = 2.8;
		p.contract = c;
		p.insert();
		
		var d = new db.Distribution();
		d.date = new Date(2017, 5, 1, 19, 0, 0);
		d.contract = c;
		d.place = place;
		d.insert();
		
		
	}
	
	static function initApp(u:db.User){
		//setup App
		var app = App.current = new App();
		app.eventDispatcher = new hxevents.Dispatcher<Event>();
		app.plugins = [];
		//internal plugins
		app.plugins.push(new plugin.Tutorial());
		
		//optionnal plugins
		#if plugins
		//app.plugins.push( new hosted.HostedPlugIn() );				
		//app.plugins.push( new pro.ProPlugIn() );		
		//app.plugins.push( new connector.ConnectorPlugIn() );				
		//app.plugins.push( new pro.LemonwayEC() );
		//plugins.push( new who.WhoPlugIn() );
		#end
		
		App.current.user = u;
		App.current.view = new View();
	}
}

