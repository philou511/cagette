package service;
import service.PaymentService;
import tink.core.Error;
import db.Operation;

class MembershipService{

    var group : db.Group;

    public function new(group:db.Group){
        this.group = group;
	}
	
	public function getUserMemberships(user:db.User):Array<db.Membership>{
		return db.Membership.manager.search($user == user && $amap == group,{orderBy:-year}, false).array();
	}

	public function getUserMembership(user:db.User,year:Int):db.Membership{
		return db.Membership.manager.select($user == user && $amap == group && $year==year, false);
	}

	public function getPeriodName(year:Int):String{
		return group.getPeriodNameFromYear(year);
	}

	public function createMembership(user:db.User,year:Int,date:Date,?membershipFee:Int,?paymentType:String,?distribution:db.MultiDistrib):db.Membership{
		
		//check if exising
		if(getUserMembership(user,year)!=null){
			throw new Error("Membership already exists");
		}

		//get payment type object
		var paymentType = PaymentService.getPaymentTypes(PaymentContext.PCManualEntry, group).find(pt -> return paymentType==pt.type);

		
		var op : db.Operation = null;
		if(group.hasPayments()){

			if(paymentType==null){
				throw new Error("missing paymentType");
			}

			switch(paymentType.type){
				case payment.Check.TYPE , payment.Transfer.TYPE , payment.Cash.TYPE : //ok
				default : throw new Error("Membership payement can only be transfer, cash or check");
			}

			//debt operation
			op = new db.Operation();
			op.user = user;			
			op.group = group;
			op.name = "Adhésion "+getPeriodName(year);
			op.amount = 0 - membershipFee;
			op.date = date;
			op.type = Membership;
			var data : MembershipInfos = {year:year};
			op.data = data;			
			op.pending = false;				
			op.insert();	
			
			var paymentOp = db.Operation.makePaymentOperation(user,group, paymentType.type, membershipFee, "Paiement adhésion "+getPeriodName(year) , op );
			paymentOp.pending = false;
			paymentOp.update();

			service.PaymentService.updateUserBalance(user,group);
		}

		var cotis = new db.Membership();
		cotis.amap = group;
		cotis.user = user;
		cotis.year = year;
		cotis.date = date;
		cotis.distribution = distribution;
		cotis.operation = op;
		cotis.insert();

		return cotis;

	}


    public function countUpToDateMemberships(){
		var year = group.getMembershipYear();
		return db.Membership.manager.count( $amap == group && $year == year);
    }
    
    /**
        get members with up to date membership
    **/
    public function getMembershipUsers(?index:Int,?limit:Int):Array<db.User> {
		var userGroups = [];
		if (index == null && limit == null) {
			userGroups = db.UserGroup.manager.search($group == group, false).array();	
		}else {
			userGroups = db.UserGroup.manager.search($group == group,{limit:[index,limit]}, false).array();
		}
		
		for (userGroup in Lambda.array(userGroups)) {
			if (!userGroup.hasValidMembership()) userGroups.remove(userGroup);
		}
		
		return userGroups.map( x -> return x.user );	
	}

    /**
        get members with no membership ( or expired )
    **/
	public function getNoMembershipUsers(?index:Int,?limit:Int):Array<db.User> {
		var userGroups = [];
		if (index == null && limit == null) {
			userGroups = db.UserGroup.manager.search($group == group, false).array();	
		}else {
			userGroups = db.UserGroup.manager.search($group == group,{limit:[index,limit]}, false).array();
		}
		
		for (userGroup in Lambda.array(userGroups)) {
			if (userGroup.hasValidMembership()) userGroups.remove(userGroup);
		}
		
		return userGroups.map( x -> return x.user );		
	}
}