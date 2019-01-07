package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Vendor (producteur)
 */
class Vendor extends Object
{
	public var id : SId;
	public var name : SString<128>;
	
	public var email : STinyText;
	public var phone:SNull<SString<19>>;
		
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	
	public var desc : SNull<SText>;
	
	public var linkText:SNull<SString<256>>;
	public var linkUrl:SNull<SString<256>>;
	
	@hideInForms @:relation(imageId) public var image : SNull<sugoi.db.File>;
	
	@:relation(amapId) public var amap : SNull<Amap>;
	
	public function new() 
	{
		super();
		var t = sugoi.i18n.Locale.texts;
		name = t._("Supplier");
	}
	
	override function toString() {
		return name;
	}

	public function getActiveContracts(){
		var now = Date.now();
		return db.Contract.manager.search($vendor == this && $startDate < now && $endDate > now ,{orderBy:-startDate}, false);
	}

	public function infos():VendorInfo{
		return {
			id : id,
			name : name,
			faceImageUrl : (image!=null ? App.current.view.file(image) : null ),
			logoImageUrl : (image!=null ? App.current.view.file(image) : null ),
			zipCode : zipCode,
			city : city
		};
	}
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 				=> t._("Supplier name"),
			"desc" 				=> t._("Description"),
			"email" 			=> t._("Email"),
			"phone" 			=> t._("Phone"),
			"address1" 			=> t._("Address 1"),
			"address2" 			=> t._("Address 2"),
			"zipCode" 			=> t._("Zip code"),
			"city" 				=> t._("City"),			
			"linkText" 			=> t._("Link text"),			
			"linkUrl" 			=> t._("Link URL"),			
		];
	}
	
}