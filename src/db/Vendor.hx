package db;
import sugoi.form.validators.EmailValidator;
import sys.db.Object;
import sys.db.Types;
import Common;

enum DisabledReason{
	IncompleteLegalInfos; //incomplete legal infos
	NotCompliantWithPolicy; //not compliant with policy (charte des producteurs)
}

/**
	infos from https://entreprise.data.gouv.fr/api/sirene/v3/etablissements/
**/
typedef SiretInfos = {
	date_creation:String,
	activite_principale:String,//code NAF
	geo_adresse:String,//adresse postale complete
	libelle_commune:String,
	libelle_voie:String,
	code_postal:String,
	type_voie:String,
	latitude:Float,
	longitude:Float,
	unite_legale:{
		categorie_juridique:Int,//code juridique de niveau III
	}
}

enum VendorBetaFlags{
	Cagette2;		//BETA Cagette 2.0
}

/**
 * Vendor (farmer/producer/vendor)
 */
class Vendor extends Object
{
	public var id : SId;
	public var name : SString<128>;	//Business name 
	public var peopleName : SNull<SString<128>>; //Business owner(s) name
	
	//public var legalStatus : SNull<SEnum<LegalStatus>>;
	@hideInForms public var profession : SNull<SInt>;

	public var email:SNull<SString<128>>;
	public var phone:SNull<SString<19>>;
		
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	public var country:SNull<SString<64>>;
	
	public var desc : SNull<SText>;
	@hideInForms public var cdate : SNull<SDateTime>; // date de création

	//legal infos
	@hideInForms public var companyNumber : SNull<SString<128>>; //SIRET
	@hideInForms public var vatNumber : SNull<SString<128>>; //VAT number
	@hideInForms public var legalStatus : SNull<SInt>; //statut juridique
	@hideInForms public var companyCapital : SNull<SInt>; //capital social
	@hideInForms public var siretInfos : SNull<SData<SiretInfos>>; //infos from SIRET API
	@hideInForms public var activityCode:SNull<SString<8>>;//code NAF (NAFRev2)
	
	public var vendorPolicy:SBool; //charte producteurs
	@hideInForms public var tosVersion: SNull<SInt>; //CGV version checked
	
	public var linkText:SNull<SString<256>>;
	public var linkUrl:SNull<SString<256>>;

	@hideInForms public var directory 	: SBool;
	@hideInForms public var longDesc 	: SNull<SText>;
	@hideInForms public var offCagette 	: SNull<SText>;
	
	@hideInForms @:relation(imageId) 	public var image : SNull<sugoi.db.File>;
	@hideInForms @:relation(userId) 	public var user : SNull<db.User>; //owner of this vendor (when not cpro)
	
	@hideInForms public var status : SNull<SString<32>>; //temporaire , pour le dédoublonnage
	@hideInForms public var disabled : SNull<SEnum<DisabledReason>>; // vendor is disabled
	
	@hideInForms public var isTest : SBool; //cpro test account

	@hideInForms public var lat:SNull<SFloat>;
	@hideInForms public var lng:SNull<SFloat>;

	@hideInForms public var betaFlags:SFlags<VendorBetaFlags>;

	public function new() 
	{
		super();
		directory = true;
		cdate = Date.now();

	}

	public function checkIsolate(){
	
		if(this.betaFlags.has(VendorBetaFlags.Cagette2)){

			var cpro = pro.db.CagettePro.getCurrentCagettePro();

			var noCagette2Groups = cpro.getGroups().filter(v->!v.hasCagette2());
			if ( noCagette2Groups.length>0 ){
				var name = noCagette2Groups.map(v -> v.name).join(", ");
				throw sugoi.ControllerAction.ControllerAction.ErrorAction("/user/choose",'Le producteur "${this.name}" a l\'option Cagette2 activée et ne peut pas fonctionner avec des groupes qui n\'ont pas activé cette option ($name). Contactez nous sur <b>support@cagette.net</b> pour régler le problème.');
			}
			
		} 
	}

	public function hasCagette2(){
		return betaFlags.has(VendorBetaFlags.Cagette2);
	}
	
	override function toString() {
		return name;
	}

	public function getContracts(){
		return db.Catalog.manager.search($vendor == this,{orderBy:-startDate}, false);
	}

	public function getActiveContracts(){
		var now = Date.now();
		return db.Catalog.manager.search($vendor == this && $startDate < now && $endDate > now ,{orderBy:-startDate}, false);
	}

	public function getImage():String{
		if (image == null) {
			return "/img/vendor.png";
		}else {
			return App.current.view.file(image);
		}
	}

	public function getImages(){

		var out = {
			logo:null,
			portrait:null,
			banner:null,
			farm1:null,				
			farm2:null,				
			farm3:null,				
			farm4:null,				
		};

		var files = sugoi.db.EntityFile.getByEntity("vendor",this.id);
		for( f in files ){
			switch(f.documentType){				
				case "logo" 	: out.logo 		= f.file;
				case "portrait" : out.portrait 	= f.file;
				case "banner" 	: out.banner 	= f.file;
				case "farm1" 	: out.farm1 	= f.file;
				case "farm2" 	: out.farm2 	= f.file;
				case "farm3" 	: out.farm3 	= f.file;
				case "farm4" 	: out.farm4 	= f.file;
			}
		}

		if(out.logo==null) out.logo = this.image;

		return out;
	}

	public function getInfos(?withImages=false):VendorInfos{

		var file = function(f){
			return if(f==null)  null else App.current.view.file(f);
		}
		var vendor = this;
		var out : VendorInfos = {
			id : id,
			name : vendor.name,
			profession:null,
			email:vendor.email,
			offCagette:offCagette,
			image : file(vendor.image),
			images : cast {},
			address1: vendor.address1,
			address2: vendor.address2,
			zipCode : vendor.zipCode,
			city : vendor.city,
			linkText:vendor.linkText,
			linkUrl:vendor.linkUrl,
			desc:vendor.desc,
			longDesc:vendor.longDesc,
			vendorPage: vendor.getLink(),
			companyNumber: vendor.companyNumber,
			legalStatus: vendor.getLegalStatus(true)
		};

		if(this.profession!=null){
			out.profession = Lambda.find(service.VendorService.getVendorProfessions(),function(x) return x.id==this.profession).name;
		}

		if(withImages){
			var images = getImages();
			out.images.logo = file(images.logo);
			out.images.portrait = file(images.portrait);
			out.images.banner = file(images.banner);
			out.images.farm1 = file(images.farm1);
			out.images.farm2 = file(images.farm2);
			out.images.farm3 = file(images.farm3);
			out.images.farm4 = file(images.farm4);
		}
		return out;
	}

	public function getGroups():Array<db.Group>{
		var contracts = getActiveContracts();
		var groups = Lambda.map(contracts,function(c) return c.group);
		return tools.ObjectListTool.deduplicate(groups);
	}

	public static function get(email:String,status:String){
		return manager.select($email==email && $status==status,false);
	}

	#if plugins
	public function getCpro(){
		return pro.db.CagettePro.getFromVendor(this);
	}
	#end	
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 				=> "Nom de votre ferme/entreprise",
			"peopleName" 		=> "Nom de l'exploitant(e)",	
			"desc" 				=> t._("Description"),
			"email" 			=> t._("Email pro"),
			"legalStatus"		=> t._("Legal status"),
			"phone" 			=> t._("Phone"),
			"address1" 			=> t._("Address 1"),
			"address2" 			=> t._("Address 2"),
			"zipCode" 			=> t._("Zip code"),
			"city" 				=> t._("City"),			
			"linkText" 			=> t._("Link text"),			
			"linkUrl" 			=> t._("Link URL"),			
			"companyNumber" 	=> "Numéro SIRET (14 chiffres)",	
			"vendorPolicy"		=> "Ce producteur est conforme à la <a href=\"https://www.cagette.net/charte-producteurs\" target=\"_blank\">Charte Producteurs Cagette.net</a>"
		];
	}


	public function getLink():String{		
		var permalink = sugoi.db.Permalink.getByEntity(this.id,"vendor");
		return permalink==null ? "/p/pro/public/vendor/"+id : "/"+permalink.link;		
	}

	public function getAddress(){
		var str = new StringBuf();
		if(address1!=null) str.add(address1);
		if(address2!=null) str.add(", "+address2);
		if(zipCode!=null) str.add(", "+zipCode);
		if(city!=null) str.add(" "+city);
		return str.toString();
	}

	public function getAddressFromSiretInfos(){
		if(siretInfos==null) return null;
		
		var addr = {
			address1:"",
			address2:"",
			zipCode:siretInfos.code_postal,
			city:siretInfos.libelle_commune,
			lat:siretInfos.latitude,
			lng:siretInfos.longitude
		}

		//find address1
		var a = [];
		for( k in ["numero_voie","type_voie","libelle_voie"] ){
			var v = Reflect.field(siretInfos,k);
			if(v!=null && v!=""){
				a.push(v);
			}
		}
		addr.address1 = a.join(" ");

		return addr;
	}

	public function isDisabled(){
		return disabled!=null;
	}

	public function getDisabledReason():Null<String>{
		return switch(this.disabled){
			case null : null;
			case DisabledReason.IncompleteLegalInfos : "Informations légales incomplètes. Complétez vos informations légales pour débloquer le compte. (SIRET,capital social,numéro de TVA)";
			case DisabledReason.NotCompliantWithPolicy : "Producteur incompatible avec la charte producteur de Cagette.net";
		};
	}

	/**
		like "GAEC au capital de 5000€"
	**/
	public function getLegalStatus(?full=true){

		var str = "";

		//legal status
		for ( c in service.VendorService.getLegalStatuses()){
			if(Std.string(c.id) == Std.string(this.legalStatus)) {
				str += c.name;
				break;
			}
		}
		if(str=="") str = "Statut juridique inconnu";

		if(full){
			//capital
			if(this.companyCapital!=null) str += " au capital de "+companyCapital+" €";

			//VAT
			if(vatNumber!=null){
				str += ". Numéro de TVA : "+vatNumber;
			}else{
				str += ". Entreprise non assujetie à TVA";
			}
		}
		
		return str;
	}

	function check(){
		if(this.email==null){
			throw new tink.core.Error("Vous devez obligatoirement saisir un email pour ce producteur.");
		}

		if(!EmailValidator.check(this.email) ) {
			throw new tink.core.Error("Email invalide.");
		}

		//disable if missing legal infos
		#if plugins
		var cpro = pro.db.CagettePro.getFromVendor(this);
		if(companyNumber==null){
			if(cpro!=null && cpro.training){
				//do not disable training accounts
			}else{
				disabled = DisabledReason.IncompleteLegalInfos;
			}			
		}
		#end
	}

	override function insert(){
		check();
		super.insert();
	}
	
	override function update(){
		check();
		super.update();
	}
}