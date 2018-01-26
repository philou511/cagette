package controller.admin;
import haxe.web.Dispatch;
import Common;

class Admin extends Controller {
	
	public function new() {
		super();
		view.category = 'admin';
		
		//lance un event pour demander aux plugins si ils veulent ajouter un item dans la nav
		var nav = new Array<Link>();
		var e = Nav(nav,"admin");
		app.event(e);
		view.nav = e.getParameters()[0];
		
	}

	@tpl("admin/default.mtt")
	function doDefault() {
		
	}
	
	@tpl("form.mtt")
	function doEmails() {
		
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
		
		view.categ = db.TxpCategory.manager.all();
		
		
		
	}
	
	
	
	
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

		var errorsStats = sys.db.Manager.cnx.request("select count(id) as c, DATE_FORMAT(date,'%y-%c-%d') as day from Error where date > NOW()- INTERVAL 1 MONTH "+sql+" group by day order by day").results();
		view.errorsStats = errorsStats;

		view.browser = new sugoi.tools.ResultsBrowser(
			sugoi.db.Error.manager.unsafeCount("SELECT count(*) FROM Error WHERE 1 "+sql),
			20,
			function(start, limit) {  return sugoi.db.Error.manager.unsafeObjects("SELECT * FROM Error WHERE 1 "+sql+" ORDER BY date DESC LIMIT "+start+","+limit,false); }
		);
	}
	
	
	
}

