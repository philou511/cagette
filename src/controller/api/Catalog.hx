package controller.api;
import tink.core.Error;
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
            absentDistribsMaxNb : catalog.absentDistribsMaxNb,
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

        if( sub.catalog.group.hasShopMode() ){
            throw new Error(403,"group is in shop mode");
        }

		if ( !app.user.canManageContract(sub.catalog) && !(app.user.id==sub.user.id) ){
			throw new Error(403,t._('Access forbidden') );
		} 
		
		if( !SubscriptionService.canAbsencesBeEdited( sub.catalog ) ) {
			throw new Error(403,t._('no absences mgmt in this catalog') );
		}
		
		var absenceDistribs = sub.getAbsentDistribs();
		var possibleAbsences = sub.getPossibleAbsentDistribs();
		var now = Date.now().getTime();
		possibleAbsences = possibleAbsences.filter(d -> d.orderEndDate.getTime() > now);
		var lockedDistribs = absenceDistribs.filter( d -> d.orderEndDate.getTime() < now);	//absences that are not editable anymore
		
        var post = StringTools.urlDecode( sugoi.Web.getPostData() );
        if(post!=null){
            var newAbsentDistribIds:Array<Int> = Json.parse(post).absentDistribIds;
            if (newAbsentDistribIds==null || newAbsentDistribIds.length==0) {
                throw new Error(500,"bad parameter");
            }

            var subService = new SubscriptionService();
            subService.updateAbsencesDates( sub, newAbsentDistribIds );
        }

        /**
            once the sub is created, absent distribs number cannot be changed.
            But asbence distribs can be chosen, until they are 
        **/
        var catalog = sub.catalog;
        json({
            startDate : catalog.absencesStartDate,
            endDate : catalog.absencesEndDate,
            absentDistribsNb : sub.getAbsencesNb(),
            absentDistribIds : sub.getAbsentDistribIds(),
            closedDistribIds : lockedDistribs.map(d -> d.id),
            possibleAbsentDistribs : possibleAbsences.map(d -> d.getInfos())
        });
    }

}