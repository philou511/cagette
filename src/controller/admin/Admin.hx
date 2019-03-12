package controller.admin;
import haxe.web.Dispatch;
import Common;

class Admin extends Controller {
	
	public function new() {
		super();
		view.category = 'admin';
		
		//trigger a "Nav" event
		var nav = new Array<Link>();
		var e = Nav(nav,"admin");
		app.event(e);
		view.nav = e.getParameters()[0];
		
	}

	@tpl("admin/default.mtt")
	function doDefault() {
		view.now = Date.now();
	}
	
	@tpl("admin/emails.mtt")
	function doEmails() {
		var browse = function(index:Int, limit:Int) {
			return sugoi.db.BufferedMail.manager.search($sdate==null,{limit:[index,limit],orderBy:-cdate},false);
		}

		var count = sugoi.db.BufferedMail.manager.count($sdate==null);
		view.browser = new sugoi.tools.ResultsBrowser(count,10,browse);
		view.num = count;

	}

	@tpl("form.mtt")
	function doSmtp() {
		
		var f = new sugoi.form.Form("emails");
		var data = [
			{label:"SMTP",value:"smtp"},
			{label:"Mandrill API",value:"mandrill"},
		];
		
		var mailer = sugoi.db.Variable.get("mailer")==null ? "smtp" : sugoi.db.Variable.get("mailer");
		var host = sugoi.db.Variable.get("smtp_host")==null ? App.config.get("smtp_host") : sugoi.db.Variable.get("smtp_host");
		var port = sugoi.db.Variable.get("smtp_port")==null ? App.config.get("smtp_port") : sugoi.db.Variable.get("smtp_port");
		var user = sugoi.db.Variable.get("smtp_user")==null ? App.config.get("smtp_user") : sugoi.db.Variable.get("smtp_user");
		var pass = sugoi.db.Variable.get("smtp_pass")==null ? App.config.get("smtp_pass") : sugoi.db.Variable.get("smtp_pass");
		
		
		f.addElement(new sugoi.form.elements.StringSelect("mailer", "Mailer", data,  mailer ));
		f.addElement(new sugoi.form.elements.StringInput("smtp_host", "host", host));
		f.addElement(new sugoi.form.elements.StringInput("smtp_port", "port", port));
		f.addElement(new sugoi.form.elements.StringInput("smtp_user", "user", user));
		f.addElement(new sugoi.form.elements.StringInput("smtp_pass", "pass", pass));
		
		
		if (f.isValid()){
			for ( k in ["mailer","smtp_host","smtp_port","smtp_user","smtp_pass"]){
				sugoi.db.Variable.set(k, f.getValueOf(k));
			}
			throw Ok("/admin/emails", t._("Configuration updated") );
			
		}
		
		view.title = t._("Email service configuration");
		view.form = f;
	}
	
	function doPlugins(d:Dispatch) {
		d.dispatch(new controller.admin.Plugins());
	}
	
	
	@tpl("admin/taxo.mtt")
	function doTaxo(){
		
		view.categ = db.TxpCategory.manager.search(true,{orderBy:displayOrder});
		
	}
	
	/**
	 *  Display errors logged in DB
	 */
	@tpl("admin/errors.mtt")
	function doErrors( args:{?user: Int, ?like: String, ?empty:Bool} ) {
		view.now = Date.now();

		view.u = args.user!=null ? db.User.manager.get(args.user,false) : null;
		view.like = args.like!=null ? args.like : "";

		var sql = "";
		if( args.user!=null ) sql += " AND uid="+args.user;
		//if( args.like!=null && args.like != "" ) sql += " AND error like "+sys.db.Manager.cnx.quote("%"+args.like+"%");
		if (args.empty) {
			sys.db.Manager.cnx.request("truncate table Error");
		}

		var errorsStats = sys.db.Manager.cnx.request("select count(id) as c, DATE_FORMAT(date,'%y-%m-%d') as day from Error where date > NOW()- INTERVAL 1 MONTH "+sql+" group by day order by day").results();
		view.errorsStats = errorsStats;

		view.browser = new sugoi.tools.ResultsBrowser(
			sugoi.db.Error.manager.unsafeCount("SELECT count(*) FROM Error WHERE 1 "+sql),
			20,
			function(start, limit) {  return sugoi.db.Error.manager.unsafeObjects("SELECT * FROM Error WHERE 1 "+sql+" ORDER BY date DESC LIMIT "+start+","+limit,false); }
		);
	}

	@tpl("admin/graph.mtt")
	function doGraph(?key:String,?year:Int,?month:Int){


		var from = new Date(year,month,1,0,0,0);
		var to = new Date(year,month+1,0,23,59,59);

		if(app.params.exists("recompute")){

			switch(key){
				case "basket":
					for( d in 1...to.getDate()){
						var _from = new Date(year,month,d,0,0,0);
						var _to = new Date(year,month,d,23,59,59);
						var value = db.Basket.manager.count($cdate>=_from && $cdate<=_to);
						var g = db.Graph.record(key,value, _from );
						// trace(value,_from,g);
						
					}


			}

		}

		var data = db.Graph.getRange(key,from,to);
		view.data = data;
		view.from = from;
		view.to = to;
		view.key = key;

		var averageValue = 0.0;
		var total = 0.0;
		for( d in data) total += d.value;
		averageValue = total/data.length;
		view.total = total;
		view.averageValue = averageValue;




	}
	
	function doFixDistribValidation() {

		Sys.println("===== Liste des distributions ayant été re-validées ====<br>");

		//Get the current group
		var group = app.user.amap;
		//Get all the contracts for this given group
		var contractIds = Lambda.map(group.getContracts(),function(x) return x.id);
		//Get all the validated distributions for this given group
		var validatedDistribs = db.Distribution.manager.search( ($contractId in contractIds) && $validated == true, {orderBy:date}, false);
		for (distrib in validatedDistribs){

			service.PaymentService.validateDistribution(distrib);
			Sys.println(distrib.toString() + "<br>");

		}

		Sys.println("===== Fin de la liste ====");

	}

	function doCheckDistribValidation() {

		Sys.println("===== Liste des distributions validées ayant des opérations/paiements non validés ====<br>");

		//Get the current group
		var group = app.user.amap;
		//Get all the contracts for this given group
		var contractIds = Lambda.map(group.getContracts(),function(x) return x.id);
		//Get all the validated distributions for this given group
		var validatedDistribs = db.Distribution.manager.search( ($contractId in contractIds) && $validated == true, {orderBy:date}, false);
		for (distrib in validatedDistribs){

			for (user in distrib.getUsers()){
		
				var basket = db.Basket.get(user, distrib.place, distrib.date);
				if (basket == null || basket.isValidated()) continue;
		
				for (order in basket.getOrders()){
					if (!order.paid) {
						Sys.println(order.distribution.toString() + "<br>");
						Sys.println(order.toString() + "<br>");
					}		
				}

				var operation = basket.getOrderOperation(false);
				if (operation != null){
					
					if (operation.pending) {
						Sys.println(distrib.toString() + "<br>");
						Sys.println(operation.toString() + "<br>");
					}
				
					for ( payment in basket.getPaymentsOperations()){

						if (payment.pending){
							Sys.println(distrib.toString() + "<br>");
							Sys.println(payment.toString() + "<br>");
						}
					}	
				}

			}
		}

		Sys.println("===== Fin de la liste ====");

	}

}

