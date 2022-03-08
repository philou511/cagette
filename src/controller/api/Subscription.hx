package controller.api;
import service.OrderService;
import haxe.Json;
import neko.Web;
import service.SubscriptionService;
import tink.core.Error;

typedef NewSubscriptionDto = {
    userId:Int,
    catalogId:Int,
    distributions:Array<{id:Int,orders:Array<{id:Int,productId:Int,qty:Float}>}>,
    absentDistribIds:Array<Int>
};

typedef UpdateOrdersDto = {  
    distributions:Array<{id:Int,orders:Array<{id:Int,productId:Int,qty:Float}>}>,
};

class Subscription extends Controller
{

    /**
        Get or create a subscription
    **/
	public function doDefault(?sub:db.Subscription){

        // Create a new sub
        var post = sugoi.Web.getPostData();
        if(post!=null && sub==null){
            var newSubData : NewSubscriptionDto = Json.parse(StringTools.urlDecode(post));
            var user = db.User.manager.get(newSubData.userId,false);
            var catalog = db.Catalog.manager.get(newSubData.catalogId,false);

            if(!app.user.isAdmin() && !user.canManageContract(catalog) && app.user.id!=user.id){
                throw new Error(403,"You're not allowed to create a subscription for this user");
            }

            var ss = new SubscriptionService();
            var ordersData = newSubData.distributions[0].orders.map( o -> {productId:o.productId, quantity:o.qty,userId2:null,invertSharedOrder:null});
            sub = ss.createSubscription(user,catalog,ordersData,newSubData.absentDistribIds);
            
        }    

        getSubscription(sub);
    }

    /**
        update Orders of a subscription
    **/
	public function doUpdateOrders(sub:db.Subscription){

        // Create a new sub
        var post = sugoi.Web.getPostData();
        if(post!=null){
            var updateOrdersData : UpdateOrdersDto = Json.parse(StringTools.urlDecode(post));

            if(!app.user.isAdmin() && !app.user.canManageContract(sub.catalog) && app.user.id!=sub.user.id){
                throw new Error(403,"You're not allowed to edit a subscription for this user");
            }

            //format Data for SubscriptionService.areVarOrdersValid()
            var pricesQuantitiesByDistrib = new Map<db.Distribution,Array<{productQuantity:Float, productPrice:Float}>>();
            for( d in updateOrdersData.distributions){
                pricesQuantitiesByDistrib.set( db.Distribution.manager.get(d.id,false) , d.orders.map( o -> {
                    var p = db.Product.manager.get(o.productId,false);
                    return {
                        productQuantity:o.qty,
                        productPrice:p.price
                    };                    
                }) );
            }

            if( SubscriptionService.areVarOrdersValid( sub, pricesQuantitiesByDistrib ) ) {

                for( d in updateOrdersData.distributions){
                    for( order in d.orders){
                        var p = db.Product.manager.get(order.productId,false);
                        
                        if(order.id==null){
                            OrderService.make( sub.user, order.qty, p , d.id , null, sub );
                        }else{
                            var userOrder = db.UserOrder.manager.get(order.id,false);
                            if(p.multiWeight){
                                OrderService.editMultiWeight( userOrder, order.qty );
                            }else{
                                OrderService.edit( userOrder, order.qty );
                            }
                        }
                    }
                }            
            }

			if ( sub.catalog.hasPayments ) SubscriptionService.createOrUpdateTotalOperation( sub );
			
        }    

        getSubscription(sub);
    }




    private function getSubscription(sub:db.Subscription){

        var distributionsWithOrders = new Array<{id:Int,orders:Array<{id:Int,productId:Int,qty:Float}>}>();
        for( d in SubscriptionService.getSubscriptionDistributions(sub,"allIncludingAbsences")){
            distributionsWithOrders.push({
                id:d.id,
                orders:d.getUserOrders(sub.user).array().map(o -> {id:o.id,productId:o.product.id,qty:o.quantity})
            });
        }

        json({
            id : sub.id,
            startDate : sub.startDate,
            endDate : sub.endDate,
            user : sub.user.infos(),
            user2 : sub.user2==null ? null : sub.user2.infos(),
            catalogId : sub.catalog.id,
            constraints : SubscriptionService.getSubscriptionConstraints(sub),
            totalOrdered : sub.getTotalPrice(),
            balance : sub.getBalance(),
            distributions:distributionsWithOrders,
            absentDistribIds:sub.getAbsentDistribIds()
        });
    }

}