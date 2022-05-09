
package pro.db;
import Common;
import sys.db.Object;
import sys.db.Types;

enum NotifType {
	NTCatalogImportRequest;
	NTDeliveryRequest;
	NTOrdersClosed;
	NTDeliveryUpdate;
}

typedef CatalogImportContent = {
	//placeId : Int,
 	catalogId:Int, //pcatalog id
	userId:Int, //client remote id
	message : String,
	catalogType : Int,
}

typedef DeliveryRequestContent = {
	pcatalogId:Int, //concerned cpro catalog
	distribId:Int, //multidistrib id
}

typedef DeliveryUpdate = {
	did:Int,//distrib id
	oldDistribution:DeliveryRequestContent,
	newDistribution:DeliveryRequestContent,
}

/**
 * Notifications
 */
class PNotif extends Object
{
	public var id : SId;	
	@:relation(companyId) 	public var company 	: pro.db.CagettePro;	
	@:relation(groupId) 	public var group 	: SNull<db.Group>;
	@:relation(userId) 		public var sender 	: SNull<db.User>; //sender of the notif
	public var type 	: SEnum<NotifType>;
	public var title	: STinyText;
	public var content 	: SSmallText;	
	public var date 	: SDateTime;	
	
	public function new(){
		super();
		date = Date.now();
	}

	public static function distributionInvitation(catalog:pro.db.PCatalog, distrib:db.MultiDistrib,sender:db.User){

		var notif = new pro.db.PNotif();
		notif.company = catalog.company;
		notif.title = "Demande de livraison pour le " + App.current.view.hDate(distrib.getDate());
		notif.type = NotifType.NTDeliveryRequest;
		notif.group = distrib.getGroup();
		var content : DeliveryRequestContent = {
			pcatalogId : catalog.id,
			distribId : distrib.id
		};
		notif.content  = haxe.Json.stringify(content);
		notif.sender = sender;
		notif.insert();
		
		var html = notif.group.name + " demande une livraison le " + App.current.view.hDate(distrib.getDate());
		html += "<br/>Adresse : " + distrib.getPlace().getFullAddress();
		html += "<br/>Connectez-vous à votre compte producteur pour valider ou refuser cette demande.";
		App.quickMail(notif.company.vendor.email, notif.title, html);	
	}

	public static function getDistributionInvitation(catalog:pro.db.PCatalog, distrib:db.MultiDistrib){
		var out = [];
		if(catalog==null || distrib==null) return out;
		for( n in manager.search($group==distrib.getGroup() && $type==NotifType.NTDeliveryRequest)){
			var content : DeliveryRequestContent = haxe.Json.parse(n.content);
			if(content.pcatalogId==catalog.id && content.distribId==distrib.id){
				out.push(n);
			}
		}
		return out;
	}

	public function getContent():Dynamic{
		return haxe.Json.parse(this.content);
	}

	/**
		get company notifications
	**/
	public static function getNotifications(company:CagettePro){

		var notifs = pro.db.PNotif.manager.search($company == company, {orderBy: -date}, true).array();

		for( n in notifs.copy()){
			//check validity
			switch(n.type){
				case NotifType.NTCatalogImportRequest:
					var content : CatalogImportContent = n.getContent();
					var catalog = pro.db.PCatalog.manager.get(content.catalogId);
					if(catalog==null){
						//pcatalog does not exists anymore
						notifs.remove(n);
						n.delete();
					}

				case NotifType.NTDeliveryUpdate :

				case NotifType.NTOrdersClosed :

				case NotifType.NTDeliveryRequest :
					var content : DeliveryRequestContent = n.getContent();
					var distrib = db.MultiDistrib.manager.get(content.distribId);
					if( distrib.distribEndDate.getTime() < Date.now().getTime() ){
						//if distrib is in the past
						notifs.remove(n);
						n.delete();
					}
			}
		}
		
		return notifs;

	} 
}