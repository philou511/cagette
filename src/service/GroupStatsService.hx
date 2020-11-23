package service;

import haxe.macro.Expr.Error;
import db.UserOrder;
import db.Distribution;
import db.Membership;
import db.Basket;

class GroupStatsService{

    var from : Date;
    var to : Date;
    var group : db.Group;

    public function new(group:db.Group, from:Date,to:Date) {
        this.group = group;
        this.from = from;
        this.to = to;        
        //limit to one year
        if( (to.getTime() - from.getTime())/1000 > 60*60*24*365   ){
            throw new tink.core.Error("Vous devez choisir une période inférieure ou égale à un an");
        }
    }


    public function getBasketNumber() {
        var dids = db.MultiDistrib.getFromTimeRange( group , from , to  ).map(d -> d.id);
        return Basket.manager.count( $multiDistribId in dids );
    }
    
    public function getSalesAmount(){
        var amount = 0.0;
        var dids = db.MultiDistrib.getFromTimeRange( group , from , to  ).map(d -> d.id);
        var baskets = Basket.manager.search( $multiDistribId in dids );
        for ( b in baskets){
            if(b.total==null){
                b.lock();
                b.total = b.getOrdersTotal();
                b.update();
            }
            amount += b.total;

        }
        return amount;
    }

    /**
        get years concerned by this timeframe
    **/
    function getYears(){
        var years = [group.getMembershipYear(from)];
        if(group.getMembershipYear(to)!=years[0]){
            years.push( group.getMembershipYear(to) );
        }
        return years;
    }

    public function getMembershipNumber(){
        return Membership.manager.count($date >= from && $date < to  && $group == group);
    }

    /**
        liste les gens qui ont une cotisation valide pour cette période
    **/
    public function getActiveMembershipMembers():Array<Int>{
        var memberships = Membership.manager.search(($year in getYears()) && $group == group && $date < to, false).array();
        var userIds = [];
        for (m in memberships){
            if(!userIds.has(m.user.id)){
                userIds.push(m.user.id);
            }
        }
        return userIds;
    }

    /**
        compte combien d'adhérents ont commandé
    **/
    public function getActiveMembershipWithOrderNumber(){
        var mdIds = db.MultiDistrib.getFromTimeRange( group , from , to  ).array().map(md->md.id);
        var distribIds = Distribution.manager.search($multiDistribId in mdIds,false).array().map(d->d.id);
        if(distribIds.length==0) return 0;
        var userIds = getActiveMembershipMembers();
        if(userIds.length==0) return 0;
        return sys.db.Manager.cnx.request('select count(distinct userId) from UserOrder where distributionId in (${distribIds.join(",")}) and userId in (${userIds.join(",")})').getIntResult(0);
    }

    public function getMembersWithOrderNumber(){
        var mdIds = db.MultiDistrib.getFromTimeRange( group , from , to  ).array().map(md->md.id);
        var distribIds = Distribution.manager.search($multiDistribId in mdIds,false).array().map(d->d.id);
        if(distribIds.length==0) return 0;
        return sys.db.Manager.cnx.request('select count(distinct userId) from UserOrder where distributionId in (${distribIds.join(",")})').getIntResult(0);
    }

    

    public function getMembershipAmount(){
        var amount = 0.0;
        for ( m in Membership.manager.search($date >= from && $date < to  && $group == group, false) ){

            //fix on the fly
            if(m.amount==0 || m.amount==null){
                m.lock();
                if(m.operation!=null){
                    m.amount = Math.abs(m.operation.amount);
                    m.update();
                }
            }

            amount += m.amount;
        } 
        return amount;
    }

    /**
        get number of different products that have been sold during this period
    **/
    public function getProductNumber(){
        var mdIds = db.MultiDistrib.getFromTimeRange( group , from , to  ).array().map(md->md.id);
        var distribIds = Distribution.manager.search($multiDistribId in mdIds,false).array().map(d->d.id);
        if(distribIds.length==0) return 0;
        return sys.db.Manager.cnx.request('select count(distinct productId) from UserOrder where distributionId in (${distribIds.join(",")})').getIntResult(0);
    }

    public function getMembersNumber(){
        return group.getMembersNum();
    }

    
}