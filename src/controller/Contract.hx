package controller;
import db.UserContract;
import sugoi.form.elements.DateDropdowns;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import db.Contract;
import Common;
import plugin.Tutorial;
using Std;

class Contract extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("contract/view.mtt")
	public function doView(c:db.Contract) {
		view.category = 'amap';
		view.c = c;
	}
	
	/**
	 * "my account" page
	 */
	@tpl("contract/default.mtt")
	function doDefault() {
		
		var ua = db.UserAmap.get(app.user, app.user.amap);
		if (ua == null) throw Error("/", t._("You're not a member of this group"));
		
		var constOrders = null;
		var varOrders = new Map<String,Array<db.UserContract>>();
		
		var a = App.current.user.amap;		
		var oneMonthAgo = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30);
		
		//commandes fixes
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == a && $endDate > oneMonthAgo, false);		
		constOrders = [];
		for ( c in contracts){
			var orders = app.user.getOrdersFromContracts([c]);
			if (orders.length == 0) continue;
			constOrders.push({contract:c, orders:db.UserContract.prepare(orders) });
		}
				
		//commandes variables groupées par date de distrib
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == a && $endDate > oneMonthAgo, false);
		
		for (c in contracts) {
			var ds = c.getDistribs(false);
			for (d in ds) {
				//store orders in a stringmap like "2015-01-01" => [order1,order2,...]
				var k = d.date.toString().substr(0, 10);
				var orders = app.user.getOrdersFromDistrib(d);
				if (orders.length > 0) {
					if (!varOrders.exists(k)) {
						varOrders.set(k, Lambda.array(orders));
					}else {
						var z = varOrders.get(k).concat(Lambda.array(orders));
						varOrders.set(k, z);
					}	
				}
			}
		}
		
		//struct finale
		var varOrders2 = new Array<{date:Date,orders:Array<UserOrder>}>();
		for ( k in varOrders.keys()) {

			var d = new Date(k.split("-")[0].parseInt(), k.split("-")[1].parseInt() - 1, k.split("-")[2].parseInt(), 0, 0, 0);
			
			var orders = db.UserContract.prepare( Lambda.list(varOrders[k]) );
			
			varOrders2.push({date:d,orders:orders});
			

		}
		
		//trier la map par ordre chrono desc
		varOrders2.sort(function(b, a) {
			return Math.round(a.date.getTime()/1000)-Math.round(b.date.getTime()/1000);
		});
		
		view.varOrders = varOrders2;
		view.constOrders = constOrders;
		
		
		// tutorials
		if (app.user.isAmapManager()) {
			
			app.user.lock();
			//actions
			if (app.params.exists('startTuto') ) {
				
				//start a tuto
				var t = app.params.get('startTuto'); 
				app.user.tutoState = {name:t,step:0};
				app.user.update();
				
			}else if (app.params.exists('stopTuto')) {
				
				//stopped tuto from a tuto window
				app.user.tutoState = null;
				app.user.update();	
				view.stopTuto = true;
			}
			
		
			//tuto state
			var tutos = new Array<{name:String,completion:Float,key:String}>();
			
			for ( k in Tutorial.all().keys() ) {	
				var t = Tutorial.all().get(k);
				
				var completion = null;
				if (app.user.tutoState!=null && app.user.tutoState.name == k) completion = app.user.tutoState.step / t.steps.length;
				
				tutos.push( { name:t.name, completion:completion , key:k } );
			}
			
			view.tutos = tutos;
			
		}
		
		checkToken();
		
		view.userAmap = ua;
		
	}

	/**
	 * Edit a contract 
	 */
	@tpl("form.mtt")
	function doEdit(c:db.Contract) {
		view.category = 'contractadmin';
		if (!app.user.isContractManager(c)) throw Error('/', t._("Forbidden action"));
		
		var currentContact = c.contact;
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		form.removeElement(form.getElement("type"));
		form.getElement("userId").required = true;
		
		if (form.checkToken()) {
			form.toSpod(c);
			c.amap = app.user.amap;
			
			//checks & warnings
			if (c.hasPercentageOnOrders() && c.percentageValue==null) throw Error("/contract/edit/"+c.id, t._("If you would like to add fees to the order, define a rate (%) and label."));
			
			if (c.hasStockManagement()) {
				for (p in c.getProducts()) {
					if (p.stock == null) {
						app.session.addMessage(t._("Warning about management of stock. Please fill the field \"stock\" for all your products"), true);
						break;
					}
				}
			}
			
			//no stock mgmt for constant orders
			if (c.hasStockManagement() && c.type==db.Contract.TYPE_CONSTORDERS) {
				c.flags.unset(ContractFlags.StockManagement);
				app.session.addMessage(t._("Managing stock is not available for CSA contracts"), true);
			}
			
			
			c.update();
			
			//update rights
			if ( c.contact != null && (currentContact==null || c.contact.id!=currentContact.id) ) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
				
				//remove rights to old contact
				if (currentContact != null) {
					var x = db.UserAmap.get(currentContact, c.amap, true);
					if (x != null) {
						x.removeRight(ContractAdmin(c.id));
						x.update();						
					}
				}
				
			}
			
			throw Ok("/contractAdmin/view/"+c.id, t._("Contract updated"));
		}
		
		view.form = form;
	}
	
	@tpl("contract/insertChoose.mtt")
	function doInsertChoose() {
		//checkToken();
		
	}
	
	/**
	 * Créé un nouveau contrat
	 */
	@tpl("form.mtt")
	function doInsert(?type:Int) {
		if (!app.user.isAmapManager()) throw Error('/', t._("Forbidden action"));
		if (type == null) throw Redirect('/contract/insertChoose');
		
		view.title = if (type == db.Contract.TYPE_CONSTORDERS)t._("Create a contract with fixed orders") else t._("Create a contract with variable orders");
		
		var c = new db.Contract();
		
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		form.removeElement(form.getElement("type"));
		form.getElement("userId").required = true;
			
		if (form.checkToken()) {
			form.toSpod(c);
			c.amap = app.user.amap;
			//trace(app.user.amap);
			//trace(c.amap);
			c.type = type;
			c.insert();
			
			//right
			if (c.contact != null) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
			}
			
			throw Ok("/contractAdmin/view/"+c.id, t._("New contract created"));
		}
		
		view.form = form;
	}
	
	function doDelete(c:db.Contract/*,args:{chk:String}*/) {
		
		if (!app.user.isAmapManager()) throw Error("/contractAdmin", t._("You don't have authorization to remove a contract"));
		
		if (checkToken()) {
			c.lock();
			
			//verif qu'il n'y a pas de commandes sur ce contrat
			var products = c.getProducts();
			var orders = db.UserContract.manager.count($productId in Lambda.map(products, function(p) return p.id));
			if (orders > 0) {
				throw Error("/contractAdmin", t._("You cannot delete this contract because some orders are linked to it."));
			}
			
			//remove admin rights and delete contract	
			if(c.contact!=null){
				var ua = db.UserAmap.get(c.contact, c.amap, true);
				if (ua != null) {
					ua.removeRight(ContractAdmin(c.id));
					ua.update();	
				}			
			}
			
			app.event(DeleteContract(c));
			
			c.delete();
			throw Ok("/contractAdmin", t._("Contract deleted"));
		}
		
		throw Error("/contractAdmin", t._("Token error"));
	}
	
	/**
	 * Make an order by contract ( standard mode )
	 * The form is prepopulated if orders have already been made.
	 * 
	 * It should work for constant orders ( will display one column )
	 * or varying orders ( with as many columns as distributions dates )
	 * 
	 */
	@tpl("contract/order.mtt")
	function doOrder(c:db.Contract ) {
		
		//checks
		if (app.user.amap.hasPayments()) throw Redirect("/contract/orderAndPay/" + c.id);
		if (app.user.amap.hasShopMode()) throw Redirect("/shop");
		if (!c.isUserOrderAvailable()) throw Error("/", t._("This contract is not opened for orders"));

		
		var distributions = [];
		// If its a varying contract, we display a column by distribution
		if (c.type == db.Contract.TYPE_VARORDER) {
			distributions = db.Distribution.getOpenToOrdersDeliveries(c);
		}else{
			distributions = [null];
		}
		
		//list of distribs with a list of product and optionnaly an order
		var userOrders = new Array< {distrib:db.Distribution,datas:Array<{order:db.UserContract,product:db.Product}>} >();
		var products = c.getProducts();
		
		if ( c.type == db.Contract.TYPE_VARORDER ){
			
			for ( d in distributions){
				var datas = [];
				for ( p in products) {
					var ua = { order:null, product:p };
					
					var order = db.UserContract.manager.select($user == app.user && $productId == p.id && $distributionId==d.id, true);	
					
					if (order != null) ua.order = order;
					datas.push(ua);
				}
				
				userOrders.push({distrib:d,datas:datas});
			}
			
		}else{
			
			var datas = [];
			for ( p in products) {
				var ua = { order:null, product:p };
				
				var order = db.UserContract.manager.select($user == app.user && $productId == p.id, true);
				
				if (order != null) ua.order = order;
				datas.push(ua);
			}
			
			userOrders.push({distrib:null,datas:datas});
			
		}

		
		//form check
		if (checkToken()) {
			
			//get dsitrib if needed
			//var distrib : db.Distribution = null;
			//if (c.type == db.Contract.TYPE_VARORDER) {
				//distrib = db.Distribution.manager.get(Std.parseInt(app.params.get("distribution")), false);
			//}
			
			for (k in app.params.keys()) {
				
				if (k.substr(0, 1) != "d") continue;
				var qt = app.params.get(k);
				if (qt == "") continue;
				
				var pid = null;
				var did = null;
				try{
				pid = Std.parseInt(k.split("-")[1].substr(1));
				did = Std.parseInt(k.split("-")[0].substr(1));
				}catch (e:Dynamic){trace("unable to parse key "+k); }
				
				//find related element in userOrders
				var uo = null;
				for ( x in userOrders){
					if (x.distrib!=null && x.distrib.id != did) {
						continue;
					}else{
						for (a in x.datas){
							if (a.product.id == pid){
								uo = a;
								break;
							}
						}
					}
				}
				
				if (uo == null) throw t._("Could not find the product ::produ:: and delivery ::deliv::", {produ:pid, deliv:did});
					
				var q = 0.0;
				
				if (uo.product.hasFloatQt ) {
					var param = StringTools.replace(qt, ",", ".");
					q = Std.parseFloat(param);
				}else {
					q = Std.parseInt(qt);
				}
				
				
				if (uo.order != null) {	
					//trace("updating order q="+q);
					db.UserContract.edit(uo.order, q);
					
				}else {
					//trace("new order q="+q);
					db.UserContract.make(app.user, q, uo.product, did);
				}
				
			}
			throw Ok("/contract/order/"+c.id, t._("Your order has been updated"));
		}
		
		view.c = view.contract = c;
		view.userOrders = userOrders;
	}
	
	
	/**
	 * Make an order by contract ( standard mode ) + payment process
	 */
	@tpl("contract/orderAndPay.mtt")
	function doOrderAndPay(c:db.Contract ) {
		
		//checks
		if (!app.user.amap.hasPayments()) throw Redirect("/contract/order/" + c.id);
		if (app.user.amap.hasShopMode()) throw Redirect("/");
		if (!c.isUserOrderAvailable()) throw Error("/", t._("This contract is not opened for orders"));
		
		var distributions = [];
		/* If its a varying contract, we display a column by distribution*/
		if (c.type == db.Contract.TYPE_VARORDER) {
			distributions = db.Distribution.getOpenToOrdersDeliveries(c);
		}
		
		//list of distribs with a list of product and optionnaly an order
		var userOrders = new Array< {distrib:db.Distribution,datas:Array<{order:db.UserContract,product:db.Product}>} >();
		var products = c.getProducts();
		
		for ( d in distributions){
			var datas = [];
			for ( p in products) {
				var ua = { order:null, product:p };
				
				var order : db.UserContract = null;
				if (c.type == db.Contract.TYPE_VARORDER) {
					order = db.UserContract.manager.select($user == app.user && $productId == p.id && $distributionId==d.id, true);	
				}else {
					order = db.UserContract.manager.select($user == app.user && $productId == p.id, true);
				}
				
				if (order != null) ua.order = order;
				datas.push(ua);
			}
			
			userOrders.push({distrib:d,datas:datas});
		}
		
		
		//form check
		if (checkToken()) {
			
			//get distrib if needed
			var distrib = null;
			if (c.type == db.Contract.TYPE_VARORDER) {
				distrib = db.Distribution.manager.get(Std.parseInt(app.params.get("distribution")), false);
			}
			
			var orders : OrderInSession = {products:[],userId:app.user.id,total:0};
			
			for (k in app.params.keys()) {
				
				if (k.substr(0, 1) != "d") continue;
				var qt = app.params.get(k);
				if (qt == "") continue;
				
				var pid = null;
				var did = null;
				try{
					pid = Std.parseInt(k.split("-")[1].substr(1));
					did = Std.parseInt(k.split("-")[0].substr(1));
				}catch (e:Dynamic){
					trace("unable to parse key "+k);					
				}
				
				//find related element in userOrders
				var uo = null;
				for ( x in userOrders){
					if (x.distrib!=null && x.distrib.id != did) {
						continue;
					}else{
						for (a in x.datas){
							if (a.product.id == pid){
								uo = a;
								break;
							}
						}
					}
				}
				
				if (uo == null) throw t._("Could not find the product ::produ:: and delivery ::deliv::", {produ:pid, deliv:did});
					
				//quantity
				var q = 0.0;				
				if (uo.product.hasFloatQt ) {
					var param = StringTools.replace(qt, ",", ".");
					q = Std.parseFloat(param);
				}else {
					q = Std.parseInt(qt);
				}
				
				orders.products.push({productId:pid, quantity:q, distributionId:did});
				
				var p = db.Product.manager.get(pid, false);
				orders.total += p.getPrice() * q;
				
			}
			
			App.current.session.data.order = orders;
			
			//Go to payments page			
			if (c.type == db.Contract.TYPE_CONSTORDERS) {
				throw Ok("/contract/order/"+c.id, t._("Your CSA order has been saved"));
			}else{
				throw Ok("/transaction/pay/", t._("In order to save your order, please choose a means of payment."));
			}
			
			
			
		}
		
		view.c = view.contract = c;
		view.userOrders = userOrders;		
	}
	
	
	/**
	 * A user edit an order for a multidistrib.
	 */
	@tpl("contract/orderByDate.mtt")
	function doEditOrderByDate(date:Date) {
		
		if (app.user.amap.hasPayments()) {
			//when payments are active, the user cannot modify his order
			throw Redirect("/");
		}
		
		// cannot edit order if date is in the past
		if (Date.now().getTime() > date.getTime()) {
			
			var msg = t._("This delivery has already taken place, you can no longer modify the order.");
			if (app.user.isContractManager()) msg += t._("<br/>As the manager of the contract you can modify the order from this page: <a href='/contractAdmin'>Management of contracts</a>");
			
			throw Error("/contract", msg);
		}
		
		// Il faut regarder le contrat de chaque produit et verifier si le contrat est toujours ouvert à la commande.		
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

		var cids = Lambda.map(app.user.amap.getActiveContracts(true), function(c) return c.id);
		var distribs = db.Distribution.manager.search(($contractId in cids) && $date >= d1 && $date <=d2 , false);
		var orders = db.UserContract.manager.search($userId==app.user.id && $distributionId in Lambda.map(distribs,function(d)return d.id)  );
		view.orders = db.UserContract.prepare(orders);
		view.date = date;
		
		//form check
		if (checkToken()) {
			
			var orders_out = [];
			
			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var order = Lambda.find(orders, function(uo) return uo.product.id == pid);
					if (order == null) throw t._("Error, not possible to find the order");
					
					var q = 0.0;
					if (order.product.hasFloatQt ) {
						param = StringTools.replace(param, ",", ".");
						q = Std.parseFloat(param);
					}else {
						q = Std.parseInt(param);
					}
					
					var quantity = Math.abs( q==null?0:q );

					if ( order.distribution.canOrderNow() ) {
						//met a jour la commande
						var o = db.UserContract.edit(order, quantity);
						if(o!=null) orders_out.push( o );
					}					
				}
			}
			
			app.event(MakeOrder(orders_out));
			
			throw Ok("/contract", t._("Your order has been updated"));
		}
	}
}
