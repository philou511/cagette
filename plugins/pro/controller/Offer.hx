package pro.controller;
import form.CagetteForm;
import sugoi.form.Form;
import Common;
import sugoi.form.ListData.FormData;
import sugoi.form.elements.FloatInput;
import sugoi.form.elements.FloatSelect;
import sugoi.form.elements.IntSelect;
using Std;

class Offer extends controller.Controller
{

	var company : pro.db.CagettePro;
	
	public function new()
	{
		super();
		view.company = company = pro.db.CagettePro.getCurrentCagettePro();
		view.category = "product";
		
	}
	
	/**
	 * Edit an offer
	 */
	@tpl('plugin/pro/offerform.mtt')
	function doEdit(o:pro.db.POffer) {
		
		var f = CagetteForm.fromSpod(o);
		
		//units
		f.removeElementByName('quantity');
		var uname = o.product.unitType==null ? "Quantité" : switch(o.product.unitType){
			case Kilogram,Gram: "Poids";
			case Litre: "Volume";
			default : "Quantité";
		}
		f.addElement( new form.UnitQuantity("quantity", uname, o.quantity, true, o.product.unitType) );

		f.removeElementByName('smallQt');
		if(o.product.bulk){
			f.addElement( new form.UnitQuantity("smallQt", uname+" (petite quantité pour le vrac)", o.smallQt==null ? 0.1 : o.smallQt, true, o.product.unitType) );
		}
		
		//for the VATBox component
		view.rates = Lambda.array(company.getVatRates()).join("|");
		view.price = o.price;
		view.vat = o.vat;		
		
		//add catalogs to update
		f.addElement(new sugoi.form.elements.Html("html","<hr/>"));
		var coffers = pro.db.PCatalogOffer.manager.search($offerId == o.id, true);
		var data = [for (co in coffers) {label:co.catalog.name, value:Std.string(co.catalog.id)}];
		var checked = [];
		for (co in coffers){
			//checked if price is identical
			if ( co.price == o.price ) checked.push(Std.string(co.catalog.id)); 
		}
		var el = new sugoi.form.elements.CheckboxGroup("catalogs", "Mettre à jour le prix dans les catalogues", data, checked);
		f.addElement(el);		

		if (f.isValid()) {			
			
			f.toSpod(o); 

			if(o.product.bulk){
				if(o.smallQt==null) throw Error(sugoi.Web.getURI(),"Vous devez définir le champs 'petite quantité' si l'option 'vrac' est activée");
				if(o.product.unitType==null) throw Error(sugoi.Web.getURI(),"Vous devez définir l'unité de votre produit si l'option 'vrac' est activée");
				if(o.quantity==null) throw Error(sugoi.Web.getURI(),"Vous devez définir une quantité/poids/volume si l'option 'vrac' est activée");
			}			
			
			//ref uniqueness
			if ( pro.db.POffer.refExists(company, o.ref, o) ){
				throw Error("/p/pro/product", "Cette référence existe dejà dans votre catalogue");
			}
			
			var catalogsToUpdate : Array<Int> = f.getValueOf("catalogs");

			//if offers are in catalogs, update the lastUpdate field of the catalog (for synch purpose)			
			for( coffer in coffers){
				
				//update price directly in catalog
				if( Lambda.exists(catalogsToUpdate,function(x) {return Std.string(x)==Std.string(coffer.catalog.id);}  ) ){					
					coffer.price = o.price;
					coffer.update();
				}

				//need sync
				coffer.catalog.toSync();
			}

			o.update();
			throw Ok('/p/pro/product#product'+o.product.id,'L\'offre a été mise à jour');
		}
		
		view.form = f;
		view.title = 'Modifier l\'offre "${o.product.name}"';
	}
		
	/**
	 * Create a new offer
	 */
	@tpl("plugin/pro/offerform.mtt")
	public function doInsert(p:pro.db.PProduct) {
		
		var o = new pro.db.POffer();
		o.product = p;
		o.ref = p.ref + "-" + (pro.db.POffer.manager.count($product==p)+1);
		var f = CagetteForm.fromSpod(o);		
		
		//units
		f.removeElementByName('quantity');
		var uname = switch(p.unitType){
			case Kilogram,Gram: "Poids";
			case Litre: "Volume";
			default : "Quantité";
		}
		f.addElement( new form.UnitQuantity("quantity", uname, 1, true, p.unitType) );	
		
		
		f.removeElementByName('smallQt');
		if(o.product.bulk){
			f.addElement( new form.UnitQuantity("smallQt", uname+" (petite quantité pour le vrac)", o.smallQt==null ? 0.1 : o.smallQt, true, o.product.unitType) );
		}
		
		//for the VATBox component
		view.rates = Lambda.array(company.getVatRates()).join("|");
		view.price = 0;
		view.vat = Lambda.array(company.getVatRates())[0];

		if (f.isValid()) {
			f.toSpod(o);
			o.product = p;		

			if(o.product.bulk){
				if(o.smallQt==null) throw Error(sugoi.Web.getURI(),"Vous devez définir le champs 'petite quantité' si l'option 'vrac' est activée");
				if(o.product.unitType==null) throw Error(sugoi.Web.getURI(),"Vous devez définir l'unité de votre produit si l'option 'vrac' est activée");
				if(o.quantity==null) throw Error(sugoi.Web.getURI(),"Vous devez définir une quantité/poids/volume si l'option 'vrac' est activée");
			}
			

			if ( pro.db.POffer.refExists(company, o.ref) ){
				throw Error("/p/pro/product", "Cette référence existe dejà dans votre catalogue");
			}
			
			o.insert();
			throw Ok('/p/pro/product#product'+p.id,'L\'offre a été enregistrée');
		}
		
		view.form = f;
		view.title = "Enregistrer une nouvelle offre";
	}
	
	/**
	 * Delete an offer
	 * @param	o
	 */
	public function doDelete(o:pro.db.POffer) {
		
		var catalogOffers = o.getCatalogOffers();
		
		if (catalogOffers.length > 0){
			throw Error("/p/pro/product", "Cette offre est référencée dans le catalogue "+Lambda.map(catalogOffers,function(co) return "\""+co.catalog.name+"\"").join(", ")+". <br/>Plutôt que d'effacer complètement et définitivement le produit, il est recommandé de simplement retirer ce produit du catalogue.");
		}else{
			o.lock();
			o.delete();
			throw Ok("/p/pro/product","Offre supprimée");
		}
	}
	
	@tpl('shop/productInfo.mtt')
	public function doPreview(o:pro.db.POffer) {
		view.p = o.getInfos();
		view.vendor = company.vendor;
	}
	
	
	
	/*@tpl('plugin/pro/product/addimage.mtt')
	function doAddImage(offer:pro.db.POffer) {
		
		view.image = offer.image;		
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 12); //12Mb
		
		if (request.exists("image")) {
			
			//Image
			var image = request.get("image");
			if (image != null && image.length > 0) {
				var img : sugoi.db.File = null;
				if ( Sys.systemName() == "Windows") {
					img = sugoi.db.File.create(request.get("image"), request.get("image_filename"));
				}else {
					img = sugoi.tools.UploadedImage.resizeAndStore(request.get("image"), request.get("image_filename"), 400, 400);	
				}
				
				offer.lock();
				offer.image = img;
				offer.update();
				
				// //if offers are in catalogs, update the lastUpdate field of the catalog (for synch purpose)
				// var offersId = Lambda.map(product.getOffers(false), function(o) return o.id);
				// var coffers = pro.db.PCatalogOffer.manager.search($offerId in offersId, false);
				// var catalogs = pro.db.PCatalog.manager.search( $id in Lambda.map(coffers, function(x) return x.catalog.id) , true);
				// for ( c in catalogs) c.toSync();		
				
				throw Ok('/p/pro/product#product' + offer.product.id,'Image mise à jour');
			}
		}
		
		view.title = 'Importer une photo pour "${offer.product.name}"';
	}*/	
	
	
	
}