package controller.api;
import haxe.Json;
import tink.core.Error;
import service.OrderService;
import Common;

/**
 * Public order API
 */
class Order extends Controller
{
	public function doContracts( multiDistrib : db.MultiDistrib, ?args : { contractType : Int } ) {

		var contracts = new Array<ContractInfo>();
		var type = ( args != null && args.contractType != null ) ? args.contractType : null;
		for( distrib in multiDistrib.getDistributions(type) ) {
			
			var image = distrib.contract.vendor.image == null ? null : view.file( distrib.contract.vendor.image );
			contracts.push( { id : distrib.contract.id, name : distrib.contract.name, image : image } );
		}

		Sys.print( Json.stringify({ success : true, contracts : contracts }) );

	}

	/**
		Get orders of a user for a multidistrib.
		Possible to filter for a distribution only
	 */	
	public function doGet(user:db.User,multiDistrib:db.MultiDistrib,?args:{contract:db.Contract}){

		checkIsLogged();
		
		var contract = (args!=null && args.contract!=null) ? args.contract : null;
		
		//rights	
		if (!app.user.canManageAllContracts()) throw new Error(t._("You do not have the authorization to manage this contract"));
		if (multiDistrib.isValidated()) throw new Error(t._("This delivery has been already validated"));
		
		//get datas
		var orders =[];

		if(contract==null){
			orders = multiDistrib.getUserOrders(user);
		}else{
			orders = Lambda.array(multiDistrib.getDistributionForContract(contract).getUserOrders(user));
		}

		var orders = OrderService.prepare(orders);		
		Sys.print(tink.Json.stringify({success:true,orders:orders}));
	}
	
	/**
	 * Update orders of a user ( from react OrderBox component )
	 * @param	userId
	 */
	public function doUpdate(user:db.User,multiDistrib:db.MultiDistrib){

		checkIsLogged();
		
		//GET params
		var p = app.params;
		

		//POST payload
		var data = new Array<{id:Int,productId:Int,qt:Float,paid:Bool,invertSharedOrder:Bool,userId2:Int}>();
		var raw = StringTools.urlDecode(sugoi.Web.getPostData());
		
		if(raw==null){
			throw new Error("Order datas are null");
		}else{
			data = haxe.Json.parse(raw).orders;
		}
		
		//rights
		//fbarbut 2018-11-13 : too many problems when people try to edit the order of someone who left the group...
		//if (!user.isMemberOf(c.amap)) throw new Error(t._("::user:: is not member of this group", {user:user.name}));
		if (!app.user.canManageAllContracts()) throw new Error(t._("You do not have the authorization to manage this contract"));
		if (multiDistrib.isValidated()) throw new Error(t._("This delivery has been already validated"));
		
		//record orders
	
		//find existing orders
		var exOrders = multiDistrib.getUserOrders(user);
				
		var orders = [];
		for (o in data) {
			
			//get product
			var product = db.Product.manager.get(o.productId, false);
			//if (product.contract.id != c.id) throw "product " + o.productId + " is not in contract " + c.id;
			
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
				var d = multiDistrib.getDistributionFromProduct(product);
				if(d.contract.type==db.Contract.TYPE_CONSTORDERS) d = null; //no need if csa contract

				var o =  OrderService.make(user, o.qt , product, d == null ? null : d.id, o.paid , user2, invert);
				if (o != null) orders.push(o);
			}
		}
		
		app.event(MakeOrder(orders));
		db.Operation.onOrderConfirm(orders);
		
		Sys.print(Json.stringify({success:true, orders:data}));
	}


	
	
}