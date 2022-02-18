package controller.api;
import service.SubscriptionService;
import haxe.Json;
import neko.Web;

class Catalog extends Controller
{

    /**
        get a catalog
    **/
	public function doDefault(catalog:db.Catalog){

        var ss = new SubscriptionService();
        var out = {
            id : catalog.id,
            name : catalog.name,
            description : catalog.description,
            type : catalog.type,
            startDate   : catalog.startDate,
            endDate     : catalog.endDate,
            vendor:catalog.vendor.getInfos(),
            products:catalog.getProducts().array().map( p -> p.infos() ),
            contact: catalog.contact==null ? null : catalog.contact.infos(),
            documents : catalog.getVisibleDocuments(app.user).array().map(ef -> {name:ef.file.name,url:"/file/"+sugoi.db.File.makeSign(ef.file.id)}),
            distributions : catalog.getDistribs(false).array().map( d -> d.getInfos() ),
            constraints : SubscriptionService.getContractDescription(catalog),
            absences : SubscriptionService.getAbsencesDescription(catalog),
        }

        json(out);

    }

    /**
        absences infos when there is no subscription
    **/
    public function doCatalogAbsences(catalog:db.Catalog){
        json({
            startDate : catalog.absencesStartDate,
            endDate : catalog.absencesEndDate,
            absentDistribsMaxNb : catalog.absentDistribsMaxNb,
            possibleAbsentDistribs : SubscriptionService.getContractAbsencesDistribs(catalog).map(d -> d.getInfos())
        });
    }

    /**
        absences infos once a sub is created
    **/
    public function doSubscriptionAbsences(sub:db.Subscription){
       /* json({
            startDate : catalog.absencesStartDate,
            endDate : catalog.absencesEndDate,
            absentDistribsNb : sub.getAbsencesNb(),
            absentDistribIds : sub.getAbsentDistribIds(),
            possibleAbsentDistribs : SubscriptionService.getContractAbsencesDistribs(catalog).map(d -> d.getInfos())
        });*/

    }

}