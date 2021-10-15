package pro.controller;
import pro.service.PCatalogService;
import pro.db.POffer;
import connector.db.RemoteCatalog;
import service.VendorService;
import Common;
using tools.ObjectListTool;

class CatalogLinker extends controller.Controller
{
	var company : pro.db.CagettePro;
	var vendor : db.Vendor;
	
	public function new() 
	{
		super();
		view.company = company = pro.db.CagettePro.getCurrentCagettePro();
		view.vendor = vendor = pro.db.CagettePro.getCurrentVendor();
	}
		
	/**
		choose which invited catalog to link
	**/
	@logged @tpl("plugin/pro/catalogLinker/default.mtt")
	public function doDefault(){
				
		view.unlinkedCatalogs = VendorService.getUnlinkedCatalogs(company);
		view.vendorId = vendor.id;
	}

	@logged @tpl("plugin/pro/catalogLinker/selectPCatalog.mtt")
	public function doSelectPcatalog(c:db.Catalog){
				
		view.pcatalogs = company.getCatalogs();
		view.catalog = c;
		
	}

	/**
		linking tool
	**/
    @logged @tpl("plugin/pro/catalogLinker/link.mtt")
	public function doLink(catalog:db.Catalog, pcatalog:pro.db.PCatalog){
				
		view.pcatalog = pcatalog;
        view.catalog = catalog;
		checkToken();
	}

	@logged @tpl("plugin/pro/catalogLinker/importFirstCatalog.mtt")
	public function doImportFirstCatalog(?catalog:db.Catalog){

		if(catalog!=null){
			if(company.getProducts().length>0) throw Error("/p/pro","Action interdite, vous avez déjà des produits dans votre compte producteur");

			pro.service.PCatalogService.linkRemoteCatalog(catalog,company);
			throw Ok('/p/pro/product',"Bravo, vous avez récupéré votre premier catalogue ! Vérifiez que les fiches produits sont correctes.");

		}else{
			view.unlinkedCatalogs = VendorService.getUnlinkedCatalogs(company);
		}
	}

	public function doSubmitLinkage(remoteCatalog:db.Catalog,pcatalog:pro.db.PCatalog){

		if(checkToken()){
			var linkage = [];
			for( k in app.params.keys()){
				if(k.substr(0,1)=="p"){
					linkage.push({
						productId:k.substr(1).parseInt(),
						offerId:app.params.get(k).parseInt()
					});
				}
			}

			//product linkage is made thru refs
			for(l in linkage){

				var offer = POffer.manager.get(l.offerId,true);
				var product = db.Product.manager.get(l.productId,true);

				//need ref
				if(offer.ref==null || offer.ref==""){
					offer.ref = pro.service.PProductService.generateRef(company);
					offer.update();
				}

				product.ref = offer.ref;
				product.update();

			}

			//create link to remote catalog
			var rc = new connector.db.RemoteCatalog();
			rc.id = remoteCatalog.id;
			rc.remoteCatalogId = pcatalog.id;
			rc.insert();


			//make a sync 
			PCatalogService.sync(pcatalog.id);

			throw Ok("/p/pro/catalog" , "Le catalogue a été correctement relié");
		}

	}

}