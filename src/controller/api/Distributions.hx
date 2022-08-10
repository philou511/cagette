package controller.api;

import pro.payment.MangopayECPayment;
import mangopay.Mangopay;
import mangopay.MangopayPlugin;
import haxe.DynamicAccess;
import tink.core.Error;
import db.UserGroup;
import haxe.Json;
import Common;
import db.MultiDistrib;
import service.VolunteerService;
import service.DistributionService;

class Distributions extends Controller {
	
	public function new() {
		super();
	}

	/**
		multidistribs data for volunteer roles assignements calendar
	**/
	function doVolunteerRolesCalendar(from:Date,to:Date){

		var group = app.getCurrentGroup();
		var user = app.user;
		var multidistribs = db.MultiDistrib.getFromTimeRange(group, from, to);
		var uniqueRoles = VolunteerService.getUsedRolesInMultidistribs(multidistribs);
		var out = {
			 multiDistribs: new Array(),
			 roles: uniqueRoles.map(function(r) 
				return {
					id: r.id,
					name: r.name
				}
			)
		};

		for( md in multidistribs){
			var o = {
				id 					: md.id,
				distribStartDate	: md.distribStartDate,
				hasVacantVolunteerRoles: md.hasVacantVolunteerRoles(),
				canVolunteersJoin	: md.canVolunteersJoin(),
				volunteersRequired	: md.getVolunteerRoles().length,
				volunteersRegistered: md.getVolunteers().length,
				hasVolunteerRole	: null,
				volunteerForRole 	: null,
			};

			//populate hasVolunteerRole
			var hasVolunteerRole:Dynamic = {};
			for( role in uniqueRoles ){
				Reflect.setField(hasVolunteerRole,Std.string(role.id),md.hasVolunteerRole(role));
			}
			o.hasVolunteerRole = hasVolunteerRole;

			//populate volunteerForRole
			var volunteerForRole = {};
			for(role in uniqueRoles ) {
				var vol = md.getVolunteerForRole(role);
				if(vol!=null){
					Reflect.setField(volunteerForRole,Std.string(role.id),{id:vol.user.id,coupleName:vol.user.getCoupleName()});
				}else{
					Reflect.setField(volunteerForRole,Std.string(role.id),null);
				}
			}
			o.volunteerForRole = volunteerForRole;
			out.multiDistribs.push(o);
		}

		json(out);
	}

	/**
		bridge from TS for mangopay refunds
	**/
	function doMangopayRefund(amountToRefund:Float,basket:db.Basket,key:String){

		if(key != haxe.crypto.Md5.encode(App.config.get("key")+"bridge")){
			throw new tink.core.Error("invalid bridge key");
		}

		if (MangopayPlugin.hasOnlyMangopayPayments(basket)) {
					
			var mangopayUser = mangopay.db.MangopayUser.get(basket.getUser());
			if( mangopayUser == null ) throw "This user should have a Mangopay user ID";

			//We sort the payments operations by payment amounts so that we can refund first on the biggest amount
			var sortedPaymentsOperations = basket.getPaymentsOperations().array();
			sortedPaymentsOperations.sort(function(a, b): Int {
				if (a.amount < b.amount) return 1;
				else if (a.amount > b.amount) return -1;
				return 0;
			});

			//Let's do the refund on different payments if needed
			var refundRemainingAmount = Math.abs(amountToRefund);
			var totalRefunded = 0.0;
			var refundOps = [];
			for ( payment in sortedPaymentsOperations ) {
				var amountToRefund = 0.0;
				if ( refundRemainingAmount == 0.0 ) break;
				
				if ( refundRemainingAmount <= payment.amount ) {
					//Partial Refund
					amountToRefund = refundRemainingAmount;
				} else {
					//Full Refund						
					amountToRefund = payment.amount;						
				}
				refundRemainingAmount -= amountToRefund;	

				//Let's do the refund for this payment
				var conf = MangopayPlugin.getGroupConfig(basket.getGroup());
				var amount = MangopayPlugin.getAmountAndFees(amountToRefund,conf);
				var refund : mangopay.Types.Refund = {				
					DebitedFunds: {				
						Currency: Euro,
						Amount: Math.round(amount.netAmount * 100)		
					},
					Fees: {				
						Currency: Euro,
						Amount: 0 - Math.round(amount.fees * 100),//negative : refund fees
					},
					AuthorId: mangopayUser.mangopayUserId,
					InitialTransactionId: payment.getPaymentData().remoteOpId				
				};				
				var createdRefund = Mangopay.createPayInRefund(refund);
				App.current.logError(Json.stringify(createdRefund));
				totalRefunded += amountToRefund;

				//create one operation for each refund
				var op  = new db.Operation();
				op.type = db.Operation.OperationType.Payment;
				op.setPaymentData({
					type:MangopayECPayment.TYPE,
					remoteOpId: createdRefund.Id
				});
				op.name = 'Remboursement (${createdRefund.Id})';
				op.group = basket.getGroup();
				op.user = basket.user;
				op.relation = basket.getOrderOperation();
				op.amount = 0 - Math.abs(amountToRefund);						
				op.date = Date.now();
				op.insert();
				refundOps.push(op);
			}

			//prepare operations for JSON serialization
			var refundOps2:Array<{id:Int}> = refundOps.map(op -> {id:op.id});

			json({refunds:refundOps2});

		}else{
			throw new tink.core.Error("Basket #"+basket.id+" is not a mangopay paid basket.");
		}


	}
}
