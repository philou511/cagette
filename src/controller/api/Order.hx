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

	function checkRights(user:db.User,contract:db.Contract,multiDistrib:db.MultiDistrib){

		if( contract==null && multiDistrib==null ) throw new Error("You should provide at least a contract or a multiDistrib");
		if( contract!=null && contract.type==db.Contract.TYPE_CONSTORDERS && multiDistrib!=null ) throw new Error("You cant edit a CSA contract for a multiDistrib");
		
		//rights	
		if (contract==null && !app.user.canManageAllContracts()) throw new Error(403,t._("Forbidden access"));
		if (contract!=null && !app.user.canManageContract(contract)) throw new Error(403,t._("You do not have the authorization to manage this catalog"));
		if ( multiDistrib != null && multiDistrib.isValidated() ) throw new Error(t._("This delivery has been already validated"));
	}

	/**
		Get orders of a user for a multidistrib.
		Possible to filter for a distribution only
		(Used by OrderBox react component)

		contract arg : we want to edit the orders of one single catalog/contract
		multiDistrib arg : we want to edit the orders of the whole distribution
	 */	
	public function doGet(user:db.User,args:{?contract:db.Contract,?multiDistrib:db.MultiDistrib}){

		checkIsLogged();
		var contract = (args!=null && args.contract!=null) ? args.contract : null;
		var multiDistrib = (args!=null && args.multiDistrib!=null) ? args.multiDistrib : null;

		checkRights(user,contract,multiDistrib);
		
		//get datas
		var orders =[];

		if(contract==null){
			//we edit a whole multidistrib, edit only var orders.
			orders = multiDistrib.getUserOrders(user , db.Contract.TYPE_VARORDER);
		}else{
			//edit a single catalog, may be CSA or variable
			var d = null;
			if(multiDistrib!=null){
				d = multiDistrib.getDistributionForContract(contract);
			}
			orders = contract.getUserOrders(user, d);			
		}

		var orders = OrderService.prepare(orders);		
		Sys.print( tink.Json.stringify({success:true,orders:orders}) );
	}
	
	/**
	 * Update orders of a user ( from react OrderBox component )
	 * @param	userId
	 */
	public function doUpdate( user:db.User, args:{?contract:db.Contract,?multiDistrib:db.MultiDistrib} ){

		checkIsLogged();
		var contract = (args!=null && args.contract!=null) ? args.contract : null;
		var multiDistrib = (args!=null && args.multiDistrib!=null) ? args.multiDistrib : null;
		checkRights(user,contract,multiDistrib);
		
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
		if (multiDistrib!=null && multiDistrib.isValidated()) throw new Error(t._("This delivery has been already validated"));
		
		//record orders
	
		//find existing orders
		var exOrders = [];
		if(contract==null){
			//we edit a whole multidistrib
			exOrders = multiDistrib.getUserOrders(user);
		}else{
			//edit a single catalog
			var d = null;
			if(multiDistrib!=null){
				d = multiDistrib.getDistributionForContract(contract);
			}
			exOrders = contract.getUserOrders(user, d);			
		}
				
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
				var distrib = null; //no need if csa contract
				if( contract.type != db.Contract.TYPE_CONSTORDERS ) {

					distrib = multiDistrib.getDistributionFromProduct(product);
				}
				
				var o =  OrderService.make(user, o.qt , product, distrib == null ? null : distrib.id, o.paid , user2, invert);
				if (o != null) orders.push(o);
			}
		}
		
		app.event(MakeOrder(orders));
		db.Operation.onOrderConfirm(orders);
		
		Sys.print(Json.stringify({success:true, orders:data}));
	}


	
	
}