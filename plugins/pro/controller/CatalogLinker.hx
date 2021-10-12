package pro.controller;
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
		
	@logged @tpl("plugin/pro/catalogLinker/default.mtt")
	public function doDefault(){
				

		view.unlinkedCatalogs = VendorService.getUnlinkedCatalogs(company);

		view.vendorId = vendor.id;
	}

    @logged @tpl("plugin/pro/catalogLinker/link.mtt")
	public function doLink(catalog:db.Catalog){
				
		view.pcatalog = company.getCatalogs().array()[0];
        view.catalog = catalog;

	}

	@logged @tpl("plugin/pro/catalogLinker/importFirstCatalog.mtt")
	public function doImportFirstCatalog(?catalog:db.Catalog){

		if(catalog!=null){

			pro.service.PCatalogService.linkRemoteCatalog(catalog,company);
			throw Ok('/p/pro/product',"Bravo, vous avez récupéré votre premier catalogue ! Vérifiez que les fiches produits sont correctes.");


		}else{
			view.unlinkedCatalogs = VendorService.getUnlinkedCatalogs(company);
		}
		

	}


	
	
}