package db;
import Common;
import sugoi.form.ListData.FormData;
import sys.db.Object;
import sys.db.Types;

using tools.DateTool;

enum GroupFlags {
	__HasMembership; 	//@deprecated membership management  
	ShopMode; 		//shop mode / CSA mode
	HasPayments; 	//manage payments and user balance
	__ComputeMargin;	//compute margin instead of percentage
	CagetteNetwork; //register in cagette.net groups directory
	__CustomizedCategories;  //the custom categories are not used anymore, use product taxonomy instead
	HidePhone; 		//Hide manager phone on group public page
	PhoneRequired;	//phone number of members is required for this group	
	AddressRequired;//address required for delivery at home
	__UnUsed;
	Show3rdCategoryLevel; //Show the third category level in the shop (Only for shop V2)
}

enum BetaFlags{
	___ShopV2; 		//shop V2 @deprecated
	Cagette2;		//BETA Cagette 2.0
}

//user registration options
enum RegOption{
	Closed;
	WaitingList; 
	Open;
	Full;
}

enum GroupType{
	Amap; 			//CSA / GASAP / AMAP
	GroupedOrders; 	//groupements d'achat
	ProducerDrive;	//drive de producteurs
	FarmShop;		//vente à la ferme
}


@:enum
abstract GroupDisabledReason(String) {
  var BLOCKED_BY_ADMIN = "BLOCKED_BY_ADMIN";
  var MOVED = "MOVED";
}

/**
 * Group
 */
class Group extends Object
{
	public var id : SId;
	public var name : SString<64>;
	
	@formPopulate("getMembersFormElementData")
	@:relation(userId)
	public var contact : SNull<User>;	
	
	public var txtIntro:SNull<SText>; 	//introduction de l'amap
	public var txtHome:SNull<SText>; 	//texte accueil adhérents
	public var txtDistrib:SNull<SText>; //sur liste d'emargement
	
	public var extUrl : SNull<SString<64>>;   //lien sur logo du groupe

	@hideInForms public var membershipRenewalDate : SNull<SDate>;
	@hideInForms public var membershipFee : SNull<STinyInt>;
	
	@hideInForms public var vatRates : SNull<SSmallText>;
	
	//options and flags
	public var flags:SFlags<GroupFlags>;
	public var betaFlags:SFlags<BetaFlags>;
	@hideInForms public var hasMembership:SBool;

	@hideInForms public var groupType:SNull<SEnum<GroupType>>;
	
	@hideInForms @:relation(imageId)
	public var image : SNull<sugoi.db.File>;
	
	@hideInForms public var cdate : SDateTime;
	@hideInForms @:relation(placeId) public var mainPlace : SNull<db.Place>;
	
	public var regOption : SEnum<RegOption>;
	
	@hideInForms public var currency:SString<12>; //name or symbol.
	@hideInForms public var currencyCode:SString<3>; //https://fr.wikipedia.org/wiki/ISO_4217

	@formPopulate("getMembersFormElementData") @:relation(legalReprId) public var legalRepresentative : SNull<db.User>;
	
	//payments
	@hideInForms public var allowedPaymentsType:SNull<SSmallText>; //Array<String>
	@hideInForms public var checkOrder:SNull<SString<64>>;
	@hideInForms public var IBAN:SNull<SString<40>>;
	@hideInForms public var allowMoneyPotWithNegativeBalance:SNull<SBool>;

	//Volunteers for duty periods
	@hideInForms public var volunteersMailDaysBeforeDutyPeriod: STinyInt;
	@hideInForms public var volunteersMailContent: SText;
	@hideInForms public var vacantVolunteerRolesMailDaysBeforeDutyPeriod: STinyInt;
	@hideInForms public var daysBeforeDutyPeriodsOpen: SInt;
	@hideInForms public var alertMailContent: SText;
	
	@hideInForms public var disabled : SNull<SString<32>>; //Mysql enum GroupDisabledReason

	public function new() 
	{
		super();
		flags = cast 0;
		flags.set(CagetteNetwork);
		flags.set(ShopMode);
		betaFlags = cast 0;
		setVatRates([{label:"TVA alimentaire",value:5.5},{label:"TVA standard",value:20}]);
		cdate = Date.now();
		regOption = Open;
		currency = "€";
		currencyCode = "EUR";
		checkOrder = "";
		
		//duty periods props
		daysBeforeDutyPeriodsOpen = 60;
		volunteersMailContent = "<b>Rappel : Vous êtes inscrit·e à la permanence du [DATE_DISTRIBUTION],</b><br/>
		Lieu de distribution : [LIEU_DISTRIBUTION]<br/>
		<br/>
		Voici la liste des bénévoles inscrits :<br/>
		[LISTE_BENEVOLES]<br/>";

		volunteersMailDaysBeforeDutyPeriod = 4;
		alertMailContent = "Nous avons besoin de <b>bénévoles pour la permanence du [DATE_DISTRIBUTION]</b><br/>
		Lieu de distribution : [LIEU_DISTRIBUTION]<br/>
		Les roles suivants sont à pourvoir :<br/>
		[ROLES_MANQUANTS]<br/>
		Cliquez sur \"calendrier des permanences\" pour vous inscrire !";
		vacantVolunteerRolesMailDaysBeforeDutyPeriod = 7;
		
	}

	/**
		vérifie que le groupe est bien dans un ilot/isolat cagette 2
	**/
	public function checkIsolate(){
	
		if(this.betaFlags.has(BetaFlags.Cagette2)){
			var noCagette2Vendors = getVendors().filter(v->!v.betaFlags.has(db.Vendor.VendorBetaFlags.Cagette2));
			if ( noCagette2Vendors.length>0 ){
				var name = noCagette2Vendors.map(v -> v.name).join(", ");
				throw sugoi.ControllerAction.ControllerAction.ErrorAction("/user/choose",'Le groupe "${this.name}" a l\'option Cagette2 activée et ne peut pas fonctionner avec des producteurs qui n\'ont pas activé cette option ($name). Contactez nous sur <b>'+App.current.getTheme().supportEmail+'</b> pour régler le problème.');
			}
			
		} 
	}

	public function hasCagette2(){
		return betaFlags.has(BetaFlags.Cagette2);
	}
	
	
	/**
	 * find the most common delivery place
	 */
	public function getMainPlace() {
	
		if (mainPlace != null && Std.random(100) != 0) {
			return mainPlace;
		}else {
			this.lock();
			
			var places = getPlaces();
			
			//just 1 place
			if (places.length == 1) {				
				this.mainPlace = places.first();
				this.update();
				return this.mainPlace;
			}
			
			//no places !
			if (places.length == 0) return null;
			
			var pids = Lambda.map(places, function(x) return x.id);
			
			var res = sys.db.Manager.cnx.request("select placeId,count(placeId) as top from Distribution where placeId IN ("+pids.join(",")+") group by placeId order by top desc").results();
			var res = res.first();
			var pid :Int = null;
			
			if (res == null){
				pid = this.getPlaces().first().id;
			}else{
				pid = Std.parseInt(res.placeId);	
			}
			
			if (pid != 0 && pid != null) {
				var p = db.Place.manager.get(pid, false);
				this.mainPlace = p;
				this.update();
				return p;
			}else {
				return null;	
			}
		}
	}
	
	public function hasShopMode() {
		if(flags==null) return true;
		return flags.has(ShopMode);
	}
	
	public function canExposePhone() {
 		return !flags.has(HidePhone);
 	}
	
	public function hasPayments(){		
		//CSA group cannot have global payment option enabled
		return flags != null && flags.has(HasPayments) && flags.has(ShopMode);
	}
	
	/*public function hasTaxonomy(){
		return flags != null && !flags.has(CustomizedCategories);
	}*/
	
	public function hasPhoneRequired(){
		return flags != null && flags.has(PhoneRequired);
	}

	/**
	 * Renvoie la liste des contrats actifs
	 * @param	large=false
	 */
	public function getActiveContracts(?large=false) {
		return db.Catalog.getActiveContracts(this, large, false);
	}
	
	public function getContracts() {
		return db.Catalog.manager.search($group == this, false);
	}
	
	/**
	 * récupere les produits des contracts actifs
	 */
	public function getProducts() {
		var contracts = db.Catalog.getActiveContracts(App.current.user.getGroup(),false,false);
		return Product.manager.search( $catalogId in Lambda.map(contracts, function(c) return c.id),{orderBy:name}, false);
	}
	
	/**
	 * get next multi-deliveries 
	 */
	public function getDeliveries(?limit=3){
		var out = new Map<String,db.Distribution>();
		for ( c in getActiveContracts()){
			for ( d in c.getDistribs(true,3)){
				out.set(d.getKey(), d);
			}
		}
		
		var out = Lambda.array(out);
		out.sort(function(a, b){
			return Math.round(a.date.getTime() / 1000) - Math.round(b.date.getTime() / 1000);
		});
		return out.slice(0,limit);
	}
	
	public function getPlaces() {
		return db.Place.manager.search($group == this, false);
	}
	
	/**
		Get vendors with contracts in this group
	**/
	public function getVendors():Array<db.Vendor> {
		var vendors = Lambda.array(Lambda.map(getContracts(),function(c) return c.vendor));
		return tools.ObjectListTool.deduplicate(vendors);
	}

	public function getActiveVendors():Array<db.Vendor> {
		var vendors = Lambda.array(Lambda.map(getActiveContracts(true),function(c) return c.vendor));
		return tools.ObjectListTool.deduplicate(vendors);
	}
	
	public function getMembers() {
		return User.manager.unsafeObjects("Select u.* from User u,UserGroup ua where u.id=ua.userId and ua.groupId="+this.id+" order by u.lastName", false);
	}
	
	public function getMembersNum():Int{
		return UserGroup.manager.count($groupId == this.id);
	}

	/**
		list of anyone having rights in this group
	**/
	public function getGroupAdmins():Array<db.UserGroup>{

		var users = db.UserGroup.manager.search($rights != null && $rights != "[]" && $group == this, false);
		
		//cleaning 
		/*for ( u in users.array()) {
			
			//rights on a deleted catalog
			for ( r in u.rights) {
				switch(r) {
					case ContractAdmin(cid):
						if (cid == null) continue;
						if (db.Catalog.manager.get(cid) == null) {
							u.lock();
							u.removeRight(r);
							u.update();
						}
					default :
				}
			}
		}*/

		return users.array();
	}
	
	public function getMembersFormElementData():FormData<Int> {
		var m = getMembers();
		var out = [];
		for (mm in m) {
		
			out.push({label:mm.getCoupleName() , value:mm.id});
			
		}
		return out;
	}
	
	override public function toString() {
		if (name != '' && name != null) {
			return name;
		}else {
			return 'group#' + id;
		}
	}
	
	/**
	 * pour avoir le nom de la periode de cotisation pour une date donnée
	 */
	public function getPeriodName(?d:Date):String {
		if (d == null) d = Date.now();
		var year = getMembershipYear(d);
		return getPeriodNameFromYear(year);
	}
	
	/**
	 * Si la date de renouvellement est en janvier ou février, on note la cotisation avec l'année en cours,
	 * sinon c'est "à cheval" donc on note la cotis avec l'année la plus ancienne (ex:2014 pour une cotis 2014-2015)
	 */
	public function getMembershipYear(?d:Date):Int {
		if (d == null) d = Date.now();
		var year = d.getFullYear();
		var n = membershipRenewalDate;
		if (n == null) n = Date.now();
		var renewalDate = new Date(year, n.getMonth(), n.getDate(), 0, 0, 0);
		
		//if (membershipRenewalDate.getMonth() <= 1) {
			
			if (d.getTime() < renewalDate.getTime()) {
				return year-1;
			}else {
				return year;
			}
			
		//}else {
			//return year - 1;
		//}
	}

	public function getMembershipTimeframe(d:Date):{from:Date,to:Date}{
		if (d == null) d = Date.now();
		var n = membershipRenewalDate;
		if (n == null){
			n = new Date( 2000,8,1,0,0,0 ); //default renewal date at 1st september
		} 
		var renewalDate = new Date(d.getFullYear(), n.getMonth(), n.getDate(), 0, 0, 0);
		if (d.getTime() < renewalDate.getTime()) {
			return { from: renewalDate.setYear(renewalDate.getFullYear()-1)  , to : renewalDate };
		}else {
			return { from : renewalDate , to : renewalDate.setYear(renewalDate.getFullYear()+1)};
		}
	}
	
	/**
	 * à partir d'une année de cotis enregistrée, afficher le nom de la periode
	 * @param	y
	 */
	public function getPeriodNameFromYear(y:Int):String {
		if (membershipRenewalDate!=null && membershipRenewalDate.getMonth() <= 1) {
			return Std.string(y);
		}else {
			return Std.string(y) + "-" + Std.string(y+1);
		}
	}
	
	override public function insert(){
		
		if (txtHome == null){
			var t = sugoi.i18n.Locale.texts;
			txtHome = "Bienvenue sur le groupe " + this.name + " !\n Vous pouvez consulter votre planning de distribution ou faire une nouvelle commande.";
		}
		
		App.current.event(NewGroup(this,App.current.user));
		
		super.insert();
	}
	
	public function getCurrency():String{
		
		if (currency == ""){
			lock();
			currency = "€";
			currencyCode = "EUR";
			update();
		}
		
		return currency;		
	}

	public function getVisibleDocuments( isMemberOfGroup : Bool ) : List<sugoi.db.EntityFile> {

		if ( isMemberOfGroup ) {

			return sugoi.db.EntityFile.manager.search( $entityType == 'group' && $entityId == this.id && $documentType == 'document', false);
		}
		
		return sugoi.db.EntityFile.manager.search( $entityType == 'group' && $entityId == this.id && $documentType == 'document' && $data == 'public', false);

	}

	public function deleteDemoContracts(){
		var out = [];

		for( email in ["galinette@cagette.net","jean@cagette.net"]){
			var v = db.Vendor.manager.select($email == email);
			for( c in getContracts()){
				if( c.vendor.id==v.id) {
					c.lock();
					out.push(c);
					c.delete();
				}
			}

		}
		return out;
	}

	public function infos(): GroupInfo {
		return {
			id: id,
			name: name
		}
	}
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 			=> t._("Group name"),
			"legalStatus" 	=> t._("Legal status"),
			"txtIntro" 		=> t._("Short description"),
			"txtHome" 		=> t._("Homepage text"),
			"txtDistrib" 	=> t._("Text for distribution lists"),
			"extUrl" 		=> "URL de votre site web",
			"membershipRenewalDate" => t._("Membership renewal date"),
			"flags" 		=> t._("Options"),
			"betaFlags" 	=> t._("Nouvelles fonctionnalités"),
			"groupType" 	=> "Type de groupe (déclaratif)",
			"regOption" 	=> t._("Registration setting"),
			"contact" 		=> t._("Main contact"),
			"legalRepresentative" => t._("Legal representative")			
		];
	}

	public function setVatRates(rates:Array<{value:Float,label:String}>){
		vatRates = haxe.Json.stringify(rates);
	}

	public function getVatRates():Array<{value:Float,label:String}>{
		try{
			return haxe.Json.parse(vatRates);
		}catch(e:Dynamic){
			var rates = [{label:"TVA alimentaire",value:5.5},{label:"TVA standard",value:20}];
			this.lock();
			setVatRates(rates);
			this.update();
			return rates;
		}
	}

	/**
		get vat rates as map
	**/
	public function getVatRatesOld():Map<String,Float>{
		var map = new Map<String,Float>();
		var rates = getVatRates();
		if(rates==null) return null;
		for( r in rates){
			map.set(r.label,r.value);
		}
		return map;
	}

	public function setAllowedPaymentTypes(pt:Array<String>){
		allowedPaymentsType = haxe.Json.stringify(pt);
	}

	public function getAllowedPaymentTypes():Array<String>{
		try{
			return haxe.Json.parse(allowedPaymentsType);
		}catch(e:Dynamic){
			return [];
		}
		
	}

}