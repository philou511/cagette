package hosted.db ;
import sys.db.Types;
using tools.ObjectListTool;
/**
 * Stores stats on groups
 */
@:index(active,visible)
class Hosting extends sys.db.Object
{
	public var id : SId; //meme id que l'Amap	
	public var cdate : SNull<SDateTime>; // le jour ou il est passé en abo payant	
	public var active : SBool; // distrib en cours
	public var visible : SBool; // visible sur les cartes et annuaires
	public var membersNum: SInt; //nbre de membres
	public var contractNum : SInt; //nbre de contrats non-pro actifs
	public var cproContractNum : SInt; //nbre de contrats pro actifs
	
	public function new() 
	{
		super();
		active = false;
		visible = false;
		membersNum = 0;
		contractNum = 0;
		cproContractNum  = 0;
	}

	public static function getOrCreate(amapId:Int,?lock=false) {
		var  o =  manager.get(amapId, lock);
		if (o == null) {
			o = new hosted.db.Hosting();
			o.id = amapId;
			o.membersNum = o.getMembersNum();
			o.cdate = Date.now();
			o.insert();
		}
		return o;
	}
	
	public function getAmap() {
		return db.Group.manager.get(id);
	}
	
	public function getMembersNum():Int {
		return db.UserGroup.manager.count($groupId == this.id);
	}
	
	/*public function isAboOk(?plusOne=false):Bool {
	
		var members = getMembersNum();
		if (plusOne) members++;
		
		//abo null ou expiré ?
		if (aboEnd == null || Date.now().getTime() > (aboEnd.getTime() + (1000*60*60*24))) {
			
			//mode free ?
			if (members <= hosted.HostedPlugIn.ABO_MAX_MEMBERS[0]) return true;
			
			return false;
		}else {
			//abo valable
			return (members <= hosted.HostedPlugIn.ABO_MAX_MEMBERS[aboType]); 
			
		}
		
		return false;
	}*/
	
	/*public function getMaxMembers(){
		return hosted.HostedPlugIn.ABO_MAX_MEMBERS[aboType];
	}*/
	
	/**
	 * Detect if this group can be visible on the map + directories.
	 */
	public function updateVisible(){
		
		var g = getAmap();
		if(g==null) return null;

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
		// this.cproContractNum = cproContracts.length;
		// this.contractNum = contracts.length;
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