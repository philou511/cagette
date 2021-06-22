package pro.controller;

import sugoi.tools.TransactionWrappedTask;
import crm.CrmService;
import sugoi.form.elements.Html;
import sugoi.form.elements.StringInput;
import pro.db.VendorStats;
import sugoi.form.elements.CheckboxGroup;
import sugoi.form.elements.StringSelect;
import sugoi.Web;
import haxe.Json;
import sugoi.apis.linux.Curl;
import sugoi.form.elements.Checkbox;
import db.Vendor;
import pro.db.PUserCompany;
import form.CagetteForm;
import service.VendorService;

class Signup extends controller.Controller
{

	/**
		need to login as a standard user
	**/
	@tpl("plugin/pro/signup/default.mtt")
	public function doDefault(/*key:String*/){
		/*if(key!="cak2j6d6e8i9u7q45p6o54iden") {
			throw Error("/","Lien invalide");
		}*/
			
		if(app.user!=null){
			throw Redirect("/p/pro/signup/farmInfos");
		}
	}

	@logged
	@tpl('form.mtt')
	public function doFarmInfos(){
		App.current.session.data.amapId = null;
		
		//checks
		//has access to a cpro
		var uc = PUserCompany.manager.search($user ==app.user);
		if( uc.length>0){
			throw Error("/","Vous avez déjà accès à un compte Cagette Pro : "+uc.map(c -> return c.company.vendor.name).join(', '));
		}

		//has same mail than a vendor
		var vendor : db.Vendor = Vendor.manager.select($email == app.user.email,true);
		if( vendor!=null ){

			//is this vendor cpro
			if(vendor.getCpro()!=null){
				throw Error("/","Vous avez déjà accès à un compte Cagette Pro");
			}

		}else{
			//brand new vendor
			vendor = new db.Vendor();
			vendor.country = "FR";
		}

		var form = VendorService.getForm(vendor,true);
		form.removeElementByName("address1");
		form.removeElementByName("address2");
		form.removeElementByName("desc");
		form.removeElementByName("linkText");
		form.removeElementByName("linkUrl");

		form.getElement("email").value = app.user.email;
		form.getElement("phone").value = app.user.phone;

		//will be completed by SIRET API
		form.removeElementByName("zipCode");
		form.removeElementByName("city");

		form.addElement(new sugoi.form.elements.Html("html","Si votre numéro SIRET n'est pas reconnu, contactez-nous sur <a href='mailto:support@cagette.net'>cet email</a>"));
		
		form.addElement(new Checkbox("isagri","Je certifie être agriculteur ou artisan",false,true));
		form.addElement(new Checkbox("cgv","J'accepte les <a href='/cgv' target='_blank'>conditions générales de vente</a> pour les producteurs",false,true));
		form.addElement(new Checkbox("formation","J’ai pris note que mon compte sera activé une fois le financement de ma formation validé lors d’un rendez-vous téléphonique avec un conseiller.",false,true));
		
		
		// form.addElement(new Checkbox("conseiller","Je dois prendre rdv tel (5 à 10 mn)  avec un conseiller producteur pour qu’il active mon compte",false,true));
		/*var data = [
			{label:"Recommandation d'un producteur",value:"RecoProducteur"},
			{label:"Par une initiative qui utilise déjà Cagette.net",value:"RecoInitiative"},
			{label:"ADEAR",value:"ADEAR"},
			{label:"CIVAM",value:"CIVAM"},
			{label:"Réseau Bio (GAB,FNAB,Interbio...)",value:"ReseauBio"},
			{label:"Autre structure qui m'accompagne",value:"AutreStructure"},
			{label:"Presse",value:"Presse"},
			{label:"Recherche sur Internet",value:"RechercheInternet"},
			{label:"Facebook",value:"Facebook"},
			{label:"Newsletter Cagette.net",value:"NewsletterCagette"},
			{label:"Collectivité locale",value:"collectivite"},
			
		];
		form.addElement(new CheckboxGroup("referer","Comment avez-vous connu Cagette.net et le kit d'urgence ?",data,null,true));*/


		if (form.isValid()) {

			var task = new TransactionWrappedTask("vendorRegister");
			task.setTask(function(){

				if(form.getValueOf("isagri")!=true || form.getValueOf("cgv")!=true || form.getValueOf("formation")!=true ){
					throw Error(sugoi.Web.getURI(),"Vous devez cocher toutes les cases.");
				}
	
				if(form.getValueOf("country")!="FR"){
					throw Error(sugoi.Web.getURI(),"La création de compte est limitée pour l'instant à des entreprises basées en France.");
				}

				if(vendor.id != null){
					vendor.lock();
				}
				try{
					vendor = service.VendorService.update(vendor,form.getDatasAsObject());
				}catch(e:tink.core.Error){
					throw Error(sugoi.Web.getURI(),e.message);
				}			
	
				form.toSpod(vendor);
				vendor.isTest = true;
				vendor.tosVersion = sugoi.db.Variable.getInt('termsOfSaleVersion');
	
				if(vendor.id==null){
					vendor.insert();
				}else{
					vendor.update();
				}
				
				var cpro = new pro.db.CagettePro();
				cpro.vendor = vendor;
				cpro.insert();
	
				//disabled by default
				var userCompany = pro.db.PUserCompany.make(app.user,cpro);
				userCompany.disabled = true;
				userCompany.update();
	
				var stat = VendorStats.updateStats(vendor);
				// stat.referer = (form.getValueOf("referer"):Array<String>).join("|");
				// stat.update();
			});
			task.printLog = false;
			task.execute();

			var task = new TransactionWrappedTask("crmSync");
			task.setTask(function(){
				//sync to CRM 
				CrmService.syncToHubspot(vendor);
				CrmService.syncToSiB(app.user,true,"vendor_register");
				
			});
			task.printLog = false;
			task.execute(true);
			
			throw Ok('/','Félicitations votre compte vient d\'être créé.');
		}
		
		
		view.form = form;
		view.title = "Création de compte Cagette Pro";
		view.text = "<b>Bonjour "+app.user.firstName+"</b>, remplissez ce formulaire afin de créer votre compte producteur Cagette Pro.<br/>Certaines de ces informations seront visibles par vos clients. Vous pourrez les modifier par la suite.";

	}



	/*@admin
	function doTest(){
		var vendor = db.Vendor.manager.get(4997,false);

		CrmService.syncToHubspot(vendor);
		CrmService.syncToSiB(app.user,true,"vendor_register");
	}*/
	
	
}