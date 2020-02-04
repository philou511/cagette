import js.html.InputElement;
import js.Browser;
import Common;
import js.jquery.JQuery;
/**
 * JS Shopping Cart
 **/
class ShopCart
{
	public var products : Map<Int,ProductInfo>; //product db
	public var productsArray : Array<ProductInfo>; //to keep order of products
	public var categories : Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>; //categ db
	public var pinnedCategories : Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>; //categ db
	public var order : TmpBasketData;
	
	var loader : js.html.Element; //ajax loader gif
	
	//for scroll mgmt
	var cartTop : Int;
	var cartLeft : Int;
	var cartWidth : Int;
	var jWindow : JQuery;
	var cartContainer : JQuery;
	
	// var date : String;
	// var place : Int;
	var multiDistribId : Int;


	public function new() {
		products = new Map();
		productsArray = [];		
		order = { products:[] };
		categories = [];
		pinnedCategories = [];
	}
	

	
	public function add(pid:Int) {
		loader.style.display = "block";
		
		var inputEl: InputElement = cast Browser.document.getElementById('productQt' + pid);
		var q = inputEl.value;
		var qt = 0.0;
		var p = this.products.get(pid);
		if (p.hasFloatQt) {
			q = StringTools.replace(q, ",", ".");
			qt = Std.parseFloat(q);
		}else {
			qt = Std.parseInt(q);			
		}
		
		if (qt == null) {
			qt = 1;
		}
		
		//add server side
		var r = new haxe.Http('/shop/add/$multiDistribId/$pid/$qt');
		
		r.onData = function(data:String) {
			loader.style.display = "none";

			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//add locally
			subAdd(pid, qt);
			render();
		}
		r.request();
	}
	
	
	function subAdd(pid, qt:Float ) {
		for ( p in order.products) {
			if (p.productId == pid) {
				p.quantity += qt;
				render();
				return;
			}
		}
		order.products.push( { productId:pid, quantity:qt } );
	}
	
	/**
	 * Render the shopping cart and total
	 */
	function render() {
		var c = Browser.document.getElementById("cart");
		while (c.firstChild != null) c.removeChild(c.firstChild);

		Lambda.map(order.products, function( x ) {
			var p = this.products.get(x.productId);
			if (p == null) return false;

			var row = Browser.document.createElement("div");
			row.classList.add("row");

			var col1 = Browser.document.createElement("div");
			col1.classList.add("order");
			col1.classList.add("col-md-9");
			col1.innerHTML = "<b> " + x.quantity + " </b> x " + p.name;
			row.appendChild(col1);

			var col2 = Browser.document.createElement("div");
			col2.classList.add("col-md-3");
			row.appendChild(col2);

			var btn = Browser.document.createElement("a");
			btn.classList.add("btn");
			btn.classList.add("btn-default");
			btn.classList.add("btn-xs");
			btn.setAttribute("data-toggle", "tooltip");
			btn.setAttribute("data-placement", "top");
			btn.setAttribute("title", "Retirer de la commande");
			btn.innerHTML = "<i class='icon icon-delete'></i>";
			btn.onclick = function() {
				remove(p.id);
			}
			col2.appendChild(btn);

			c.appendChild(row);
			return true;
		});
		
		//compute total price
		var total = 0.0;
		for (p in order.products) {
			var pinfo = products.get(p.productId);
			if (pinfo == null) continue;
			total += p.quantity * pinfo.price;
		}
		var ffilter = new sugoi.form.filters.FloatFilter();
		
		var total = ffilter.filterString(Std.string(App.roundTo(total,2)));
		var totalEl = Browser.document.createElement("div");
		totalEl.classList.add("total");
		totalEl.appendChild(Browser.document.createTextNode("TOTAL : " + total));
		c.appendChild(totalEl);		
		
		if (order.products.length > 0){
			App.instance.setWarningOnUnload(true,"Vous avez une commande en cours. Si vous quittez cette page sans confirmer, votre commande sera perdue.");
		}else{
			App.instance.setWarningOnUnload(false);
		}
	}


	function findCategoryName(cid: Int): String {
		for (cg in this.categories){
			for (c in cg.categs){
				if (cid == c.id) {
					return c.name;
				}
			}
		}
		for ( cg in this.pinnedCategories ){
			for (c in cg.categs){
				if (cid == c.id) {
					return c.name;
				}
			}
		}
		return null;
	}

	/**
	 * Dynamically sort products by categories
	 */
	public function sortProductsBy() {
		trace("sortProductsBy");
		//store products by groups
		var groups = new Map<Int,{name:String,products:Array<ProductInfo>}>();
		var pinned = new Map<Int,{name:String,products:Array<ProductInfo>}>();

		var firstCategGroup = this.categories[0].categs;
		var pList = this.productsArray.copy();

		//sort by categs
		for (p in pList.copy()) {
			// untyped p.element.remove();
			// var element: js.html.Element = untyped p.element; 
			// while (element.firstChild != null) element.removeChild(element.firstChild);

			for (categ in p.categories){
				if (Lambda.find(firstCategGroup, function(c) return c.id == categ) != null) {
					//is in this category group
					var g = groups.get(categ);
					if (g == null){
						var name = findCategoryName(categ);
						g = {name:name,products:[]};
					}
					g.products.push(p);
					pList.remove(p);
					groups.set(categ, g);
				}
				else {
					// is in pinned group ?
					var isInPinnedCateg = false;
					for (cg in pinnedCategories){
						if (Lambda.find(cg.categs, function(c) return c.id == categ) != null) {
							isInPinnedCateg = true;
							break;
						}
					}

					if (isInPinnedCateg) {
						var c = pinned.get(categ);
						if (c == null){
							var name = findCategoryName(categ);
							c = {name:name,products:[]};
						}
						c.products.push(p);
						pList.remove(p);
						pinned.set(categ, c);
					} else {
						//not in the selected categ nor in pinned groups
						continue;
					}
				}
			}
		}

		//if some untagged products remain
		if (pList.length > 0){
			groups.set(0,{name:"Autres",products:pList});
		}

		// var container = App.jq(".shop .body");
		var container = Browser.document.querySelector(".shop .body");

		//render firts "pinned" groups , then "groups"
		for (source in [pinned, groups]) {
			for (o in source){
				if (o.products.length == 0) continue;
				var col = Browser.document.createElement("div");
				for (c in ["col-md-12", "col-xs-12", "col-sm-12", "col-lg-12"]) col.classList.add(c);
				col.innerHTML = "<div class='catHeader'>" + o.name + "</div>";
				container.appendChild(col);
				// container.append("<div class='col-md-12 col-xs-12 col-sm-12 col-lg-12'><div class='catHeader'>" + o.name + "</div></div>");

				for (p in o.products) {
					trace(untyped p.element.outerHTML);
				// 	// trace("p", untyped p.element.parentElement.length == 0);
				// 	//if the element has already been inserted, we need to clone it
				// 	if (untyped p.element.parentElement.length == 0){
				// 		container.appendChild(untyped p.element);
				// 		container.appendChild(Browser.document.createTextNode("HELLO!!"));
				// 	} else{
				// 		var clone = untyped p.element.cloneNode(true);
				// 		container.appendChild(clone);
				// 		// trace(clone);
				// 	}
				}
			}
		}
		App.jq(".product").show();
	}

	/**
	 * is shopping cart empty ?
	 */
	public function isEmpty(){
		return order.products.length == 0;
	}

	/**
     * submit cart
     */
	public function submit() {
		
		var req = new haxe.Http("/shop/submit/"+multiDistribId);
		req.onData = function(data) {
			var data : {tmpBasketId:Int,success:Bool} = haxe.Json.parse(data);
			App.instance.setWarningOnUnload(false);
			js.Browser.location.href = "/shop/validate/"+data.tmpBasketId;
		}
		req.addParameter("data", haxe.Json.stringify(order));
		req.request(true);		
	}
	
	/**
	 * filter products by category
	 */
	public function filter(cat:Int) {
		
		//icone sur bouton
		App.jq(".tag").removeClass("active").children().remove("i");//clean
		
		var bt = App.jq("#tag" + cat);
		bt.addClass("active").prepend("<i class='icon icon-check'></i> ");
		
		
		//affiche/masque produits
		for (p in products) {
			if (cat==0 || Lambda.has(p.categories, cat)) {
				App.jq(".shop .product" + p.id).fadeIn(300);
			}else {
				App.jq(".shop .product" + p.id).fadeOut(300);
			}
		}
	}
	
	/**
	 * remove a product from cart
	 * @param	pid
	 */
	public function remove(pid:Int ) {
		loader.style.display = "block";
		//add server side
		var r = new haxe.Http('/shop/remove/$multiDistribId/$pid');
		r.onData = function(data:String) {
			loader.style.display = "none";
			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//remove locally
			for ( p in order.products.copy()) {
				if (p.productId == pid) {
					order.products.remove(p);
					render();
					return;
				}
			}
			render();
		}
		r.request();
	}
	
	/**
	 * loads products DB and existing cart in ajax
	 */
	public function init(multiDistribId:Int) {
		this.multiDistribId = multiDistribId;
		loader = Browser.document.getElementById("loader");
		
		var req = new haxe.Http("/shop/init/"+multiDistribId);
		req.onData = function(data) {
			loader.style.display = "none";
			
			var data : { 
				products:Array<ProductInfo>,
				categories:Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>,
				order:TmpBasketData } = haxe.Unserializer.run(data);

			//populate local categories lists
			for ( cg in data.categories){
				if (cg.pinned){
					pinnedCategories.push(cg);
				}else{
					categories.push(cg);
				}
			}

			//product DB
			for (p in data.products) {
				//catch dom element for further usage
				untyped p.element = Browser.document.querySelector(".product" + p.id);

				var id : Int = p.id;
				this.products.set(id, p);
				this.productsArray.push(p);
			}
			
			//existing order
			for ( p in data.order.products) {
				subAdd(p.productId,p.quantity );
			}
			
			render();
			sortProductsBy();

		}
		req.request();
		
		//DISABLED : pb quand le panier est plus haut que l'ecran
		//scroll mgmt, only for large screens. Otherwise let the cart on page bottom.
		/*if (js.Browser.window.matchMedia("(min-width: 1024px)").matches) {
			
			jWindow = App.jq(js.Browser.window);
			cartContainer = App.jq("#cartContainer");
			cartTop = cartContainer.position().top;
			cartLeft = cartContainer.position().left;
			cartWidth = cartContainer.width();
			jWindow.scroll(onScroll);
			
		}*/ 	
		
		
	}
	
	/**
	 * keep the cart on top when scrolling
	 * @param	e
	 */
	// public function onScroll(e:Dynamic) {
		
	// 	//cart container top position		
		
	// 	if (jWindow.scrollTop() > cartTop) {
	// 		//trace("absolute !");
	// 		cartContainer.addClass("scrolled");
	// 		cartContainer.css('left', Std.string(cartLeft) + "px");			
	// 		cartContainer.css('top', Std.string(/*cartTop*/10) + "px");
	// 		cartContainer.css('width', Std.string(cartWidth) + "px");
			
	// 	}else {
	// 		cartContainer.removeClass("scrolled");
	// 		cartContainer.css('left',"");
	// 		cartContainer.css('top', "");
	// 		cartContainer.css('width', "");
	// 	}
	// }
	
}