package pro.service;
import Common;

class PCatalogService{

	/**
	 * Synchronizes catalog to contracts, offers to products, company info to vendor.
	 If catalogId is given, force sync of this catalog
	 */
	public static function sync(?catalogId:Int){

		var log = [];

		var remoteCatalogs = new List();
		if ( catalogId!=null ){
			remoteCatalogs = connector.db.RemoteCatalog.manager.search($remoteCatalogId == catalogId,true);
		}else{
			remoteCatalogs = connector.db.RemoteCatalog.manager.search($needSync);
		}
		
		for ( rc in remoteCatalogs){
			
			var contract = rc.getContract();
			if (contract == null) continue;
			var catalog = rc.getCatalog();			
			if( catalog==null ) continue;
			
			
			var fullUpdate = !contract.hasOpenOrders() || catalogId!=null;
			
			//log.push( "<h4>" + /*contract.name+" - " +*/ contract.amap.name /*+(fullUpdate?"[Full]":"[Light]")*/ + "</h4>" );
			log.push( "<h4>" +  contract.group.name + "</h4>" );

			syncContract(contract,catalog);
			
			//sync cpro products to group products
			var groupProducts = contract.getProducts(false);
			var disabledProducts = rc.getDisabledProducts();
			
			for ( cproProduct in catalog.getOffers() ){
				
				//find remote product by ref.
				var groupProduct = Lambda.find(groupProducts, function(x) return x.ref == cproProduct.offer.ref);				
				var disabledInGroup = false;
				if(groupProduct!=null){
					disabledInGroup = Lambda.has(disabledProducts, groupProduct.id);
					//debug
					/*if(disabledInGroup){
						log.push( cproProduct.offer+" est désactivé dans le groupe" );
					}else{
						log.push( cproProduct.offer+" est actif dans le groupe" );
					}*/
				}else{
					//debug
					//log.push( cproProduct.offer+" n'existe pas, faut le créer" );
				} 
				log = log.concat( syncProduct(cproProduct, groupProduct, contract, fullUpdate, disabledInGroup) );	
				groupProducts.remove(groupProduct);				
			}
			
			//removed product from catalog, let's disable them.
			//do NOT remove them to keep previous orders.
			for ( p in groupProducts){
				if (p.active == false) continue;
				log.push("Produit à désactiver : " + p.name);
				p.lock();
				p.active = false;
				p.update();
				
			}

			//once everything is updated, set needSync to false
			if (fullUpdate){
				rc.needSync = false;
				rc.update();	
			}
			
			
		}
		//log = log.split("\n").join("<br/>\n");
		return log;
	}


	/**
	 * Synchro from catalog offer -> product.
	 * Manages also new products
	 * @param	off
	 * @param	product
	 */
	public static function syncProduct(co:pro.db.PCatalogOffer, ?groupProduct:db.Product, contract:db.Catalog, fullUpdate:Bool, ?isLocallyDisabled=false){
		
		var log = [];
		if (groupProduct == null){
			log.push("Nouveau produit : " + co.offer.product.name);
			groupProduct = new db.Product();
			groupProduct.catalog = contract;
		}else{
			groupProduct.lock();
		}
		
		//if its a new product, sync completely
		if (groupProduct.id == null){			
			fullUpdate = true;
		}
		
		//log.push("update product " + co.offer.ref + " " + groupProduct.name+ (isLocallyDisabled?"  (locally disabled)":"") + "\n";		
		
		groupProduct.desc = co.offer.product.desc;
		groupProduct.unitType = co.offer.product.unitType;
		groupProduct.qt = co.offer.quantity;
		groupProduct.image = co.offer.image==null ? co.offer.product.image : co.offer.image;
		groupProduct.ref = co.offer.ref;
		groupProduct.vat = co.offer.vat;
		groupProduct.txpProduct = co.offer.product.txpProduct;
		groupProduct.organic = co.offer.product.organic;		
		groupProduct.variablePrice = co.offer.product.variablePrice;
		groupProduct.multiWeight = co.offer.product.multiWeight;
		groupProduct.wholesale = co.offer.product.wholesale;
		groupProduct.retail = co.offer.product.retail;
		groupProduct.bulk = co.offer.product.bulk;
		groupProduct.smallQt = co.offer.smallQt;
		
		//set stock if it's a new product
		if(groupProduct.id == null && co.offer.stock!=null){
			groupProduct.stock = PStockService.getStocks(co.offer).availableStock;
		}
		
		groupProduct.active = co.offer.active && !isLocallyDisabled;		
		
		//name change
		if (fullUpdate) {
			groupProduct.name = co.offer.product.name;				
			if (co.offer.name != null){
				groupProduct.name += " - " + co.offer.name;
			}
		}
		
		//made this because of this fucking bug with float comparison !
		if (groupProduct.price == null) groupProduct.price = 0;
		if ( Formatting.roundTo(groupProduct.price,2) != Formatting.roundTo(co.price,2)  && fullUpdate ){
			log.push("Changement de prix : " + groupProduct.name + " : '" + groupProduct.price + "' -> '" + co.price +"'");	
			groupProduct.price = co.price;	
		}		
		
		if (groupProduct.id == null){
			groupProduct.insert();
		}else{
			groupProduct.update();			
		}		

		return log;
	}

	/**
	 *  SYnc categs (TERRA LIBRA)
	 */
	/*public static function syncCategs(p:db.Product){

		var getCategGroup = function(cgName:String){
			var cg = db.CategoryGroup.manager.select($name==cgName && $amapId==p.catalog.group.id);
			if(cg==null){
				cg = new db.CategoryGroup();
				cg.name = cgName;
				cg.amap = p.catalog.group;
				cg.insert();
			}
			return cg;
		}

		var getCateg = function(catName:String,cgName:String){
			var cg = getCategGroup(cgName);
			var cat = db.Category.manager.select($name==catName && $categoryGroupId==cg.id);
			if(cat==null){
				cat = new db.Category();
				cat.name = catName;
				cat.categoryGroup = cg;
				cat.insert();
			}
			return cat;
		}

		

		var txp = p.txpProduct;
		if(txp==null) return null;
		//var cg = getCategGroup("Types de produits");
		var cat = getCateg(txp.category.name+" / "+txp.subCategory.name,"Types de produits");
		db.ProductCategory.getOrCreate(p,cat);
		
		return "CATEG : "+cat.name+"<br/>";


	}*/

	/*public static function syncVendor(?companySource:pro.db.Company,?pvendorSource:pro.db.PVendor,target:db.Vendor){
		if(target.id!=null) target.lock();

		if(companySource!=null){
			target.name = companySource.name;
			target.desc = companySource.desc;
			target.image = companySource.image;
			target.email  = companySource.email;
			target.phone = companySource.phone;
			target.address1 = companySource.address1;
			target.address2 = companySource.address2;
			target.zipCode = companySource.zipCode;
			target.city = companySource.city;
			target.desc = companySource.desc;
			target.linkText = companySource.linkText;
			target.linkUrl = companySource.linkUrl;
		}else{
			target.name = pvendorSource.name;
			target.desc = pvendorSource.desc;
			target.image = pvendorSource.image;
			target.email  = pvendorSource.email;
			target.phone = pvendorSource.phone;
			target.address1 = pvendorSource.address1;
			target.address2 = pvendorSource.address2;
			target.zipCode = pvendorSource.zipCode;
			target.city = pvendorSource.city;
			target.desc = pvendorSource.desc;
			target.linkText = pvendorSource.linkText;
			target.linkUrl = pvendorSource.linkUrl;
		}
		if(target.id!=null) {
			target.update();
		}else{
			target.insert();
		}

		return target;
	}*/

	/**
	 *  Create or sync the contract
	 *  @param contract - 
	 *  @param catalog - 
	 *  @param contact - 
	 *  @param group - 
	 *  @param vendor - 
	 */
	public static function syncContract(contract:db.Catalog,catalog:pro.db.PCatalog, ?contact:db.User,?group:db.Group){

		if(catalog==null) throw "catalog cannot be null";
		if(contract==null){

			if(group==null) throw "you should provide a group";
			if(contact==null) throw "you should provide a contact";
			if(catalog.company.vendor==null) throw "catalog should be linked to a CagettePro/Vendor accound";

			//create it
			contract = new db.Catalog();
			contract.vendor = catalog.company.vendor;
			contract.type = db.Catalog.TYPE_VARORDER;
			contract.group = group;
			contract.flags.set(db.Catalog.CatalogFlags.UsersCanOrder);
			contract.contact = contact;
		
		}else{
			//just sync it
			contract.lock();
		}
		
		contract.startDate = catalog.startDate;
		contract.endDate = catalog.endDate;
		if(catalog.contractName!=null) {
			contract.name = catalog.contractName;
		}else{
			contract.name = "Commande "+contract.vendor.name;
		}

				
		//vendor
		if( catalog.vendor==null){
			if(catalog.company.vendor==null) throw "catalog "+catalog.id+" company has no vendor";
			contract.vendor = catalog.company.vendor;
		}else{
			if(catalog.vendor==null) throw "catalog "+catalog.id+" vendor is null";
			contract.vendor = catalog.vendor;	
		}
		
		if(contract.id==null){
			contract.insert();
		}else{
			contract.update();
		}

		//check that the farmer can access the contract in the group
		for( user in catalog.company.getUsers() ){
			var ua = db.UserGroup.getOrCreate(user, contract.group);
			if(catalog.company.captiveGroups){
				//cagette pro users are admin in all groups if captiveGroups is activated
				ua.giveRight(Right.GroupAdmin);
				ua.giveRight(Right.Membership);
				ua.giveRight(Right.Messages);
				ua.giveRight(Right.ContractAdmin());
			}else{
				ua.giveRight(Right.ContractAdmin(contract.id));
			}
			
			
		}

		return contract;
	}

	/**
	 * Link catalog to group : Create catalog and products from a pcatalog
	 */
	public static function linkCatalogToGroup(catalog:pro.db.PCatalog,clientGroup:db.Group,remoteUserId:Int,?contractType=1):connector.db.RemoteCatalog{
		
		if(catalog.company.discovery){
			//check if there is already one group
			var groups = catalog.company.getGroups();
			if(groups.length > 0 && groups[0].id!=clientGroup.id){
				throw new tink.core.Error("<b>"+catalog.company.vendor.name+"</b> ne peut pas travailler avec plus d'un point de livraison, car il est en <b>Cagette Découverte</b>. <br/>Passez à <b>Cagette Pro</b> pour vous relier à un nombre illimité de points de livraison.");
			}
		}

		//checks
		var contracts = connector.db.RemoteCatalog.getContracts(catalog, clientGroup);
		if ( contracts.length>0 ){
			throw new tink.core.Error("Ce catalogue existe déjà dans ce groupe. Il n'est pas nécéssaire d'importer plusieurs fois le même catalogue dans un groupe.");
		}

		//coordinator
		var contact = db.User.manager.get(remoteUserId);
		
		//create contract		
		var contract = syncContract(null,catalog,contact,clientGroup);

		//if AMAP contract
		if(contractType==0){
			contract.type = db.Catalog.TYPE_CONSTORDERS;
			contract.update();
		}
		
		//create remoteCatalog record
		var rc = new connector.db.RemoteCatalog();
		rc.id = contract.id;
		rc.remoteCatalogId = catalog.id;
		rc.insert();
		
		//create products
		for ( co in catalog.getOffers()){
			pro.service.PCatalogService.syncProduct(co, null, contract,true, false);
		}
		
		return rc;
	}
	

	public static function makeCatalogOffer(offer:pro.db.POffer,catalog:pro.db.PCatalog,price:Float){
		var cp = new pro.db.PCatalogOffer();
		cp.catalog = catalog;
		cp.offer = offer;
		cp.price = price;
		cp.insert();
		return cp;
	}

}