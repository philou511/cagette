package service;

import sugoi.form.elements.Html;
import controller.Product;

class ProductService{


	/**
	 * Batch disable products
	 */
	public static function batchDisableProducts(productIds:Array<Int>){

		var data = {pids:productIds,enable:false};
		var contract = db.Product.manager.get(productIds[0], true).catalog;
		var products = contract.getProducts(false);

		App.current.event( BatchEnableProducts(data) );
		
		for ( pid in data.pids){
			
			var p = db.Product.manager.get(pid, true);

			if ( Lambda.find(products,function(p) return p.id==pid)==null ) throw 'product $pid is not in this contract !';
			
			p.active = false;
			p.update();
		}
	}


	/**
	 * Batch enable products
	 */
	public static function batchEnableProducts(productIds:Array<Int>){

		var data = {pids:productIds,enable:true};
		var contract = db.Product.manager.get(productIds[0], true).catalog;
		var products = contract.getProducts(false);

		App.current.event( BatchEnableProducts(data) );
		
		for ( pid in data.pids){
			
			var p = db.Product.manager.get(pid, true);

			if ( Lambda.find(products,function(p) return p.id==pid)==null ) throw 'product $pid is not in this contract !';
			
			p.active = true;
			p.update();
		}
	}

	inline public static function getHTPrice(ttcPrice:Float,vatRate:Float):Float{
		return ttcPrice / (1 + vatRate / 100);
	}

	public static function getCategorizerHtml(productName:String,categId:Int,formName:String){
		productName = Formatting.escapeJS(productName);
		return '<div id="pInput"></div><script language="javascript">_.getProductInput("pInput","${productName}",$categId,"${formName}");</script>';
	}

	/**
		duplicate a product
	**/
	public static function duplicate(source_p:db.Product):db.Product{
		var p = new db.Product();
		p.name = source_p.name;
		p.qt = source_p.qt;
		p.price = source_p.price;
		p.catalog = source_p.catalog;
		p.image = source_p.image;
		p.desc = source_p.desc;
		p.ref = source_p.ref;
		p.stock = source_p.stock;
		p.vat = source_p.vat;
		p.organic = source_p.organic;
		p.txpProduct = source_p.txpProduct;
		p.unitType = source_p.unitType;
		p.multiWeight = source_p.multiWeight;
		p.variablePrice = source_p.variablePrice;
		p.insert();
		
		//custom categs
		for (source_cat in source_p.getCategories()){
			var cat = new db.ProductCategory();
			cat.product = p;
			cat.category = source_cat;
			cat.insert();
		}
		return p;
	}

	public static function getForm(?product:db.Product,?catalog:db.Catalog):sugoi.form.Form{

		if(product==null){
			product = new db.Product();
			product.catalog = catalog;
		} 

		var f = form.CagetteForm.fromSpod(product);

		f.getElement("bulk").description = "Ce produit est vendu en vrac ( sans conditionnement ). Le poids/volume commandé peut être corrigé après pesée.";
		f.getElement("hasFloatQt").description = "<div class='alert alert-danger'>Attention cette option <a href='https://wiki.cagette.net/admin:5april' target='_blank'>disparaîtra le lundi 3 Mai 2021</a>. </a>";
		f.getElement("variablePrice").description = "Comme au marché, le prix final sera calculé en fonction du poids réel après pesée.";
		f.getElement("multiWeight").description = "Permet de peser séparément chaque produit. Idéal pour la volaille par exemple.";

		//stock mgmt ?
		if (!product.catalog.hasStockManagement()){
			f.removeElementByName('stock');	
		} else {
			if(!product.catalog.group.hasShopMode()){
				//manage stocks by distributions for CSA contracts
				var stock = f.getElement("stock");
				stock.label = "Stock (par distribution)";				 
				if(product.stock!=null){
					stock.value = Math.floor( product.stock / product.catalog.getDistribs(false).length );
				}		
			}
		}

		var group = product.catalog.group;
		
		//VAT selector
		f.removeElement( f.getElement('vat') );		
		var data :sugoi.form.ListData.FormData<Float> = [];
		for (k in group.getVatRates().keys()) {
			data.push( { label:k, value:group.getVatRates()[k] } );
		}
		f.addElement( new sugoi.form.elements.FloatSelect("vat", "TVA", data, product.vat ) );

		f.removeElementByName("catalogId");
		
		//Product Taxonomy:
		if(!group.flags.has(CustomizedCategories)){
			var txId = product.txpProduct == null ? null : product.txpProduct.id;
			var html = service.ProductService.getCategorizerHtml(product.name,txId,f.name);
			f.addElement(new sugoi.form.elements.Html("html",html, 'Nom'),1);

			f.addElement(new sugoi.form.elements.Html("html","<a class='alert alert-warning' href='https://docs.google.com/forms/d/e/1FAIpQLSfFQpIabLSBgLTWZkuiIhQR4tO8tmGO2SZDWPd4OrHcXrM8PA/viewform?fbzx=-2048161261692944588&_hsmi=2&_hsenc=p2ANqtz-_nAqLUeyXe4EKO6PgLsD49ReyvUS-nm0FoXfFBZak_nuM_-3GpRCwdXM4ydo_3oKdGFRQ46l_deWgk4proQVALa3hKCA' target='_blank'>Participez au sondage pour améliorer les catégories.</a><br/>",""),2);

		}else{
			f.removeElementByName("txpProductId");
		}

		return f;

	}



}