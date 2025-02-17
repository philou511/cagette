import Common;
import GitMacros;
import db.User;
import thx.semver.Version;

class App extends sugoi.BaseApp {

	public static var current : App = null;
	public static var t : sugoi.i18n.translator.ITranslator;
	public static var config = sugoi.BaseApp.config;
	public static var eventDispatcher : hxevents.Dispatcher<Event>;	
	public static var plugins : Array<sugoi.plugin.IPlugIn>;
	

	public var breadcrumb : Array<Link>;
	public static var theme	: Theme;
	public static var settings	: Settings;

	/**
	 * Version management
	 * @doc https://github.com/fponticelli/thx.semver
	 */ 
	public static var VERSION = ([0,14]  : Version)/*.withPre(GitMacros.getGitShortSHA(), GitMacros.getGitCommitDate())*/;
	
	public function new(){
		super();

		breadcrumb = [];

		if (App.config.DEBUG) {
			this.headers.set('Access-Control-Allow-Origin', "*");
			this.headers.set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
		}
	}
	
	public static function main() {
		
		App.t = sugoi.form.Form.translator = new sugoi.i18n.translator.TMap(getTranslationArray(), "fr");
		sugoi.BaseApp.main();
	}
	
	/**
	 * Init plugins and event dispatcher just before launching the app
	 */
	override public function mainLoop() {
		super.mainLoop();
	}

	override function init(){
		var i = super.init();

		if(eventDispatcher==null){
			eventDispatcher = new hxevents.Dispatcher<Event>();
			plugins = [];
			
			//internal plugins
			// plugins.push(new plugin.Tutorial());
			
			//optionnal plugins
			#if plugins
			plugins.push( new hosted.HostedPlugIn() );				
			plugins.push( new pro.ProPlugIn() );		
			plugins.push( new connector.ConnectorPlugIn() );				
			plugins.push( new mangopay.MangopayPlugin() );
			plugins.push( new who.WhoPlugIn() );
			#end

			setTheme();
			setSettings();
		}

		return i;

	}

	public function setTheme(){
		var cagetteTheme: Theme = {
			id: "cagette",
			name: "Cagette.net",
			url: "https://www.cagette.net",
			supportEmail: "support@cagette.net",			
			footer: {
				bloc1: '<a href="https://www.cagette.net" target="_blank">
							<img src="/theme/cagette/logo.png" alt="logo Cagette.net" style="width:166px;"/>
						</a>',
				bloc2: '<ul>
							<li>								
								<a href="https://www.cagette.net/comment-ca-marche/" target="_blank">Comment ça marche ?</a> 
							</li>
							<li> 
								<a href="/charte/" target="_blank">Charte producteurs</a> 
							</li>
							<li> 
								<a href="https://wiki.cagette.net" target="_blank">Documentation</a> 
							</li>
							<li>
								<a href="https://www.facebook.com/groups/EntraideCagette/" target="_blank">Groupe Facebook</a> 
							</li>
							<li>
								<a href="http://www.cagette.net/producteurs" target="_blank">Information producteurs</a> 
							</li>												
							<li>
								<a href="/cgu" target="_blank">Conditions générales d\'utilisation</a> 
							</li>
							<li>
								<a href="/cgv" target="_blank">Conditions générales de vente</a> 
							</li>	
							<li>
								<a href="/mgp" target="_blank">C.G.U Mangopay</a> 
							</li>
						</ul>',
				bloc3: 'SOUTENEZ-NOUS
						<ul>
							<li>
								<a href="http://www.lilo.org/fr/cagette-net/?utm_source=cagette-net" target="_blank">Notre page sur Lilo.org</a>
							</li>
						</ul>
						<!-- PAYPAL !-->
						<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top" style="margin-top:12px;">
							<input type="hidden" name="cmd" value="_s-xclick"/>
							<input type="hidden" name="hosted_button_id" value="S9KT7FQS7P622"/>
							<input type="image" src="https://www.paypalobjects.com/fr_FR/FR/i/btn/btn_donate_LG.gif" border="0" name="submit" alt="PayPal, le réflexe sécurité pour payer en ligne"/>
							<img alt="" border="0" src="https://www.paypalobjects.com/fr_FR/i/scr/pixel.gif" width="1" height="1"/>
						</form>',
				bloc4: 'SUIVEZ-NOUS
						<ul class="cagsocialmedia">
							<li class="cagfb">
								<a title="Facebook" href="https://www.facebook.com/cagette" target="_blank"> <i class="icon icon-facebook"></i></a>	
							</li>
							<li class="cagtwitter">
								<a title="Twitter" href="https://twitter.com/Cagettenet" target="_blank"> <i class="icon icon-twitter"></i></a> 
							</li>
							<li class="cagyoutube">
								<a title="Youtube" href="https://www.youtube.com/channel/UC3cvGxAUrbN9oSZmr1oZEaw" target="_blank"> <i class="icon icon-youtube"></i></a> 						
							</li>
							<li style="background-color:#333;">
								<a title="Github" href="https://github.com/bablukid/cagette" target="_blank"> <i class="icon icon-github"></i></a> 						
							</li>
						</ul>

						<br/>
						Cagette.net est réalisé <br/>
						par la <a href="https://www.alilo.fr" "target="_blank">SCOP Alilo</a>'
			},
			email:{
				senderEmail : 'noreply@mj.cagette.net',
				brandedEmailLayoutFooter:  '<p>Cagette.net - ALILO SCOP, 4 impasse Durban, 33000 Bordeaux</p>
				<div style="display: flex; justify-content: center; align-items: center;">
					<a href="https://www.cagette.net" target="_blank" rel="noreferrer noopener notrack" class="bold-green" style="text-decoration:none !important; padding: 8px; display: flex; align-items: center;">
						<img src="http://'+ App.config.HOST+'/img/emails/website.png" alt="Site web" height="25" style="width:auto!important; height:25px!important; vertical-align:middle" valign="middle" width="auto"/>Site web
					</a>
					<a href="https://www.facebook.com/cagette" target="_blank" rel="noreferrer noopener notrack" class="bold-green" style="text-decoration:none !important; padding: 8px; display: flex; align-items: center;">
						<img src="http://'+ App.config.HOST+'/img/emails/facebook.png" alt="Facebook" height="25" style="width:auto!important; height:25px!important; vertical-align:middle" valign="middle" width="auto"/>Facebook
					</a>
					<a href="https://www.youtube.com/channel/UC3cvGxAUrbN9oSZmr1oZEaw" target="_blank" rel="noreferrer noopener notrack" class="bold-green" style="text-decoration:none !important; padding: 8px; display: flex; align-items: center;">
						<img src="http://'+ App.config.HOST+'/img/emails/youtube.png" alt="YouTube" height="25" style="width:auto!important; height:25px!important; vertical-align:middle" valign="middle" width="auto"/>YouTube
					</a>
				</div>'
			},
			terms: {
				termsOfServiceLink: "https://www.cagette.net/wp-content/uploads/2020/11/cgu-.pdf",
				termsOfSaleLink: "https://www.cagette.net/wp-content/uploads/2020/11/cgv.pdf",
				platformTermsLink: "",
			}
			
		}
		var res = this.cnx.request("SELECT value FROM Variable WHERE name='whiteLabel'").results();
		var whiteLabelStringified = res.first()==null ? null : res.first().value;
		App.theme = whiteLabelStringified != null ? haxe.Json.parse(whiteLabelStringified) : cagetteTheme;
	}

	public function setSettings(){
		var res = this.cnx.request("SELECT value FROM Variable WHERE name='settings'").results();
		var settingsStringified = res.first()==null ? null : res.first().value;
		App.settings = settingsStringified != null ? haxe.Json.parse(settingsStringified) : {};
	}

	/**
		Theme is stored as static var, thus it's inited only one time at app startup
	**/
	public function getTheme():Theme{
		return App.theme;
	}

	/**
		Settings is stored as static var, thus it's inited only one time at app startup
	**/
	public function getSettings():Settings{
		return App.settings;
	}
	
	public function getCurrentGroup(){		
		if (session == null) return null;
		if (session.data == null ) return null;
		var a = session.data.amapId;
		if (a == null) {
			return null;
		}else {			
			return db.Group.manager.get(a,false);
		}
	}
	
	override function beforeDispatch() {
		
		//send "current page" event
		event( Page(this.uri) );
		
		super.beforeDispatch();
	}
	
	public function getPlugin(name:String):sugoi.plugin.IPlugIn {
		for (p in plugins) {
			if (p.getName() == name) return p;
		}
		return null;
	}
	
	public static function log(t:Dynamic) {
		if(App.config.DEBUG) {
			neko.Web.logMessage(Std.string(t)); //write in Apache error log
			#if weblog
			Weblog.log(t); //write en Weblog console (https://lib.haxe.org/p/weblog/)
			#end
		}
	}
	
	public function event(e:Event) {
		if(e==null) return null;
		App.eventDispatcher.dispatch(e);
		return e;
	}
	
	/**
	 * Translate DB objects fields in forms
	 */
	public static function getTranslationArray() {
		//var t = sugoi.i18n.Locale.texts;
		var out = new Map<String,String>();

		out.set("firstName2", "Prénom du conjoint");
		out.set("lastName2", "Nom du conjoint");
		out.set("email2", "e-mail du conjoint");
		out.set("zipCode", "code postal");
		out.set("city", "commune");
		out.set("phone", "téléphone");
		out.set("phone2", "téléphone du conjoint");


		out.set("select", "sélectionnez");
		out.set("contract", "Contrat");
		out.set("place", "Lieu");
		out.set("name", "Nom");
		out.set("cdate", "Date d'entrée dans le groupe");
		out.set("quantity", "Quantité");
		out.set("paid", "Payé");
		out.set("user2", "(facultatif) partagé avec ");
		out.set("product", "Produit");
		out.set("user", "Adhérent");
		out.set("txtIntro", "Texte de présentation du groupe");
		out.set("txtHome", "Texte en page d'accueil pour les adhérents connectés");
		out.set("txtDistrib", "Texte à faire figurer sur les listes d'émargement lors des distributions");
		out.set("extUrl", "URL du site du groupe.");
		
		out.set("startDate", "Date de début");
		out.set("endDate", "Date de fin");
		
		out.set("orderStartDate", "Date ouverture des commandes");
		out.set("orderEndDate", "Date fermeture des commandes");	
		out.set("openingHour", "Heure d'ouverture");	
		out.set("closingHour", "Heure de fermeture");	
		
		out.set("date", "Date de distribution");	
		out.set("active", "actif");	
		
		out.set("contact", "Reponsable");
		out.set("vendor", "Producteur");
		out.set("text", "Texte");
	
		out.set("flags", "Options");
		out.set("HasEmailNotif4h", "Recevoir des notifications par email 4h avant les distributions");
		out.set("HasEmailNotif24h", "Recevoir des notifications par email 24h avant les distributions");
		out.set("HasEmailNotifOuverture", "Recevoir des notifications par email pour l'ouverture des commandes");

		out.set("HasMembership", "Gestion des adhésions");
		out.set("DayOfWeek", "Jour de la semaine");
		out.set("Monday", "Lundi");
		out.set("Tuesday", "Mardi");
		out.set("Wednesday", "Mercredi");
		out.set("Thursday", "Jeudi");
		out.set("Friday", "Vendredi");
		out.set("Saturday", "Samedi");
		out.set("Sunday", "Dimanche");
		out.set("cycleType", "Récurrence");
		out.set("Weekly", "hebdomadaire");
		out.set("Monthly", "mensuelle");
		out.set("BiWeekly", "toutes les deux semaines");
		out.set("TriWeekly", "toutes les 3 semaines");
		out.set("price", "prix TTC");
		out.set("uname", "Nom");
		out.set("pname", "Produit");
		out.set("organic", "Agriculture biologique");
		
		out.set("membershipRenewalDate", "Adhésions : Date de renouvellement");
		out.set("membershipPrice", "Adhésions : Coût de l'adhésion");
		out.set("UsersCanOrder", "Les membres peuvent saisir leur commande en ligne");
		out.set("StockManagement", "Gestion des stocks");
		out.set("contact", "Responsable");
		out.set("PercentageOnOrders", "Ajouter des frais au pourcentage de la commande");
		out.set("percentageValue", "Pourcentage des frais");
		out.set("percentageName", "Libellé pour ces frais");
		out.set("fees", "frais");
		out.set("AmapAdmin", "Administrateur du groupe");
		out.set("Membership", "Accès à la gestion des membres");
		out.set("Messages", "Accès à la messagerie");
		out.set("vat", "TVA");
		out.set("desc", "Description");
		
		//group options
		out.set("ShopMode", "Mode Marché");
		out.set("CustomizedCategories", "Catégories personnalisées");
		out.set("HidePhone", "Masquer le téléphone du responsable sur la page publique");
		out.set("PhoneRequired", "Saisie du numéro de téléphone obligatoire");
		out.set("AddressRequired", "Saisie de l'adresse obligatoire");
		out.set("CagetteNetwork", "Lister ce groupe sur la carte et sur les annuaires partenaires");
		out.set("HasPayments", "Gestion des paiements");
		out.set("Show3rdCategoryLevel", "Classer les produits de la boutique par catégorie de troisième niveau");	

		out.set("Cagette2", "Cagette 2.0");	
	

		out.set("ref", "Référence");
		out.set("linkText", "Intitulé du lien");
		out.set("linkUrl", "URL du lien");
		
		//group type
		out.set("Amap", "AMAP");
		out.set("GroupedOrders", 	"Groupement d'achat");
		out.set("ProducerDrive", 	"En direct d'un collectif de producteurs");
		out.set("FarmShop", 		"En direct d'un producteur");
		
		out.set("regOption", 	"Inscription de nouveaux membres");
		out.set("Closed", 		"Fermé : L'administrateur ajoute les nouveaux membres");
		out.set("WaitingList", 	"Liste d'attente");
		out.set("Open", 		"Ouvert : tout le monde peut s'inscrire");
		out.set("Full", 		"Complet : Le groupe n'accepte plus de nouveaux membres");

		out.set("Soletrader"	, "Micro-entreprise");
		out.set("Organization"	, "Association");
		out.set("Business"		, "Société");		
		
		out.set("unitType", "Unité");
		out.set("qt", "Quantité");
		out.set("Unit", "Pièce");
		out.set("Kilogram", "Kilogrammes");
		out.set("Gram", "Grammes");
		out.set("Litre", "Litres");		
		out.set("Centilitre", "Centilitres");		
		out.set("Millilitre", "Millilitres");		
		out.set("htPrice", "Prix H.T");
		out.set("amount", "Montant");
		out.set("percent", "Pourcentage");
		out.set("pinned", "Mets en avant les produits");
		
		out.set("byMember", "Par adhérent");
		out.set("byProduct", "Par produit");

		//stock strategy
		out.set("ByProduct"	, "Par produit (produits vrac, stockés sans conditionnement)");
		out.set("ByOffer"	, "Par offre (produits stockés déja conditionnés)");
				
		out.set("variablePrice", "Prix variable selon pesée");	
		out.set("VATAmount", "Montant TVA");	
		out.set("VATRate", "Taux TVA");
	
		return out;
	}
	
	public function populateAmapMembers() {		
		return user.getGroup().getMembersFormElementData();
	}
	
	public static function getMailer():sugoi.mail.IMailer {
		
		var mailer : sugoi.mail.IMailer = new mail.BufferedJsonMailer();		

		/*if(App.config.DEBUG || App.config.HOST=="pp.cagette.net" || App.config.HOST=="localhost"){ 

			//Dev env : emails are written to tmp folder
			mailer = new sugoi.mail.DebugMailer();
		}else{
			
			if (sugoi.db.Variable.get("mailer") == null){
				var msg = sugoi.i18n.Locale.texts._("Please configure the email settings in a <href='/admin/emails'>this section</a>");
				throw sugoi.ControllerAction.ErrorAction("/",msg);
			}

			if (sugoi.db.Variable.get("mailer") == "mandrill"){		
				//Buffered emails with Mandrill
				untyped mailer.defineFinalMailer("mandrill");		
			}else{
				//Buffered emails with SMTP
				untyped mailer.defineFinalMailer("smtp");
			}
		}*/
		return mailer;
	}
	
	/**
	 * Send an email
	 */
	public static function sendMail(m:sugoi.mail.Mail, ?group:db.Group, ?sender:{email: String, ?name: String,?userId: Int}){
		
		if (group == null) group = App.current.user == null ? null:App.current.user.getGroup();
		if (group != null) m.setSender(group.contact == null ? App.current.getTheme().email.senderEmail : group.contact.email, group.name);
		if (sender != null) m.setSender(sender.email, sender.name, sender.userId);
		current.event(SendEmail(m));
		var params = group==null ? null : {remoteId:group.id};
		getMailer().send(m,params,function(o){});		
	}
	
	public static function quickMail(to:String, subject:String, html:String,?group:db.Group){
		var e = new sugoi.mail.Mail();		
		e.setSubject(subject);
		e.setRecipient(to);			
		e.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);				
		var html = App.current.processTemplate("mail/message.mtt", {text:html,group:group});		
		e.setHtmlBody(html);
		App.sendMail(e, group);
	}
	
	/**
		process a template and returns the generated string
		(used for emails)
	**/
	public function processTemplate(tpl:String, ctx:Dynamic):String {
		
		//inject usefull vars in view
		Reflect.setField(ctx, 'HOST', App.config.HOST);
		Reflect.setField(ctx, 'theme', this.getTheme());
		Reflect.setField(ctx, 'hDate', date -> return Formatting.hDate(date) );

		ctx._ = App.current.view._;
		ctx.__ = App.current.view.__;
		
		var tpl = loadTemplate(tpl);
		var html = tpl.execute(ctx);	
		#if php
		if ( html.substr(0, 4) == "null") html = html.substr(4);
		#end
		return html;
	}
	
	
	
}
