package db;
import haxe.io.Encoding;
import sugoi.form.ListData.FormData;
import sys.db.Object;
import sys.db.Types;

enum CatalogFlags {
	UsersCanOrder;  		//adhérents peuvent saisir eux meme la commande en ligne
	StockManagement; 		//gestion des commandes
	PercentageOnOrders;		//calcul d'une commission supplémentaire 
}

@:index(startDate,endDate)
class Catalog extends Object
{
	public var id : SId;
	public var name : SString<64>;

	public var type : SInt;
	
	//responsable
	@formPopulate("populate") @:relation(userId) public var contact : SNull<User>;
	@formPopulate("populateVendor") @:relation(vendorId) public var vendor : Vendor;
	
	public var startDate:SDateTime;
	public var endDate :SDateTime;
	
	public var description:SNull<SText>;
	
	@hideInForms @:relation(groupId) public var group:db.Group;
	public var distributorNum:STinyInt;
	public var flags : SFlags<CatalogFlags>;
	
	public var percentageValue : SNull<SFloat>; 		//fees percentage
	public var percentageName : SNull<SString<64>>;		//fee name
	
	public var orderStartDaysBeforeDistrib : SNull<SInt>;
	public var orderEndHoursBeforeDistrib : SNull<SInt>;

	public var requiresOrdering : SNull<Bool>;
	public var distribMinOrdersTotal : SNull<SFloat>;
	public var catalogMinOrdersTotal : SNull<SFloat>;
	public var allowedOverspend : SNull<SFloat>;

	public var absentDistribsMaxNb : SNull<SInt>;
	public var absencesStartDate : SNull<SDateTime>;
	public var absencesEndDate : SNull<SDateTime>;

	@:skip inline public static var TYPE_CONSTORDERS = 0; 	//CSA catalog 
	@:skip inline public static var TYPE_VARORDER = 1;		//variable orders catalog
	@:skip var cache_hasActiveDistribs : Bool;


	
	public function new() 
	{
		super();
		flags = cast 0;
		distributorNum = 0;		
		flags.set(UsersCanOrder);
	
	}	
	
	/**
	 * The products can be ordered currently ?
	 * 
	 * @deprecated it depends on distributions
	 */
	@:skip var userOrderAvailableCache:Bool;
	public function isUserOrderAvailable():Bool {
		
		if(userOrderAvailableCache!=null) return userOrderAvailableCache;

		if (type == TYPE_CONSTORDERS ) {
			userOrderAvailableCache = isVisibleInShop();
		}else {
		
			var n = Date.now();			
			var d = db.Distribution.manager.count( $orderStartDate <= n && $orderEndDate >= n && $catalogId==this.id);
		
			userOrderAvailableCache = d>0 && isVisibleInShop();
		}

		return userOrderAvailableCache;
		
	}

	public function isCSACatalog(){
		return type == TYPE_CONSTORDERS;
	}
	
	/**
	 * The products can be displayed in a shop ?
	 */
	public function isVisibleInShop():Bool {
		
		//yes if the contract is active and the 'UsersCanOrder' flag is checked
		var n = Date.now().getTime();
		return flags.has(UsersCanOrder) && n < this.endDate.getTime() && n > this.startDate.getTime();
	}

	public function isActive():Bool{
		var n = Date.now().getTime();
		return n < this.endDate.getTime() && n > this.startDate.getTime();
	}
	
	/**
	 * is currently open to orders
	 */
	public function hasRunningOrders(){
		var now = Date.now();
		var n = now.getTime();
		
		var contractOpen = flags.has(UsersCanOrder) && n < this.endDate.getTime() && n > this.startDate.getTime();
		var d = db.Distribution.manager.count( $orderStartDate <= now && $orderEndDate > now && $catalogId==this.id);
		
		return contractOpen && d > 0;
	}
	
	
	public function hasPercentageOnOrders():Bool {
		return flags.has(PercentageOnOrders) && percentageValue!=null && percentageValue!=0;
	}
	
	public function hasStockManagement():Bool {
		return flags.has(StockManagement);
	}

	public function hasConstraints() : Bool {

		return this.type == TYPE_VARORDER && ( this.requiresOrdering || ( this.distribMinOrdersTotal != null &&  this.distribMinOrdersTotal != 0 ) || ( this.catalogMinOrdersTotal != null &&  this.catalogMinOrdersTotal != 0 ) );
	}

	public function hasAbsencesManagement() : Bool {

		return this.absentDistribsMaxNb != null && this.absentDistribsMaxNb != 0 && this.absencesStartDate != null && this.absencesEndDate != null;
	}


	public function getForm() : sugoi.form.Form {

		if ( this.group == null || this.type == null || this.vendor == null ) {

			throw new tink.core.Error( "Un des éléments suivants est manquant : le groupe, le type, ou le producteur." );
		}

		var t = sugoi.i18n.Locale.texts;

		var customMap = new form.CagetteForm.FieldTypeToElementMap();
		customMap["DDate"] = form.CagetteForm.renderDDate;
		customMap["DTimeStamp"] = form.CagetteForm.renderDDate;
		customMap["DDateTime"] = form.CagetteForm.renderDDate;

		var form = form.CagetteForm.fromSpod( this, customMap );
		
		form.removeElement(form.getElement("groupId") );
		form.removeElement(form.getElement("type"));
		form.removeElement(form.getElement("vendorId"));
		
		if ( this.group.hasShopMode() ) {

			form.removeElement(form.getElement("orderStartDaysBeforeDistrib"));
			form.removeElement(form.getElement("orderEndHoursBeforeDistrib"));
			form.removeElement(form.getElement("requiresOrdering"));
			form.removeElement(form.getElement("distribMinOrdersTotal"));
			form.removeElement(form.getElement("catalogMinOrdersTotal"));
			form.removeElement(form.getElement("allowedOverspend"));
			form.removeElement(form.getElement("absentDistribsMaxNb"));
			form.removeElement(form.getElement("absencesStartDate"));
			form.removeElement(form.getElement("absencesEndDate"));
		}
		else {
			//CSA MODE
			form.removeElementByName("percentageValue");
			form.removeElementByName("percentageName");
			untyped form.getElement("flags").excluded = [2];// remove "PercentageOnOrders" flag

			var absencesIndex = 16;
			if ( this.type == TYPE_VARORDER ) {
				//VAR
				form.addElement( new sugoi.form.elements.Html( 'distribconstraints', '<h4>Engagement par distribution</h4>', '' ), 10 );
				form.addElement( new sugoi.form.elements.Html( 'catalogconstraints', '<h4>Engagement sur la durée du contrat</h4>', '' ), 13 );
				
				form.getElement("catalogMinOrdersTotal").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#minimum_de_commandes_sur_la_duree_du_contrat";
				form.getElement("allowedOverspend").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#depassement_autorise";
			}
			else { 
				//CONST
				form.removeElement(form.getElement("orderStartDaysBeforeDistrib"));
				form.removeElement(form.getElement("requiresOrdering"));
				form.removeElement(form.getElement("distribMinOrdersTotal"));
				form.removeElement(form.getElement("catalogMinOrdersTotal"));
				form.removeElement(form.getElement("allowedOverspend"));

				form.getElement("orderEndHoursBeforeDistrib").label = "Délai minimum pour saisir une souscription (nbre d'heures avant prochaine distribution)";
				form.getElement("orderEndHoursBeforeDistrib").docLink = "https://wiki.cagette.net/admin:admin_contratsamap#champs_delai_minimum_pour_saisir_une_souscription";

				absencesIndex = 9;
			}

			var html = "<h4>Gestion des absences</h4><div class='alert alert-warning'>
            <p><i class='icon icon-info'></i> 
				Vous pouvez définir une période pendant laquelle les membres pourront choisir d'être absent.<br/>
				<a href='https://wiki.cagette.net/admin:absences' target='_blank'>Consulter la documentation.</a>
            </p></div>";
			form.addElement( new sugoi.form.elements.Html( 'absences', html, '' ), absencesIndex );
			
			//if catalog is new
			if ( this.id == null ) {

				if ( this.type == TYPE_VARORDER ) {

					form.getElement("orderStartDaysBeforeDistrib").value = 365;
					form.getElement("allowedOverspend").value = 500;
				}
				form.getElement("orderEndHoursBeforeDistrib").value = 24;
			}
		}
		
		//For all types and modes
		if ( this.id != null ) {

			form.removeElement(form.getElement("distributorNum"));
		}
		else {

			form.getElement("name").value = "Commande " + this.vendor.name;
			form.getElement("startDate").value = Date.now();
			form.getElement("endDate").value = DateTools.delta( Date.now(), 365.25 * 24 * 60 * 60 * 1000 );
		}

		form.addElement( new sugoi.form.elements.Html( "vendorHtml", '<b>${this.vendor.name}</b> ( ${this.vendor.zipCode} ${this.vendor.city} )', t._( "Vendor" ) ), 3 );

		var contact = form.getElement("userId");
		form.removeElement( contact );
		form.addElement( contact, 4 );
		contact.required = true;
			
		return form;
	}

	public function checkFormData( form : sugoi.form.Form ) {

		if( !this.group.hasShopMode() ) {

			var t = sugoi.i18n.Locale.texts;

			if( this.type == TYPE_VARORDER ) {

				var orderStartDaysBeforeDistrib = form.getValueOf("orderStartDaysBeforeDistrib");
				if( orderStartDaysBeforeDistrib == 0 ) {

					throw new tink.core.Error( 'L\'ouverture des commandes ne peut pas être à zéro.
					Si vous voulez utiliser l\'ouverture par défaut des distributions laissez le champ vide.');
				}
				
				var distribMinOrdersTotal = form.getValueOf("distribMinOrdersTotal");
				if( distribMinOrdersTotal != null && distribMinOrdersTotal != 0 ) {

					this.requiresOrdering = true;
				}

				var catalogMinOrdersTotal = form.getValueOf("catalogMinOrdersTotal");
				var allowedOverspend = form.getValueOf("allowedOverspend");
				if( ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 ) && ( allowedOverspend == null || allowedOverspend == 0 ) ) {

					throw new tink.core.Error( 'Vous devez obligatoirement définir un dépassement autorisé car vous avez rentré un minimum de commandes sur la durée du contrat.');
				}
			}

			if( this.type == TYPE_CONSTORDERS ) {
				
				var orderEndHoursBeforeDistrib = form.getValueOf("orderEndHoursBeforeDistrib");
				if( orderEndHoursBeforeDistrib == null || orderEndHoursBeforeDistrib == 0 ) {

					throw new tink.core.Error( 'Vous devez obligatoirement définir un nombre d\'heures avant distribution pour la fermeture des commandes.');
				}
			}

			var absentDistribsMaxNb = form.getValueOf('absentDistribsMaxNb');
			var absencesStartDate : Date = form.getValueOf('absencesStartDate');
			var absencesEndDate : Date = form.getValueOf('absencesEndDate');

			if ( ( absentDistribsMaxNb != null && absentDistribsMaxNb != 0 ) && ( absencesStartDate == null || absencesEndDate == null ) ) {

				throw new tink.core.Error( 'Vous avez défini un nombre maximum d\'absences alors vous devez sélectionner des dates pour la période d\'absences.' );
			}

			if ( ( absencesStartDate != null || absencesEndDate != null ) && ( absentDistribsMaxNb == null || absentDistribsMaxNb == 0 ) ) {

				throw new tink.core.Error( 'Vous avez défini des dates pour la période d\'absences alors vous devez entrer un nombre maximum d\'absences.' );
			}

			if ( absencesStartDate != null && absencesEndDate != null ) {

				if ( absencesStartDate.getTime() >= absencesEndDate.getTime() ) {

					throw new tink.core.Error( 'La date de début des absences doit être avant la date de fin des absences.' );
				}

				var absencesDistribsNb = service.SubscriptionService.getCatalogAbsencesDistribsNb( this, absencesStartDate, absencesEndDate );
				if ( ( absentDistribsMaxNb != null && absentDistribsMaxNb != 0 ) && absentDistribsMaxNb > absencesDistribsNb ) {

					throw new tink.core.Error( 'Le nombre maximum d\'absences que vous avez saisi est trop grand.
					Il doit être inférieur ou égal au nombre de distributions dans la période d\'absences : ' + absencesDistribsNb );
					
				}

				if ( absencesStartDate.getTime() < this.startDate.getTime() || absencesEndDate.getTime() > this.endDate.getTime() ) {

					throw new tink.core.Error( 'Les dates d\'absences doivent être comprises entre le début et la fin du contrat.' );
				}

				this.absencesStartDate = new Date( absencesStartDate.getFullYear(), absencesStartDate.getMonth(), absencesStartDate.getDate(), 0, 0, 0 );
				this.absencesEndDate = new Date( absencesEndDate.getFullYear(), absencesEndDate.getMonth(), absencesEndDate.getDate(), 23, 59, 59 );
			}

			if ( this.id != null ) {

				if ( this.hasPercentageOnOrders() && this.percentageValue == null ) {

					throw new tink.core.Error( t._("If you would like to add fees to the order, define a rate (%) and a label.") );
				}
				
				if ( this.hasStockManagement()) {

					for ( p in this.getProducts()) {

						if ( p.stock == null ) {

							App.current.session.addMessage(t._("Warning about management of stock. Please fill the field \"stock\" for all your products"), true );
							break;
						}
					}
				}

			}

		}
	}

	
	/**
	 * computes a 'percentage' fee or a 'margin' fee 
	 * depending on the group settings
	 * 
	 * @param	basePrice
	 */
	public function computeFees(basePrice:Float) {
		if (!hasPercentageOnOrders()) return 0.0;
		
		if (group.flags.has(ComputeMargin)) {
			//commercial margin
			return (basePrice / ((100 - percentageValue) / 100)) - basePrice;
			
		}else {
			//add a percentage
			return percentageValue / 100 * basePrice;
		}
	}

	public function check(){

		if( this.description!=null && !UnicodeString.validate( haxe.io.Bytes.ofString(this.description), Encoding.UTF8 )){
			App.current.session.addMessage('La description du catalogue est mal encodée et risque de poser des problèmes d\'affichage.',true);
		}

		for( p in getProducts(false)){
			if( p.ref!=null && !UnicodeString.validate( haxe.io.Bytes.ofString(p.ref), Encoding.UTF8 )){
				App.current.session.addMessage('La référence du produit "${p.ref}" est mal encodé et risque de poser des problèmes d\'affichage.',true);
			}

			if( p.name!=null && !UnicodeString.validate( haxe.io.Bytes.ofString(p.name), Encoding.UTF8 )){
				App.current.session.addMessage('Le nom du produit "${p.name}" est mal encodé et risque de poser des problèmes d\'affichage.',true);
			}
			if( p.desc!=null && !UnicodeString.validate( haxe.io.Bytes.ofString(p.desc), Encoding.UTF8 )){
				App.current.session.addMessage('La description du produit "${p.name}" est mal encodée et risque de poser des problèmes d\'affichage.',true);
			}
		}

	}
	
	/**
	 * 
	 * @param	amap
	 * @param	large = false	Si true, montre les contrats terminés depuis moins d'un mois
	 * @param	lock = false
	 */
	public static function getActiveContracts(amap:db.Group,?large = false, ?lock = false) {
		var now = Date.now();
		var end = Date.now();
	
		if (large) {
			end = DateTools.delta(end , -1000.0 * 60 * 60 * 24 * 30);
			return db.Catalog.manager.search($group == amap && $endDate > end,{orderBy:-vendorId}, lock);	
		}else {
			return db.Catalog.manager.search($group == amap && $endDate > now && $startDate < now,{orderBy:-vendorId}, lock);	
		}
	}
	
	/**
	 * get products in this contract
	 * @param	onlyActive = true
	 * @return
	 */
	public function getProducts(?onlyActive = true):List<Product> {
		if (onlyActive) {
			return Product.manager.search($catalog==this && $active==true,{orderBy:name},false);	
		}else {
			return Product.manager.search($catalog==this,{orderBy:name},false);	
		}
	}
	
	/**
	 * get a few products to display
	 * @param	limit = 6
	 */
	public function getProductsPreview(?limit = 6){
		return Product.manager.search($catalog==this && $active==true,{limit:limit,orderBy:-id},false);	
	}
	
		
	/**
	 *  get users who have orders in this contract ( including user2 )
	 *  @return Array<db.User>
	 */
	public function getUsers():Array<db.User> {
		var pids = getProducts().map(function(x) return x.id);
		var ucs = db.UserOrder.manager.search($productId in pids, false);
		var ucs2 = [];
		for( uc in ucs) {
			ucs2.push(uc.user);
			if(uc.user2!=null) ucs2.push(uc.user2);
		}
		
		//comme un user peut avoir plusieurs produits au sein d'un contrat, il faut dédupliquer cette liste
		var out = new Map<Int,db.User>();
		for (u in ucs2) {
			out.set(u.id, u);
		}
		
		return Lambda.array(out);
	}
	
	/**
	 * Get all orders of this contract
	 * @param	d	A delivery is needed for varying orders contract
	 * @return
	 */
	public function getOrders( distribution : db.Distribution ) : Array<db.UserOrder> {

		if ( distribution == null ) throw "This type of contract must have a delivery";
		
		//get product ids, some of the products may have been disabled but we keep the order
		var productIds = getProducts(false).map( function( product ) return product.id );

		var orders = new List<db.UserOrder>();
		orders = db.UserOrder.manager.search( ( $productId in productIds ) && $distribution == distribution, {orderBy:userId}, false );	
	
		return Lambda.array(orders);
	}

	/**
	 * Get orders for a user.
	 *
	 * @param	d
	 * @return
	 */
	public function getUserOrders(u:db.User,?d:db.Distribution,?includeUser2=true):Array<db.UserOrder> {
		if (type == TYPE_VARORDER && d == null) throw "This type of contract must have a delivery";

		var pids = getProducts(false).map(function(x) return x.id);
		var ucs = new List<db.UserOrder>();
		if (d != null && d.catalog.type==TYPE_VARORDER) {
			if(includeUser2){
				ucs = db.UserOrder.manager.search( ($productId in pids) && $distribution==d && ($user==u || $user2==u ), false);
			}else{
				ucs = db.UserOrder.manager.search( ($productId in pids) && $distribution==d && ($user==u), false);
			}
		}else{

			if ( includeUser2 ) {

				var orders = db.UserOrder.manager.search( ($productId in pids) && ($user==u || $user2==u ), false );
				if( orders.length != 0 ) {
					ucs.push( orders.first() );
				}
				
			} else {

				var orders = db.UserOrder.manager.search( ( $productId in pids ) && ( $user == u ), false );
				if( orders.length != 0 ) {
					ucs.push( orders.first() );
				}
			}
			
		}
		return Lambda.array(ucs);
	}

	public function getDistribs(excludeOld = true,?limit=999):List<Distribution> {
		if (excludeOld) {
			//still include deliveries which just expired in last 24h
			return Distribution.manager.search($end > DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24) && $catalog == this, { orderBy:date,limit:limit },false);
		}else{
			return Distribution.manager.search( $catalog == this, { orderBy:date,limit:limit } ,false);
		}
	}

	public function getVisibleDocuments( user : db.User ) : List<sugoi.db.EntityFile> {

		var isSubscribedToCatalog = false;
		if ( user != null && this.type == TYPE_CONSTORDERS ) { //Amap catalog

			var userCatalogs : Array<db.Catalog> = user.getContracts(this.group);
			isSubscribedToCatalog = Lambda.exists( userCatalogs, function( usercatalog ) return usercatalog.id == this.id ); 
		}

		if ( isSubscribedToCatalog ) {

			return sugoi.db.EntityFile.manager.search( $entityType == 'catalog' && $entityId == this.id && $documentType == 'document', false);
		}

		if ( user != null && user.isMemberOf(group) ) {

			return sugoi.db.EntityFile.manager.search( $entityType == 'catalog' && $entityId == this.id && $documentType == 'document' && $data != 'subscribers', false);
		}
		
		return sugoi.db.EntityFile.manager.search( $entityType == 'catalog' && $entityId == this.id && $documentType == 'document' && $data == 'public', false);

	}

	public function isDemoCatalog():Bool{
		return this.vendor.email != 'jean@cagette.net' && this.vendor.email != 'galinette@cagette.net';
	}
	
	override function toString() {
		return name+" du "+this.startDate.toString().substr(0,10)+" au "+this.endDate.toString().substr(0,10);
	}
	
	public function populate() {
		return App.current.user.getGroup().getMembersFormElementData();
	}

	override public function update(){
		startDate 	= new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate()	, 0, 0, 0 );
		endDate 	= new Date( endDate.getFullYear(),   endDate.getMonth(),   endDate.getDate()	, 23, 59, 59 );
		super.update();
	}
	
	/**
	 * get a vendor list as form data
	 * @return
	 */
	public function populateVendor():FormData<Int>{
		if(this.group==null) return [];
		var vendors = this.group.getVendors();
		var out = [];
		for (v in vendors) {
			out.push({label:v.name, value:v.id });
		}
		return out;
	}
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 				=> t._("Catalog name"),
			"startDate" 		=> t._("Start date"),
			"endDate" 			=> t._("End date"),
			"description" 		=> t._("Description"),
			"distributorNum" 	=> t._("Number of required volunteers during a distribution"),
			"flags" 			=> t._("Options"),
			"percentageValue" 	=> t._("Fees percentage"),
			"percentageName" 	=> t._("Fees label"),
			"contact" 			=> t._("Contact"),
			"vendor" 			=> t._("Farmer"),
			"orderStartDaysBeforeDistrib" => "Ouverture des commandes (nbre de jours avant distribution)",
			"orderEndHoursBeforeDistrib" => "Fermeture des commandes (nbre d'heures avant distribution)",
			"requiresOrdering" => "Obligation de commander à chaque distribution",
			"distribMinOrdersTotal" => "Minimum de commande par distribution (en €)",
			"catalogMinOrdersTotal" => "Minimum de commandes sur la durée du contrat (en €)",
			"allowedOverspend" => "Dépassement autorisé (en €)",
			"absentDistribsMaxNb" => "Nombre maximum d'absences",
			"absencesStartDate" => "Date de début de la période d'absences",
			"absencesEndDate" => "Date de fin de la période d'absences",
		];
	}
	
	
}