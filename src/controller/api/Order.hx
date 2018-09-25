package controller.api;
import haxe.Json;
import tink.core.Error;
import service.OrderService;

/**
 * Public order API
 */
class Order extends Controller
{
	/**
	 * get orders of a user from a contractId (constant contract) or a distributionId (varying contract)
	 */
	public function doGet(userId:Int){

		checkIsLogged();
		
		//params
		var p = app.params;
		var distributionId = Std.parseInt(p.get("distributionId"));
		var contractId = Std.parseInt(p.get("contractId"));
		if (distributionId == null && contractId == null) throw "You should provide a contractId or a distributionId";
		var user = db.User.manager.get(userId, false);
		if (user == null) throw 'user #$userId doesn\'t exists';
		var c : db.Contract = null;
		var d : db.Distribution = null;
		if (distributionId == null) {
			c = db.Contract.manager.get(contractId, false);
		}else{
			d = db.Distribution.manager.get(distributionId, false);
			c = d.contract;
		}
		
		//rights	
		if (!app.user.canManageContract(c)) throw t._("You do not have the authorization to manage this contract");
		if (d != null && d.validated) throw t._("This delivery has been already validated");
		if (c.type == db.Contract.TYPE_VARORDER && d == null ) throw "this contract is a 'varying order contract', please provide a distributionId";
		
		//get datas
		var pids = tools.ObjectListTool.getIds(c.getProducts(false));
		var orders;		
		if (c.type == db.Contract.TYPE_VARORDER) {
			orders = db.UserContract.manager.search($user == user && $distributionId==d.id && ($productId in pids), true);	
		}else {
			orders = db.UserContract.manager.search($user == user && ($productId in pids), true);
		}
		var orders = OrderService.prepare(orders);
		
		Sys.print(tink.Json.stringify({success:true,orders:orders}));
	}
	
	/**
	 * Update orders of a user ( from react OrderBox component )
	 * @param	userId
	 */
	public function doUpdate(userId:Int){

		checkIsLogged();
		
		//GET params
		var p = app.params;
		var distributionId = Std.parseInt(p.get("distributionId"));
		var contractId = Std.parseInt(p.get("contractId"));

		//POST payload
		var data = new Array<{id:Int,productId:Int,qt:Float,paid:Bool,invertSharedOrder:Bool,userId2:Int}>();
		data = haxe.Json.parse( StringTools.urlDecode(sugoi.Web.getPostData()) ).orders;
		
		if (distributionId == null && contractId == null) throw "You should provide a contractId or a distributionId";
		var user = db.User.manager.get(userId, false);
		if (user == null) throw 'user #$userId doesn\'t exists';
		
		var c : db.Contract = null;
		var d : db.Distribution = null;
		if (distributionId == null) {
			c = db.Contract.manager.get(contractId, false);
		}else{
			d = db.Distribution.manager.get(distributionId, false);
			c = d.contract;
		}
		var pids = tools.ObjectListTool.getIds(c.getProducts(false));
		
		//rights & checks
		if (!user.isMemberOf(c.amap)) throw t._("::user:: is not member of this group", {user:user.name});
		if (!app.user.canManageContract(c)) throw t._("You do not have the authorization to manage this contract");
		if (d != null && d.validated) throw t._("This delivery has been already validated");
		if (c.type == db.Contract.TYPE_VARORDER && d == null ) throw "this contract is a 'varying order contract', please provide a distributionId";
		
		/*
		 * record orders
		 **/ 
		
		//find existing orders
		var exOrders = null;
		if (c.type == db.Contract.TYPE_VARORDER) {
			exOrders = db.UserContract.manager.search($user == user && $distributionId==d.id && ($productId in pids), true);	
		}else {
			exOrders = db.UserContract.manager.search($user == user && ($productId in pids), true);
		}
		
		var orders = [];
		for (o in data) {
			
			//get product
			var product = db.Product.manager.get(o.productId, false);
			if (product.contract.id != c.id) throw "product " + o.productId + " is not in contract " + c.id;
			
			//find existing order				
			var uo = Lambda.find(exOrders, function(uo) return uo.id == o.id);
				
			//user2 + invert
			var user2 : db.User = null;
			var invert = false;
			if ( o.userId2 != null ) {
				user2 = db.User.manager.get(o.userId2,false);
				if (user2 == null) throw t._("Unable to find user #::num::",{num:o.userId2});
				if (!user2.isMemberOf(product.contract.amap)) throw t._("::user:: is not part of this group",{user:user2});
				if (user.id == user2.id) throw t._("Both selected accounts must be different ones");
				
				invert = o.invertSharedOrder;
			}
			
			//record order
			if (uo != null) {
				//existing record
				var o = OrderService.edit(uo, o.qt, o.paid , user2, invert);
				if (o != null) orders.push(o);
			}else {
				//new record
				var o =  OrderService.make(user, o.qt , product, d == null ? null : d.id, o.paid , user2, invert);
				if (o != null) orders.push(o);
			}
		}
		
		app.event(MakeOrder(orders));
		db.Operation.onOrderConfirm(orders);
		
		Sys.print(Json.stringify({success:true, orders:data}));
	}
	
}