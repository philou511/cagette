package db;
import sys.db.Object;
import sys.db.Types;
class Place extends Object
{

	public var id : SId;
	public var name : SString<64>;
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	//latitude/longitude
	public var lat:SNull<SFloat>;
	public var lng:SNull<SFloat>;
	@hideInForms @:relation(amapId) public var amap : Amap;
	
	
	public function new() 
	{
		super();
	}
	
	override function toString() {
		if (name == null) {
			return "place";
		}else {			
			return name;
		}
	}
	
	public function getFullAddress(){
		var str = new StringBuf();
		str.add(name+", \n");
		if (address1 != null) str.add(address1 + ", \n");
		if (address2 != null) str.add(address2 + ", \n");
		if (zipCode != null) str.add(zipCode);
		if (city != null) str.add(" - "+city);
		return str.toString();
	}
	
	/**
	 * get adress without 'name' field.
	 */
	public function getAddress(){
		var str = new StringBuf();
		if (address1 != null) str.add(address1 + ", \n");
		if (address2 != null) str.add(address2 + ", \n");
		if (zipCode != null) str.add(zipCode);
		if (city != null) str.add(" - "+city);
		return str.toString();
	}
	
	public static function getLabels():Map<String,String>{
		var t = sugoi.i18n.Locale.texts;
		return [
			"name"		=>	t._("Name"),
			"address1"	=>	t._("Address 1"),
			"address2"	=>	t._("Address 2"),
			"zipCode"	=>	t._("Zip code"),
			"city"		=>	t._("City"),			
			"lat"		=>	t._("Latitude"),			
			"lng"		=>	t._("Longitude"),			
		];
	}
	
}