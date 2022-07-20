package service;

import sugoi.form.elements.Checkbox;
import pro.db.CagettePro;
import sugoi.form.elements.Input.InputType;
import sugoi.form.elements.IntInput;
import sugoi.form.validators.EmailValidator;
import tink.core.Error;

typedef VendorDto = {
	name:String,
	email:String,
	linkUrl:String,
	companyNumber:String,
	country:String,
	// ?legalStatus:Int,//0 société, 1 entr. individuelle, 2 asso, 3 particulier

}

class VendorService{

	public static var PROFESSIONS:Array<{id:Int,name:String}>; //cache

	public function new(){}

	/**
		Get vendors accounts linked to a user account
	**/
	public static function getCagetteProFromUser(user:db.User):Array<CagettePro>{
		//get vendors linked to this account
		//var vendors = Lambda.array( db.Vendor.manager.search($user==user,false) );
		// var vendors = [];
		#if plugins
		// var vendors2 = Lambda.array(Lambda.map(pro.db.PUserCompany.getCompanies(user),function(c) return c.vendor));
		// vendors = vendors2.concat(vendors);
		// vendors = tools.ObjectListTool.deduplicate(vendors);
		return pro.db.PUserCompany.getCompanies(user);
		#end
		// return vendors;
	}


	/**
		Search vendors.
	**/
	public static function findVendors(search:{?name:String,?email:String,?geoloc:Bool,?profession:Int,?fromLat:Float,?fromLng:Float}){
		var vendors = [];
		var names = [];
		var where = [];
		if(search.name!=null){
			for( n in search.name.split(" ")){
				n = n.toLowerCase();
				if(Lambda.has(["le","la","les","du","de","l'","a","à","au","en","sur","qui","ferme","GAEC","EARL","SCEA","jardin","jardins"],n)) continue;
				if(Lambda.has(["create","delete","drop","select","count","truncate"],n)) continue; //no SQL injection !
			
				names.push(n);
			}
			where.push('(' + names.map(n -> 'name LIKE "%$n%"').join(' OR ') + ')');
		}
		
		//search by mail
		// if(search.email!=null){
		// 	where.push('email LIKE "${search.email}"');
		// }

		//search by profession
		if(search.profession!=null){
			where.push('(profession = ${search.profession} OR production2 = ${search.profession} OR production3 = ${search.profession})');
		}
		
		var selectDist = '';
		var orderBy = "";

		if(search.geoloc && search.fromLat!=null){
			orderBy = "ORDER BY dist ASC";
			selectDist = ',SQRT(POW(lat-${search.fromLat},2) + POW(lng-${search.fromLng},2)) as dist';
			where.push("lat is not null");
		}

		//search for each term
		vendors = Lambda.array(db.Vendor.manager.unsafeObjects('SELECT * $selectDist FROM Vendor WHERE ${where.join(' AND ')} $orderBy LIMIT 30',false));

		// vendors = tools.ObjectListTool.deduplicate(vendors);

		#if plugins
		//cpro first
		for( v in vendors.copy() ){
			var cpro = v.getCpro();
			if( cpro != null){				
				if(cpro.offer==Training) vendors.remove(v);				
			} 			
		}
		#end

		return vendors;
	}


	/**
		Create a vendor
	**/
	public static function create(data:VendorDto):db.Vendor{

		//already exists ?
		var vendors = db.Vendor.manager.search($email==data.email,false).array();
		#if plugins
		for( v in vendors.copy()){
			//remove training pro accounts
			var cpro = pro.db.CagettePro.getFromVendor(v);
			if(cpro!=null && cpro.offer==Training) vendors.remove(v);
		}
		#end
		if(vendors.length>0) throw new Error("Un producteur est déjà référencé avec cet email dans notre base de données");

		var vendor = update(new db.Vendor(),cast data);

		vendor.insert();
		return vendor;
	}

	public static function get(email:String,status:String){
		return db.Vendor.manager.select($email==email && $status==status,false);
	}

	public static function getForm(vendor:db.Vendor,?legalInfos=true):sugoi.form.Form {
		var t = sugoi.i18n.Locale.texts;
		var form = form.CagetteForm.fromSpod(vendor);
		
		//country
		form.removeElementByName("country");
		var country = vendor.country==null ? "FR" : vendor.country.toUpperCase();
		form.addElement(new sugoi.form.elements.StringSelect('country',t._("Country"),db.Place.getCountries(),country,true));
		
		//profession
		var data = sugoi.form.ListData.fromSpod(service.VendorService.getVendorProfessions());
		form.addElement(new sugoi.form.elements.IntSelect('profession',"Profession",data,vendor.profession,true),4);
		form.addElement(new sugoi.form.elements.IntSelect('production2',"Profession 2",data,vendor.production2,false),5);
		form.addElement(new sugoi.form.elements.IntSelect('production3',"Profession 3",data,vendor.production3,false),6);

		//email is required
		form.getElement("email").required = true;

		if(legalInfos){
			form.addElement(new sugoi.form.elements.Html("html","<h4>Informations légales obligatoires</h4>"));
			
			form.addElement(new sugoi.form.elements.Checkbox('callApi',"Utiliser l'API SIRENE pour remplir les données",true));

			form.addElement(new sugoi.form.elements.StringInput("companyNumber","Numéro SIRET (14 chiffres) ou numéro RNA pour les associations.",vendor.companyNumber,true));
			form.addElement(new sugoi.form.elements.StringInput("vatNumber","Numéro de TVA (si assujeti)",vendor.vatNumber,false));
			form.addElement(new sugoi.form.elements.IntInput("companyCapital","Capital social en € (sauf pour associations et entreprises individuelles)",vendor.companyCapital,false));
			
			var data = service.VendorService.getActivityCodes().map(x -> {label:x.id+" - "+x.name,value:x.id});
			form.addElement(new sugoi.form.elements.StringSelect('activityCode',"Code NAF",data,vendor.activityCode.split(".").join(""),false));

			var data = getLegalStatuses().map(x -> {label:x.id+" - "+x.name,value:x.id});
			form.addElement(new sugoi.form.elements.IntSelect("legalStatus","Statut juridique",data,vendor.legalStatus));
		}
		
		return form;
	}

	/**
		update a vendor
	**/
	public static function update(vendor:db.Vendor,data:VendorDto,?legalInfos=true){

		//apply changes
		for( f in Reflect.fields(data)){
			var v = Reflect.field(data,f);
			Reflect.setProperty(vendor,f,v);
		}

		var callApi:Bool = untyped data.callApi;

		if(data.linkUrl!=null && data.linkUrl.indexOf("http://")==-1 && data.linkUrl.indexOf("https://")==-1){
			vendor.linkUrl = "http://"+data.linkUrl;
		}

		//email
		if( vendor.email==null ) throw new Error("Vous devez définir un email pour ce producteur.");
		if( !EmailValidator.check(vendor.email) ) throw new Error("Email invalide.");

		//desc
		if( vendor.desc!=null && vendor.desc.length>1000) throw  new Error("Merci de saisir une description de moins de 1000 caractères");

		//asssociation
		/*if(legalInfos && data.legalStatus==2){

			var rna = ~/[^\d]/g.replace(data.companyNumber,"");//remove non numbers
			if(rna=="" || rna==null) throw new Error("Le numéro RNA est requis.");
			var sameNumber = db.Vendor.manager.search($companyNumber==rna).array();
			if( !App.config.DEBUG && sameNumber.length>0 && sameNumber[0].id!=vendor.id){
				throw new Error("Il y a déjà une association enregistrée avec ce numéro RNA");			
			}
			vendor.companyNumber = rna;
			vendor.legalStatus = 9220;//association déclarée
		}*/
	

		//check SIRET if french and not association && not particulier
		if(callApi){
			//https://entreprise.data.gouv.fr/api/sirene/v3/etablissements/82902831500010
			var c = new sugoi.apis.linux.Curl();
			var siret = ~/[^\d]/g.replace(data.companyNumber,"");//remove non numbers
			if(siret=="" || siret==null) throw new Error("Le numéro SIRET est requis.");
			var sameSiret = db.Vendor.manager.search($companyNumber==siret).array();
			
			var raw = c.call("GET","https://entreprise.data.gouv.fr/api/sirene/v3/etablissements/"+siret);
			// trace("https://entreprise.data.gouv.fr/api/sirene/v3/etablissements/"+siret);
			var res;
			try{
				res = haxe.Json.parse(raw);
			}catch(e:Dynamic){
				throw new Error('Erreur de parsing JSON : "$raw"');
			}
			
			if(res.message!=null){
				throw new Error("Erreur avec le numéro SIRET ("+res.message+"). Si votre numéro SIRET est correct mais non reconnu, contactez nous sur "+App.current.getTheme().supportEmail);
			}else if(res.etablissement.statut_diffusion=="N"){
				throw new Error("Ce numéro SIRET est non diffusible, vous devez saisir les infos légales manuellement");
			}else{
				vendor.companyNumber = siret;
				var siretInfos = res.etablissement;
				
				//take adress from siretInfos
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
		
				if(addr!=null && addr.city!=null){
					vendor.address1 = addr.address1;
					vendor.zipCode = addr.zipCode;
					vendor.city = addr.city;
					if(vendor.lat==null){
						vendor.lat = addr.lat;
						vendor.lng = addr.lng;
					}
				}
				
				vendor.activityCode = res.etablissement.activite_principale;
				vendor.legalStatus = res.etablissement.unite_legale.categorie_juridique;
				
				//do not authorize duplicate companyNumber if not Coop legalStatus
				var coopStatuses = [5560,5460,5558];
				if( !App.config.DEBUG && sameSiret.length>0 && sameSiret[0].id!=vendor.id && coopStatuses.find(s-> Std.string(s)==Std.string(vendor.legalStatus))==null ){
					throw new Error("Il y a déjà un producteur enregistré avec ce numéro SIRET");			
				}
			}
		}		

		//unban if banned
		if(vendor.companyNumber!=null && vendor.disabled==db.Vendor.DisabledReason.IncompleteLegalInfos){
			vendor.disabled = null;
			App.current.session.addMessage("Merci d'avoir saisi vos informations légales. Le compte a été débloqué.",false);
		}

		//training account MUST have "(formation)" in its name
		var cpro = vendor.getCpro();
		if(cpro!=null && cpro.offer==Training){
			if(vendor.name.indexOf("(formation)")==-1){
				vendor.name += " (formation)";
			}
		}

		return vendor;
	}

	/**
		Loads vendors professions from json
	**/
	public static function getVendorProfessions():Array<{id:Int,name:String}>{
		if( PROFESSIONS!=null ) return PROFESSIONS;
		var filePath = sugoi.Web.getCwd()+"../data/vendorProfessions.json";
		var json = haxe.Json.parse(sys.io.File.getContent(filePath));
		PROFESSIONS = json.professions;
		return json.professions;
	}

	public static function getActivityCodes():Array<{id:String,name:String}>{
		var filePath = sugoi.Web.getCwd()+"../data/codesNAF.json";
		var json:Array<{id:String,name:String}> = haxe.Json.parse(sys.io.File.getContent(filePath));
		json.sort((a,b)-> Std.parseInt(a.id)-Std.parseInt(b.id));
		return json;
	}

	public static function getLegalStatuses():Array<{id:Int,name:String}>{
		var filePath = sugoi.Web.getCwd()+"../data/categoriesJuridiques.json";
		var json:Array<{id:Int,name:String}> = haxe.Json.parse(sys.io.File.getContent(filePath));
		json.sort((a,b)-> a.id-b.id);
		return json;
	}

	public static function getUnlinkedCatalogs(company:pro.db.CagettePro){

		var remoteCatalogs = connector.db.RemoteCatalog.manager.search($remoteCatalogId in company.getCatalogs().map(x -> x.id), false); 
		var vendor = company.vendor;
		var catalogs = vendor.getActiveContracts().array();
		catalogs = catalogs.filter( c -> c.group.hasShopMode() );//remove CSA group
		catalogs = catalogs.filter( c -> {
			return remoteCatalogs.find( rc -> rc.getContract().id==c.id) == null;
		}); //remove linked catalogs
		return catalogs;
	}

}