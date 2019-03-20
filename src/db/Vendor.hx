package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Vendor (farmer/producer/vendor)
 */
class Vendor extends Object
{
	public var id : SId;
	public var name : SString<128>;
	
	public var legalStatus : SNull<SEnum<LegalStatus>>;
	@hideInForms public var profession : SNull<SInt>;

	public var email : STinyText;
	public var phone:SNull<SString<19>>;
		
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	public var country:SNull<SString<64>>;
	
	public var desc : SNull<SText>;
	
	public var linkText:SNull<SString<256>>;
	public var linkUrl:SNull<SString<256>>;
	
	@hideInForms @:relation(imageId) 	public var image : SNull<sugoi.db.File>;
	@hideInForms @:relation(userId) 	public var user : SNull<db.User>; //owner of this vendor
	
	@hideInForms @:relation(amapId) public var amap : SNull<Amap>;//DEPRECATED
	@hideInForms public var status : SNull<SString<32>>; //temporaire , pour le dédoublonnage
	
	
	public function new() 
	{
		super();
		legalStatus = Business;
		try{
			var t = sugoi.i18n.Locale.texts;
			name = t._("Supplier");
		}catch(e:Dynamic){}
	}
	
	override function toString() {
		return name;
	}

	public function getContracts(){
		return db.Contract.manager.search($vendor == this,{orderBy:-startDate}, false);
	}

	public function getActiveContracts(){
		var now = Date.now();
		return db.Contract.manager.search($vendor == this && $startDate < now && $endDate > now ,{orderBy:-startDate}, false);
	}

	public function getImages(){

		var out = {
			logo:null,
			portrait:null,
			banner:null,
			farm:[],				
		};

		var files = sugoi.db.EntityFile.getByEntity("vendor",this.id);
		for( f in files ){
			switch(f.documentType){				
				case "logo" 	: out.logo 		= f.file;
				case "portrait" : out.portrait 	= f.file;
				case "banner" 	: out.banner 	= f.file;
				case "farm" 	: out.farm.push(f.file);
			}
		}

		if(out.logo==null) out.logo = this.image;

		//sort and splice farm images
		out.farm.sort(function(a,b){
			return Math.round((b.cdate.getTime() - a.cdate.getTime())/1000);
		});
		out.farm = out.farm.splice(0,4);

		return out;
	}

	public function getInfos(?withImages=false):VendorInfos{

		var file = function(f){
			return if(f==null)  null else App.current.view.file(f);
		}
		var vendor = this;
		var out : VendorInfos = {
			id : id,
			name : vendor.name,
			image : file(vendor.image),
			images : cast {},
			zipCode : vendor.zipCode,
			city : vendor.city,
			linkText:vendor.linkText,
			linkUrl:vendor.linkUrl,
			desc:vendor.desc
		};

		if(withImages){
			var images = getImages();
			out.images.logo = file(images.logo);
			out.images.portrait = file(images.portrait);
			out.images.banner = file(images.portrait);
			out.images.farm1 = file(images.farm[0]);
			out.images.farm2 = file(images.farm[1]);
			out.images.farm3 = file(images.farm[2]);
			out.images.farm4 = file(images.farm[3]);
		}
		return out;
	}

	/*public function infos():VendorInfos{
		return {
			id 		: id,
			name 	: name,
			desc 	: desc,
			image 	: App.current.view.file(image),
			//images 	: null
			zipCode : zipCode,
			city 	: city,
			linkText	:linkText,
			linkUrl		:linkUrl,			
		};
	}*/
	

	public function getGroups():Array<db.Amap>{
		var contracts = getActiveContracts();
		var groups = Lambda.map(contracts,function(c) return c.amap);
		return tools.ObjectListTool.deduplicate(groups);
	}

	public static function get(email:String,status:String){
		return manager.select($email==email && $status==status,false);
	}

	public static function getForm(vendor:db.Vendor){
		var t = sugoi.i18n.Locale.texts;
		var form = sugoi.form.Form.fromSpod(vendor);
		
		//country
		form.removeElementByName("country");
		form.addElement(new sugoi.form.elements.StringSelect('country',t._("Country"),db.Place.getCountries(),vendor.country,true));
		
		//profession
		form.addElement(new sugoi.form.elements.IntSelect('profession',t._("Profession"),sugoi.form.ListData.fromSpod(getVendorProfessions()),vendor.profession,false),3);
		
		return form;
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

	/**
		Loads vendors professions from json
	**/
	public static function getVendorProfessions():Array<{id:Int,name:String}>{
		var filePath = sugoi.Web.getCwd()+"../data/vendorProfessions.json";
		var json = haxe.Json.parse(sys.io.File.getContent(filePath));
		return json.professions;
	}

	public function getLink():sugoi.db.Permalink{		
		return sugoi.db.Permalink.getByEntity(this.id,"vendor");
	}
	
}