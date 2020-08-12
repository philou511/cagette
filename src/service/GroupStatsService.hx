package service;

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

    public function getMembershipNumber(){
        return Membership.manager.count($date >= from && $date < to && $group ==group);
    }

    public function getMembershipAmount(){
        var amount = 0.0;
        var memberships = Membership.manager.search($date >= from && $date < to && $group ==group);
        for ( m in memberships) amount += m.amount;
        return amount;
    }
}