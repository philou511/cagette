package hosted.db ;
import sys.db.Types;
using tools.ObjectListTool;

/**
 * GroupStats
 */
@:index(active,visible)
class GroupStats extends sys.db.Object
{
	public var id : SId;
	@:relation(groupId) public var group : db.Group;	
	public var active : SBool; // distrib en cours
	public var visible : SBool; // visible sur les cartes et annuaires
	public var mode : SString<16>; // AMAP / MARKET
	public var membersNum: SInt; //nbre de membres
	public var contractNum : SInt; //nbre de catalogue actifs
	public var vendorNum : SInt; //nbre de prods actifs
	public var hasPayment : SBool;
	public var turnover90days : SInt;
	public var basketNumber90days : SInt;
	public var iro:SInt; // indice de richesse de l'offre
	public var contactType:SString<32>; //
	
	public function new() 
	{
		super();
		active = false;
		visible = false;
		membersNum = 0;
		contractNum = 0;
	}

	public static function getOrCreate(groupId:Int,?lock=false) {
		var  gs =  manager.select($groupId==groupId, lock);
		if (gs == null) {
			gs = new GroupStats();
			gs.groupId = groupId;
			gs.insert();
			gs.updateStats();
		}
		return gs;
	}
	
	
	public function getMembersNum():Int {
		return db.UserGroup.manager.count($groupId == this.group.id);
	}
	
	/**
	 * Detect if this group can be visible on the map + directories.
	 */
	public function updateStats(){
		
		var g = this.group;		
		var now = Date.now();

		//compute main place
		var mainPlace = g.getMainPlace();
		
		//has "cagette network" flag on
		var cn = g.flags.has(db.Group.GroupFlags.CagetteNetwork);
		
		var from = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 14);
		var to =   DateTools.delta(Date.now(),  1000.0 * 60 * 60 * 24 * 30 * 6);

		//has active distribs in the next 6 months
		var del = db.MultiDistrib.manager.count($distribStartDate > from && $distribStartDate < to && $group == g ) > 0;
		if (this.membersNum < 3) del = false;
		
		this.lock();
		this.visible = (del && cn );
		this.active = del;
		this.membersNum = g.getMembersNum();
		var activeCatalogs = g.getActiveContracts();
		this.contractNum = activeCatalogs.length;
		this.vendorNum = activeCatalogs.map(c -> c.vendor).deduplicate().length;
		this.hasPayment = !g.hasShopMode() || g.hasPayments(); 
		this.mode = g.hasShopMode() ? "MARKET" : "AMAP";

		var mds = db.MultiDistrib.getFromTimeRange(g,DateTools.delta(now, -1000.0 * 60 * 60 * 24 * 90),now);
		this.turnover90days = 0;
		for(md in mds){
			this.turnover90days+=Math.round(md.getTotalIncome());
		}

		var mdids:Array<Int> = mds.map(m->m.id);
		basketNumber90days = db.Basket.manager.count($multiDistribId in mdids);

		//contact type
		if(g.contact!=null){
			var cpros = service.VendorService.getCagetteProFromUser(g.contact);
			if(cpros.length>0){
				var vendor = cpros.find(cpro -> cpro.offer!=Training);				
				this.contactType = vendor==null ? "USER" : Std.string(vendor.offer);
			} else {
				this.contactType = "USER";
			}
		}else{
			this.contactType = "NONE";
		}

		this.update();
		
		return {
			cagetteNetwork:cn,
			geoloc: mainPlace!=null && mainPlace.lat!=null ,
			distributions:del,
			members:this.membersNum >= 3,
			visible:this.visible,
			active:this.active,
		};
		
	}
	
	
}