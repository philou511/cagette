package pro.controller.api;

import Common;
using tools.ObjectListTool;

class Vendor extends sugoi.BaseController
{

	public function new() 
	{
		super();
	}
	
    /**
		Cagette Pro infos via API
	**/
	public function doDefault(vendor:db.Vendor){
        Sys.print(haxe.Json.stringify(vendor.getInfos(true)));
	}

    /**
        Next distribs
    **/
    /*public function doNextDistributions(vendor:db.Vendor){
        var c = pro.db.CagettePro.getFromVendor(vendor);
        if(c==null){
            Sys.print(haxe.Json.stringify([]));
            return;
        }  
        var out : Array<DistributionInfos> = [];
        for( group in c.getGroups()){
            var contracts = db.Catalog.manager.search($vendor==c.vendor && $amap==group,false);
            for(contract in contracts){
                var distribs = contract.getDistribs();
                if(distribs.length>0) out.push(distribs.first().getInfos());
            }
        }
       Sys.print(haxe.Json.stringify(out));
    }*/
	
	public function doNextDistributions(vendor:db.Vendor){
         
        var out = new Map<Int,db.Distribution>();// groupId -> next distribution
        var cids :Array<Int> = db.Catalog.manager.search($vendor==vendor,false).getIds();
        var distribs = db.Distribution.manager.search(($catalogId in cids) && $date > Date.now(),false);
        for( d in distribs ){
            
            if(!d.catalog.group.flags.has(CagetteNetwork)) continue;

            var d2 = out[d.catalog.group.id];
            if(d2==null){
                out[d.catalog.group.id] = d;
            }else if(d2.date.getTime() > d.date.getTime()){
                out[d.catalog.group.id] = d;
            }
        }

        var out = Lambda.array(out).map(function(x) return x.getInfos());
        Sys.print(haxe.Json.stringify(out));
    }

	
}