package service;

import db.Catalog;
import haxe.Json;
import db.Operation;
import Common;
import tink.core.Error;

enum PaymentContext {
	PCAll;
	PCGroupAdmin;
	PCPayment;
	PCManualEntry;
}

/**
 * Payment Service
 * @author web-wizard,fbarbut
 */
class PaymentService {
	/**
	 * Record a new payment operation
	 */
	public static function makePaymentOperation(user:db.User, group:db.Group, type:String, amount:Float, name:String, ?relation:db.Operation,?remoteOpId:String):db.Operation {
		if (type == payment.OnTheSpotPayment.TYPE) {
			var onTheSpotAllowedPaymentTypes = service.PaymentService.getOnTheSpotAllowedPaymentTypes(group);
			if (onTheSpotAllowedPaymentTypes.length == 1) {
				// There is only one on the spot payment type so we can directly set it here
				type = onTheSpotAllowedPaymentTypes[0].type;
			}

			if (relation != null) {
				var relatedPaymentOperations = relation.getRelatedPayments();
				for (operation in relatedPaymentOperations) {
					if (operation.getData().type == payment.OnTheSpotPayment.TYPE
						|| Lambda.has(payment.OnTheSpotPayment.getPaymentTypes(), operation.getData().type)) {
						// if we already had an onTheSpot payment, lets reuse it.
						return updatePaymentOperation(user, group, operation, amount);
					}
				}
			}
		}

		var operation = new db.Operation();
		operation.amount = Math.abs(amount);
		operation.date = Date.now();
		operation.name = name;
		operation.group = group;
		operation.pending = true;
		operation.user = user;
		operation.type = Payment;
		var data:PaymentInfos = {type: type};
		if (remoteOpId != null) {
			data.remoteOpId = remoteOpId;
		}
		operation.setData(data);
		if (relation != null)
			operation.relation = relation;
		operation.insert();

		service.PaymentService.updateUserBalance(user, group);

		return operation;
	}

	/**
	 * Update a payment operation
	 */
	public static function updatePaymentOperation(user:db.User, group:db.Group, operation:db.Operation, amount:Float):db.Operation {
		operation.lock();
		operation.amount += Math.abs(amount);
		operation.update();
		service.PaymentService.updateUserBalance(user, group);
		return operation;
	}

	/**
	 * Create a new order operation
	 */
	 public static function makeOrderOperation( orders : Array<db.UserOrder>, basket : db.Basket ) {
		
		if (orders == null) throw "orders are null";
		if (orders.length == 0) throw "no orders";
		if (orders[0].user == null ) throw "no user in order";

		//check that we dont have a mix of variable and CSA
		var catalog = orders[0].product.catalog;
		for (o in orders) {
			if (o.product.catalog.type != catalog.type)
				throw new Error("Cannot record an order operation with catalogs of different types");
		}

		var t = sugoi.i18n.Locale.texts;

		var _amount = 0.0;
		for (o in orders) {
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}

		var op = new db.Operation();
		var user = orders[0].user;
		var group = catalog.group;
		
		if (basket == null)
			throw new Error("variable orders should have a basket");
		if (basket.user.id != user.id)
			throw new Error("user and basket mismatch");

		// varying orders
		var date = App.current.view.dDate(orders[0].distribution.date);
		op.name = t._("Order for ::date::", {date: date});
		op.amount = 0 - _amount;
		op.date = Date.now();
		op.type = VOrder;
		op.basket = basket;
		op.user = user;
		op.group = group;
		op.pending = true;

		op.insert();
		updateUserBalance(op.user, op.group);
		return op;
	}

	/**
	 * update an order operation
	 */
	public static function updateOrderOperation(op:db.Operation, orders:Array<db.UserOrder>, ?basket:db.Basket) {
		op.lock();
		var t = sugoi.i18n.Locale.texts;

		var _amount = 0.0;
		for (o in orders) {
			var a = o.quantity * o.productPrice;
			_amount += a + a * (o.feesRate / 100);
		}

		var contract = orders[0].product.catalog;
		if (contract.type == db.Catalog.TYPE_CONSTORDERS) {
			// Constant orders
			var dNum = contract.getDistribs(false).length;
			op.name = "" + contract.name + " (" + contract.vendor.name + ") " + dNum + " " + t._("deliveries");
			op.amount = dNum * (0 - _amount);
		} else {
			if (basket == null)
				throw "varying contract orders should have a basket";
			op.amount = 0 - _amount;
		}

		// op.date = Date.now();	//leave original date
		op.update();
		service.PaymentService.updateUserBalance(op.user, op.group);
		return op;
	}
	
	
	/**
	 * when updating a (varying) order , we need to update the existing pending transaction
	 */
	public static function findVOrderOperation(distrib:db.MultiDistrib, user:db.User, ?onlyPending = true):db.Operation {
		// throw 'find $dkey for user ${user.id} in group ${group.id} , onlyPending:$onlyPending';
		if (distrib == null)
			throw "Distrib is null";
		if (user == null)
			throw "User is null";
		var basket = db.Basket.get(user, distrib);
		if (basket == null)
			return null; /*throw new Error('No basket found for user #'+user.id+', md #'+distrib.id );*/

		if (onlyPending) {
			return db.Operation.manager.select($basket == basket && $type == VOrder && $pending == true, true);
		} else {
			return db.Operation.manager.select($basket == basket && $type == VOrder, true);
		}
	}

	/**
		Create/update the needed order operations and returns the related operations.
		Can handle orders happening on different multidistribs.
		Orders are supposed to be from the same user.
	 */
	public static function onOrderConfirm( orders : Array<db.UserOrder> ) : Array<db.Operation> { 

		var out = [];
	
		//make sure we dont have null orders in the array
		orders = orders.filter( o -> return o!=null );
		if (orders.length == 0) return null;
		
		for( o in orders){
			if(o.user==null){
				throw new Error("order "+o.id+" has no user");
			} 
			
			if(o.user.id!=orders[0].user.id){
				throw new Error("Those orders are from different users");
			}
		}

		var user = orders[0].user;
		var group = orders[0].product.catalog.group;
		
		// varying contract :
		// manage separatly orders which occur at different dates
		var ordersGroup = null;
		try {
			ordersGroup = tools.ObjectListTool.groupOrdersByKey(orders);
		} catch (e:Dynamic) {
			App.current.logError(service.OrderService.prepare(orders));
			neko.Lib.rethrow(e);
		}
		
		for ( orders in ordersGroup ) {
			
			//find basket
			var basket = null;
			for (o in orders) {
				if (o.basket != null) {
					basket = o.basket;
					break;
				}
			}

			var distrib = basket.multiDistrib;

			// get all orders for the same multidistrib, in order to update related operation.
			var allOrders = distrib.getUserOrders(user, db.Catalog.TYPE_VARORDER);

			// existing transaction
			var existing = findVOrderOperation(distrib, user, false);

			var op;
			if (existing != null) {
				op = updateOrderOperation(existing, allOrders, basket);
			} else {
				op = makeOrderOperation(allOrders, basket);
			}
			out.push(op);

			// delete order and payment operations if sum of orders qt is 0
			/*var sum = 0.0;
				for ( o in allOrders) sum += o.quantity;
				if ( sum == 0 ) {
					existing.delete();
					op.delete();
			}*/
		}
			
		return out;
	}

	/**
	 * MIGRATED
	 * 
	 * Retuns an array of payment types depending on the use case
	 * @param context
	 * @param group
	 * @return Array<payment.PaymentType>
	 */
	public static function getPaymentTypes(context: PaymentContext, ?group: db.Group) : Array<payment.PaymentType>
	{
		var out : Array<payment.PaymentType> = [];

		switch(context)
		{
			//every payment type
			case PCAll:
				var types = [
					new payment.Cash(),
					new payment.Check(),
					new payment.Transfer(),	
					new payment.MoneyPot(),
					new payment.OnTheSpotPayment(),
					new payment.OnTheSpotCardTerminal()						
				];
				var e = App.current.event(GetPaymentTypes({types:types}));
				out = switch(e) {
						case GetPaymentTypes(d): d.types;
						default : null;
					}

			//when selecting wich payment types to enable
			case PCGroupAdmin:
				var allPaymentTypes = getPaymentTypes(PCAll);
				//Exclude On the spot payment
				var onTheSpot = Lambda.find(allPaymentTypes, function(x) return x.type == payment.OnTheSpotPayment.TYPE);
				allPaymentTypes.remove(onTheSpot);
				out = allPaymentTypes;


			//For the payment page
			case PCPayment:
				if ( group.allowedPaymentsType == null ) return [];
				//ontheSpot payment type replaces checks or cash
			
				var hasOnTheSpotPaymentTypes = false;
				var all = getPaymentTypes(PCAll);
				for ( paymentTypeId in group.allowedPaymentsType ){
					var found = all.find(function(a) return a.type == paymentTypeId);
					if (found != null)  {
						if(found.onTheSpot==true){
							hasOnTheSpotPaymentTypes = true;
						}else{
							out.push(found);
						}
					}
				}
				if(hasOnTheSpotPaymentTypes){
					out.push(new payment.OnTheSpotPayment());
				}

			
			//when a coordinator does a manual refund or adds manually a payment
			case PCManualEntry:
				//Exclude the MoneyPot payment
				var paymentTypesInAdmin = getPaymentTypes(PCGroupAdmin);
				var moneyPot = Lambda.find(paymentTypesInAdmin, function(x) return x.type == payment.MoneyPot.TYPE);
				paymentTypesInAdmin.remove(moneyPot);
				#if plugins
				//cannot make a mgp payment manually !!
				var mgp = paymentTypesInAdmin.find( x -> x.type == pro.payment.MangopayMPPayment.TYPE || x.type == pro.payment.MangopayECPayment.TYPE );
				paymentTypesInAdmin.remove(mgp);
				#end
				out = paymentTypesInAdmin;
		}
		return out;
	}

	/**
	 * Returns all the payment types that are on the spot and that are allowed for this group
	 * @param group
	 * @return Array<payment.PaymentType>
	 */
	public static function getOnTheSpotAllowedPaymentTypes(group:db.Group):Array<payment.PaymentType> {
		if (group.allowedPaymentsType == null)
			return [];
		var onTheSpotAllowedPaymentTypes:Array<payment.PaymentType> = [];
		var onTheSpotPaymentTypes = payment.OnTheSpotPayment.getPaymentTypes();
		var all = getPaymentTypes(PCAll);
		for (paymentType in onTheSpotPaymentTypes) {
			if (Lambda.has(group.allowedPaymentsType, paymentType)) {
				var found = Lambda.find(all, function(a) return a.type == paymentType);
				if (found != null) {
					onTheSpotAllowedPaymentTypes.push(found);
				}
			}
		}

		return onTheSpotAllowedPaymentTypes;
	}

	/**
	 * Auto validate a distribution.
	 * This is called by the hourly cron
	 *
	 * @param distrib
	 */
	public static function validateDistribution(distrib:db.MultiDistrib) {
		distrib.lock();

		// cannot be in future
		if (distrib.distribStartDate.getTime() > Date.now().getTime()) {
			throw new tink.core.Error("Vous ne pouvez pas valider cette distribution car elle n'a pas encore commencé");
		}

		for (user in distrib.getUsers()) {
			var basket = db.Basket.get(user, distrib);
			validateBasket(basket);
		}
		// finally validate distrib
		distrib.validated = true;
		distrib.update();
	}

	public static function unvalidateDistribution(distrib:db.MultiDistrib) {
		for (user in distrib.getUsers()) {
			var basket = db.Basket.get(user, distrib);
			unvalidateBasket(basket);
		}
		// finally validate distrib
		distrib.lock();
		distrib.validated = false;
		distrib.update();
	}

	/**
	 * Auto validate a basket
	 *
	 * @param basket
	 */
	public static function validateBasket(basket:db.Basket) {
		if (basket == null || basket.isValidated())
			return false;

		// This will throw an error if for example there are pending payments of type on the spot
		basket.canBeValidated();

		// mark orders as paid
		var orders = basket.getOrders();
		for (order in orders) {
			order.lock();
			order.paid = true;
			order.update();
		}

		// validate order operation and payments
		var operation = basket.getOrderOperation(false);
		if (operation != null) {
			operation.lock();
			operation.pending = false;
			operation.update();

			for (payment in basket.getPaymentsOperations()) {
				if (payment.pending) {
					payment.lock();
					payment.pending = false;
					payment.update();
				}
			}

			var o = orders[0];
			if (o.distribution == null)
				throw o.id + " order has no distrib";
			updateUserBalance(o.user, o.distribution.place.group);
		}

		App.current.event(ValidateBasket(basket));

		return true;
	}

	public static function unvalidateBasket(basket:db.Basket) {
		if (basket == null || !basket.isValidated())
			return false;

		// mark orders as paid
		var orders = basket.getOrders();
		for (order in orders) {
			order.lock();
			order.paid = false;
			order.update();
		}

		// validate order operation and payments
		var operation = basket.getOrderOperation(false);
		if (operation != null) {
			operation.lock();
			operation.pending = true;
			operation.update();

			for (payment in basket.getPaymentsOperations()) {
				if (!payment.pending) {
					payment.lock();
					payment.pending = true;
					payment.update();
				}
			}

			var o = orders[0];
			updateUserBalance(o.user, o.distribution.place.group);
		}

		return true;
	}

	/**
	 * update user balance
	 */
	public static function updateUserBalance(user:db.User, group:db.Group) {
		var ua = db.UserGroup.getOrCreate(user, group);
		var b = sys.db.Manager.cnx.request('SELECT SUM(amount) FROM Operation WHERE userId=${user.id} and groupId=${group.id} and !(type=2 and pending=1)')
			.getFloatResult(0);
		b = Math.round(b * 100) / 100;
		ua.balance = b;
		ua.update();
	}

	/**
		Get multidistrib turnover by payment type
	**/
	public static function getMultiDistribTurnoverByPaymentType(md:db.MultiDistrib):Map<String, {ht:Float, ttc:Float}> {
		var out = new Map<String, {ht:Float, ttc:Float}>();

		/*for( b in md.getBaskets()){
			for( op in b.getPaymentsOperations()){

			}
		}*/

		return out;
	}
}
