package controller;
import sugoi.form.Form;
import Common;
import sugoi.form.ListData.FormData;
import sugoi.form.elements.FloatInput;
import sugoi.form.elements.FloatSelect;
import sugoi.form.elements.IntSelect;
using Std;
class Product extends Controller
{

	public function new()
	{
		super();
		view.nav = ["contractadmin","products"];
	}
	
	@tpl('form.mtt')
	function doEdit(d:db.Product) {
		
		if (!app.user.canManageContract(d.contract)) throw t._("Forbidden access");
		
		var f = sugoi.form.Form.fromSpod(d);
		
		//type (->icon)
		//f.removeElement( f.getElement("type") );
		//var pt = new form.ProductTypeRadioGroup("type", "type",Std.string(d.type));
		//f.addElement( pt );
		
		//stock mgmt ?
		if (!d.contract.hasStockManagement()) f.removeElementByName('stock');	
		
		//VAT selector
		f.removeElement( f.getElement('vat') );		
		var data :FormData<Float> = [];
		for (k in app.user.amap.vatRates.keys()) {
			data.push( { label:k, value:app.user.amap.vatRates[k] } );
		}
		f.addElement( new FloatSelect("vat", "TVA", data, d.vat ) );

		f.removeElementByName("contractId");
		
		//Product Taxonomy:
		//view.taxo = db.TxpProduct.manager.all();
		//f.addElement(new form.TxpProduct("txpProduct", "taxo",null,false) );
		var txId = d.txpProduct == null ? "" : Std.string(d.txpProduct.id);
		var html = '<div id="pInput"></div><script language="javascript">_.getProductInput("pInput","${d.name}","$txId","${f.name}");</script>';
		f.addElement(new sugoi.form.elements.Html(html, 'Nom'),1);

		if (f.isValid()) {
			
			
			f.toSpod(d); //update model
			
			app.event(EditProduct(d));
			
			d.update();
			throw Ok('/contractAdmin/products/'+d.contract.id, t._("The product has been updated"));
		}else{
			app.event(PreEditProduct(d));
		}
		
		view.form = f;
		view.title = t._("Modify a product");
	}
	
	@tpl("form.mtt")
	public function doInsert(contract:db.Contract ) {
		
		if (!app.user.isContractManager(contract)) throw Error("/", t._("Forbidden action")); 
		
		var d = new db.Product();
		var f = sugoi.form.Form.fromSpod(d);
		
		//f.removeElement( f.getElement("type") );		
		//var pt = new form.ProductTypeRadioGroup("type", "type", "1");
		//f.addElement( pt );
		f.removeElementByName("contractId");
		
		//stock mgmt ?
		if (!contract.hasStockManagement()) f.removeElementByName('stock');
		
		//vat selector
		f.removeElement( f.getElement('vat') );
		
		var data = [];
		for (k in app.user.amap.vatRates.keys()) {
			data.push( { value:app.user.amap.vatRates[k], label:k } );
		}
		f.addElement( new FloatSelect("vat", "TVA", data, d.vat ) );
		
		var formName = f.name;
		var html = '<div id="pInput"></div><script language="javascript">_.getProductInput("pInput","",null,"$formName");</script>';
		f.addElement(new sugoi.form.elements.Html(html, 'Nom'),1);
		
		
		if (f.isValid()) {
			f.toSpod(d); //update model
			d.contract = contract;
			
			app.event(NewProduct(d));
			
			d.insert();
			throw Ok('/contractAdmin/products/'+d.contract.id, t._("The product has been saved"));
		}else{
			app.event(PreNewProduct(contract));
		}
		
		view.form = f;
		view.title = t._("Key-in a new product");
	}
	
	public function doDelete(p:db.Product) {
		
		if (!app.user.canManageContract(p.contract)) throw t._("Forbidden access");
		
		if (checkToken()) {
			
			app.event(DeleteProduct(p));
			
			var orders = db.UserContract.manager.search($productId == p.id, false);
			if (orders.length > 0) {
				throw Error("/contractAdmin", t._("Not possible to delete this product because some orders are referencing it"));
			}
			var cid = p.contract.id;
			p.lock();
			p.delete();
			
			throw Ok("/contractAdmin/products/"+cid, t._("Product deleted"));
		}
		throw Error("/contractAdmin", t._("Token error"));
	}
	
	
	@tpl('product/import.mtt')
	function doImport(c:db.Contract, ?args: { confirm:Bool } ) {
		
		if (!app.user.canManageContract(c)) throw t._("Forbidden access");
			
		var csv = new sugoi.tools.Csv();
		csv.step = 1;
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 4);
		csv.setHeaders( ["productName","price","ref","desc","qt","unit","organic","floatQt","vat","stock"] );
		view.contract = c;
		
		// get the uploaded file content
		if (request.get("file") != null) {
			
			var datas = csv.importDatasAsMap(request.get("file"));
			
			app.session.data.csvImportedData = datas;
			
			csv.step = 2;
			view.csv = csv;
		}
		
		if (args != null && args.confirm) {
			var i : Iterable<Map<String,String>> = cast app.session.data.csvImportedData;
			var fv = new sugoi.form.filters.FloatFilter();
			
			for (p in i) {
				
				if (p["productName"] != null){

					var product = new db.Product();
					product.name = p["productName"];
					product.price = fv.filterString(p["price"]);
					product.ref = p["ref"];
					product.desc = p["desc"];
					product.vat = fv.filterString(p["vat"]);
					product.qt = fv.filterString(p["qt"]);
					if(p["unit"]!=null){
						product.unitType = switch(p["unit"].toLowerCase()){
							case "kg" : Kilogram;
							case "g" : Gram;
							case "l" : Litre;
							case "litre" : Litre;
							default : Piece;
						}
					}
					if (p["stock"] != null) product.stock = fv.filterString(p["stock"]);
					product.organic = p["organic"] != null;
					product.hasFloatQt = p["floatQt"] != null;
					
					product.contract = c;
					product.insert();
				}
				
			}
			
			view.numImported = app.session.data.csvImportedData.length;
			app.session.data.csvImportedData = null;
			
			csv.step = 3;
		}
		
		if (csv.step == 1) {
			//reset import when back to import page
			app.session.data.csvImportedData =	null;
		}
		
		view.step = csv.step;
	}
	
	@tpl("product/categorize.mtt")
	public function doCategorize(contract:db.Contract) {
		
		
		if (!app.user.canManageContract(contract)) throw t._("Forbidden access");
		
		if (db.CategoryGroup.get(app.user.amap).length == 0) throw Error("/contractAdmin", t._("You must first define categories before you can assign a category to a product"));
		
		//var form = new sugoi.form.Form("cat");
		//
		//for ( g in db.CategoryGroup.get(app.user.amap)) {
			//var data = [];
			//for ( c in g.getCategories()) {
				//data.push({key:Std.string(c.id),value:c.name});
			//}
			//form.addElement(new sugoi.form.elements.Selectbox("cats"+g.id,g.name,data));
		//}
		//
		//view.form = form;
		view.c = contract;
		
	}
	
	/**
	 * init du Tagger
	 * @param	contract
	 */	
	public function doCategorizeInit(contract:db.Contract) {
		
		if (!app.user.canManageContract(contract)) throw t._("Forbidden access");
		
		var data : TaggerInfos = {
			products:[],
			categories:[]
		}
		
		for (p in contract.getProducts()) {
			
			data.products.push({product:p.infos(),categories:Lambda.array(Lambda.map(p.getCategories(),function(x) return x.id))});
		}
		
		for (cg in db.CategoryGroup.get(app.user.amap)) {
			
			var x = { id:cg.id, categoryGroupName:cg.name, color:App.current.view.intToHex(db.CategoryGroup.COLORS[cg.color]),tags:[] };
			
			for (t in cg.getCategories()) {
				x.tags.push({id:t.id,name:t.name});
			}
			data.categories.push(x);
			
		}
		
		Sys.print(haxe.Json.stringify(data));
	}
	
	public function doCategorizeSubmit(contract:db.Contract) {
		
		if (!app.user.canManageContract(contract)) throw t._("Forbidden access");
		
		var data : TaggerInfos = haxe.Json.parse(app.params.get("data"));
		
		db.ProductCategory.manager.unsafeDelete("delete from ProductCategory where productId in (" + Lambda.map(contract.getProducts(), function(t) return t.id).join(",")+")");
		
		for (p in data.products) {
			for (t in p.categories) {
				var x = new db.ProductCategory();
				x.category = db.Category.manager.get(t, false);
				x.product = db.Product.manager.get(p.product.id,false);
				x.insert();				
			}
		}
		
		Sys.print(t._("Modifications saved"));
	}
	
	
	@tpl('product/addimage.mtt')
	function doAddImage(product:db.Product) {
		
		if (!app.user.canManageContract(product.contract)) throw t._("Forbidden access");
		
		view.c = product.contract;
		view.image = product.image;
		
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
				
				product.lock();
				
				if (product.image != null) {
					//efface ancienne
					product.image.lock();
					product.image.delete();
				}
				
				product.image = img;
				product.update();
				throw Ok('/product/addImage/'+product.id,'Image mise à jour');
			}
		}
	}	

	
	@tpl('product/compose.mtt')
	function doCompose(){
		
	}
	
	
	function doGetTaxo(){
		
		var out : TxpDictionnary = {products:new Map(), categories:new Map(), subCategories:new Map()};
		
		for ( p in db.TxpProduct.manager.all()){
			out.products.set(p.id, {id:p.id, name:p.name, category:p.category.id, subCategory:p.subCategory.id});			
		}
		
		for ( c in db.TxpCategory.manager.all()){
			out.categories.set(c.id, {id:c.id,name:c.name });
		}
		
		for ( c in db.TxpSubCategory.manager.all()){
			out.subCategories.set(c.id, {id:c.id,name:c.name });
		}
		
		Sys.print(haxe.Serializer.run(out));
		
	}
	
	
	
}