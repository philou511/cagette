package db;
import sys.db.Object;
import sys.db.Types;
import db.UserAmap;
enum UserFlags {
	HasEmailNotif4h;	//send notifications by mail 4h before
	HasEmailNotif24h;	//send notifications by mail 24h before
	HasEmailNotifOuverture; //send notifications by mail on command open
	//Tuto;			//enable tutorials
}

enum RightSite {
	Admin;
}

@:index(email,unique)
class User extends Object {

	public var id : SId;
	public var lang : SString<2>;
	@:skip public var name(get, set) : String;
	public var pass : STinyText;
	public var rights : SFlags<RightSite>; //droits niveau site : moderateur, admin...
	
	public var firstName:SString<32>;
	public var lastName:SString<32>;
	public var email : SString<64>;
	public var phone:SNull<SString<19>>;
	
	public var firstName2:SNull<SString<32>>;
	public var lastName2:SNull<SString<32>>;
	public var email2 : SNull<SString<64>>;
	public var phone2:SNull<SString<19>>;
	
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SNull<SString<32>>;
	public var city:SNull<SString<25>>;
	
	@:skip public var amap(get_amap, null) : Amap;
	
	public var cdate : SDate; 				//creation
	public var ldate : SNull<SDateTime>;	//derniere connexion
	
	public var flags : SFlags<UserFlags>;
	
	@hideInForms public var tutoState : SNull<SData<{name:String,step:Int}>>; //tutorial state
	
	public var apiKey : SNull<SString<128>>; //private API key
	
	public function new() {
		super();
		
		//default values
		cdate = Date.now();
		rights = sys.db.Types.SFlags.ofInt(0);
		flags = sys.db.Types.SFlags.ofInt(0);
		flags.set(HasEmailNotif24h);
		lang = "fr";
		pass = "";
		
	}
	
	public override function toString() {
		return getName()+" ["+id+"]";
	}

	public function isAdmin() {
		return rights.has(Admin) || id==1;
	}
	
	public static function login(user:db.User, email:String) {
		
		user.lock();
		user.ldate = Date.now();
		user.update();
		App.current.session.setUser(user);
		if (App.current.session.data == null) App.current.session.data = {};
		//Who's connected, user1 or user2 ?
		App.current.session.data.whichUser = (email == user.email) ? 0 : 1; 	
		
	}
	
	/**
	 * is this user the manager of the current group
	 */
	public function isAmapManager() {
		var a = getAmap();
		if (a == null) return false;
		var ua = getUserAmap(a);
		if (ua == null) return false;
		return ua.hasRight(Right.AmapAdmin);
	}
	
	function getUserAmap(amap:db.Amap):db.UserAmap {
		return db.UserAmap.get(this, amap);
	}
	
	public function isFullyRegistred(){
		
		return pass != null && pass != "";
	}
	
	public function makeMemberOf(group:db.Amap){
		var ua = db.UserAmap.get(this, group);
		if (ua == null) {
			ua = new db.UserAmap();
			ua.user = this;
			ua.amap = group;
			ua.insert();
		}
		return ua;
	}
	
	/**
	 * Est ce que ce membre a la gestion de ce contrat
	 * si null, est ce qu'il a la gestion d'un des contrat, n'importe lequel (utilse pour afficher 'gestion contrat' dans la nav )
	 * @param	contract
	 */
	public function isContractManager(?contract:db.Contract ) {
		if (isAdmin()) return true;
		if (contract != null) {			
			return canManageContract(contract);
		}else {
			var ua = getUserAmap(getAmap());
			if (ua == null) return false;
			if (ua.rights == null) return false;
			for (r in ua.rights) {
				switch(r) {
					case Right.ContractAdmin(cid):
						return true;
					default:
				}
			}
			return false;			
		}
		
	}
	
	public function canManageAllContracts(){
		if (isAdmin()) return true;
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		if (ua.rights == null) return false;
		for (r in ua.rights) {
			switch(r) {
				case Right.ContractAdmin(cid):
					if(cid==null) return true;
				default:
			}
		}
		return false;			
	}
	
	public function canAccessMessages():Bool {
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		if (ua.hasRight(Right.Messages)) return true;
		return false;
	}
	
	public function canAccessMembership():Bool {
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		if (ua.hasRight(Right.Membership)) return true;
		return false;
	}
	
	public function canManageContract(c:db.Contract):Bool {
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		if (ua.hasRight(Right.ContractAdmin())) return true;
		if (ua.hasRight(Right.ContractAdmin(c.id))) return true;		
		return false;
	}
	
	public function getContractManager(?lock=false) {
		return Contract.manager.search($amap == amap && $contact == this, false);
	}
	
	public function getName() {
		return get_name();
	}
	
	public function get_name() {
		return lastName + " " + firstName;
	}
	
	public function getCoupleName() {
		var n = lastName + " " + firstName;
		if (lastName2 != null) {
			n = n + " / " + lastName2 + " " + firstName2;
		}
		return n;
	}
	
	public function set_name(name:String) {
		var name = name.split(' ');
		firstName = name[0];
		lastName = name[1];
		return firstName+" "+lastName;
	}
	
	public function setPass(p:String) {
		if (p == null) return null;
		this.pass = haxe.crypto.Md5.encode( App.config.get('key') + StringTools.trim(p));
		return this.pass;
	}
	
	/**
	 * Renvoie les commandes actuelles du user
	 * @param	_amap		force une amap
	 * @param	lock=false
	 */
	public function getOrders(?_amap:db.Amap,?lock = false):List<UserContract> {
		var a = _amap == null ? getAmap() : _amap;
		var c = a.getActiveContracts(true);
		var cids = Lambda.map(c,function(m) return m.id);
		var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		var out =  UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, lock);		
		return out;
		
	}
	
	/**
	 * renvoie les commandes à partir d'une liste de contrats
	 */
	public function getOrdersFromContracts(c:Iterable<db.Contract>):List<db.UserContract> {
		var cids = Lambda.map(c,function(m) return m.id);
		var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		return UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, false);		
	}
	
	/**
	 * renvoie les commandes de contrat variables à partir d'une distribution
	 */
	public function getOrdersFromDistrib(d:db.Distribution):List<db.UserContract> {
		var pids = Lambda.map(db.Product.manager.search($contractId == d.contract.id, false), function(x) return x.id);		
		return UserContract.manager.search(($userId == id || $userId2 == id) && $distributionId==d.id && $productId in pids , false);	
	}
	
	public function get_amap():Amap {
		return getAmap();
	}
	
	/**
	 * renvoie l'amap selectionnée par le user en cours
	 */
	public function getAmap() {
		
		if (App.current.user != null && id != App.current.user.id) throw "This function is valid only for the current user";
		if (App.current.session == null) return null;
		if (App.current.session.data == null ) return null;
		var a = App.current.session.data.amapId;
		if (a == null) {
			return null;
		}else {			
			return Amap.manager.get(a,false);
		}
	}
	
	/**
	 * get groups this user belongs to
	 */
	public function getAmaps():List<db.Amap> {
		return Lambda.map(UserAmap.manager.search($user == this, false), function(o) return o.amap);
	}
	
	public function isMemberOf(amap:Amap) {
		return UserAmap.manager.select($user == this && $amapId == amap.id, false) != null;
	}
	
	
	/**
	 * Renvoie la liste des contrats dans lequel l'adherent a des commandes
	 * @param	lock=false
	 * @return
	 */
	public function getContracts(?lock=false):Array<Contract> {
		var out = [];
		var ucs = getOrders(lock);
		for (uc in ucs) {
			if (!Lambda.has(out, uc.product.contract)) {
				out.push(uc.product.contract);
			}	
		}
		return out;
		
	}
	
	/**
	 * Merge fields of 2 users, then delete the second (u2)
	 * Be carefull : check before calling this function that u2 can be safely deleted !
	 */
	public function merge(u2:db.User) {
		
		this.lock();
		u2.lock();
		
		var m = function(a, b) {
			return a == null || a=="" ? b : a;
		}
		
		this.address1 = m(this.address1, u2.address1);
		this.address2 = m(this.address2, u2.address2);
		this.zipCode = m(this.zipCode, u2.zipCode);
		this.city = m(this.city, u2.city);
		
		//find how to merge the 2 names in each account
		if (this.email == u2.email) {
			
			this.firstName = m(this.firstName, u2.firstName);
			this.lastName = m(this.lastName, u2.lastName);
			this.phone = m(this.phone, u2.phone);
			
		} else if (this.email == u2.email2) {
			
			this.firstName = m(this.firstName, u2.firstName2);
			this.lastName = m(this.lastName, u2.lastName2);
			this.phone = m(this.phone, u2.phone2);
		} 
		
		if (this.email2 == u2.email) {
			
			this.firstName2 = m(this.firstName2, u2.firstName);
			this.lastName2 = m(this.lastName2, u2.lastName);
			this.phone2 = m(this.phone2, u2.phone);
			
		} else if (this.email2 == u2.email2) {
			
			this.firstName2 = m(this.firstName2, u2.firstName2);
			this.lastName2 = m(this.lastName2, u2.lastName2);
			this.phone2 = m(this.phone2, u2.phone2);
			
		}
		
		u2.delete();
		this.update();
		
	}
	
	public static function getOrCreate(firstName:String, lastName:String, email:String):db.User{
		var u = db.User.manager.select($email == email || $email2 == email, true);
		if (u == null){
			u = new db.User();
			u.firstName = firstName;
			u.lastName = lastName;
			u.email = email;
			u.insert();
		}
		return u;
	}
	
	/**
	 * Search for similar users in the DB ( same firstName+lastName or same email )
	 */
	public static function __getSimilar(firstName:String, lastName:String, email:String,?firstName2:String, ?lastName2:String, ?email2:String):List<db.User> {
		var out = new Array();
		out = Lambda.array(User.manager.search($firstName.like(firstName) && $lastName.like(lastName), false));
		out = out.concat(Lambda.array(User.manager.search($email.like(email), false)));
		out = out.concat(Lambda.array(User.manager.search($firstName2.like(firstName) && $lastName2.like(lastName), false)));
		out = out.concat(Lambda.array(User.manager.search($email2.like(email), false)));
		
		//recherche pour le deuxieme user
		if (lastName2 != "" && lastName2 != null && firstName2 != "" && firstName2 != null) {
			out = out.concat(Lambda.array(User.manager.search($firstName.like(firstName2) && $lastName.like(lastName2), false)));			
			out = out.concat(Lambda.array(User.manager.search($firstName2.like(firstName2) && $lastName2.like(lastName2), false)));			
		}
		if (email2 != null && email2 != "") {
			out = out.concat(Lambda.array(User.manager.search($email.like(email2), false)));
			out = out.concat(Lambda.array(User.manager.search($email2.like(email2), false)));	
		}		
		
		//dedouble
		var x = new Map<Int,db.User>();
		for ( oo in out) {
			x.set(oo.id, oo);
		}
		return Lambda.list(x);
	}
	
	/**
	 * Search for similar users in the DB ( same email )
	 */
	public static function getSameEmail(email:String, ?email2:String){
		
		var out = new Array();
		out = out.concat(Lambda.array(User.manager.search($email.like(email), false)));
		out = out.concat(Lambda.array(User.manager.search($email2.like(email), false)));
		if (email2 != null && email2 != "") {
			out = out.concat(Lambda.array(User.manager.search($email.like(email2), false)));
			out = out.concat(Lambda.array(User.manager.search($email2.like(email2), false)));	
		}
		return Lambda.list(out);
	}
	
	/**
	 *  Get users with no contracts
	 **/ 
	public static function getUsers_NoContracts(?index:Int,?limit:Int):List<db.User> {
		var productsIds = App.current.user.getAmap().getProducts().map(function(x) return x.id);
		var uc = UserContract.manager.search($productId in productsIds, false);
		var uc2 = uc.map(function(x) return x.user.id); //liste des userId avec un contrat dans cette amap

		// J. Le Clerc - BUGFIX#1 Ne pas oublier les contrats alternés
		for (u in uc) {
			if (u.user2 != null) {
				uc2.add(u.user2.id);
			}
		}
		
		if (uc2.length > 0){
			//les gens qui sont dans cette amap et qui n'ont pas de contrat de cette amap
			var ua = db.UserAmap.manager.unsafeObjects("select * from UserAmap where amapId=" + App.current.user.getAmap().id +" and userId NOT IN(" + uc2.join(",") + ")", false);						
			return Lambda.map(ua, function(x) return x.user);	
		}else{
			return App.current.user.amap.getMembers();
		}
		
	}
	
	/**
	 * User with contracts
	 */
	public static function getUsers_Contracts(?index:Int,?limit:Int):List<db.User> {
		var productsIds = App.current.user.getAmap().getProducts().map(function(x) return x.id);
		if (productsIds.length == 0) return new List();
		return db.User.manager.unsafeObjects("select u.* from User u, UserContract uc where uc.productId IN(" + productsIds.join(",") + ") AND (uc.userId=u.id OR uc.userId2=u.id) group by u.id  ORDER BY u.lastName", false);	
	}
	
	
	public static function getUsers_NoMembership(?index:Int,?limit:Int):List<db.User> {
		var ua = new List();
		if (index == null && limit == null) {
			ua = db.UserAmap.manager.search($amap == App.current.user.amap, false);	
		}else {
			ua = db.UserAmap.manager.search($amap == App.current.user.amap,{limit:[index,limit]}, false);
		}
		
		for (u in Lambda.array(ua)) {
			if (u.hasValidMembership()) ua.remove(u);
		}
		
		return Lambda.map(ua, function(x) return x.user);	
	}
	
	public static function getUsers_NewUsers(?index:Int, ?limit:Int):List<db.User> {
		
		var uas = db.UserAmap.manager.search($amap == App.current.user.amap, false);
		var ids = Lambda.map(uas, function(x) return x.user.id);
		if (index == null && limit == null) {
			return  db.User.manager.search($pass == "" && ($id in ids), {orderBy:lastName} ,false);
		}else {
			return  db.User.manager.search($pass == "" && ($id in ids), {limit:[index, limit] ,orderBy:lastName} , false);			
		}
		
	}
	
	public function sendInvitation() {
		
		var t = sugoi.i18n.Locale.texts;
		
		if (isFullyRegistred()) throw t._("This user cannot receive an invitation");
		
		var group : db.Amap = null;
		
		if (App.current.user == null) {			
			group = this.getAmaps().first();	
		}else {
			//prend l'amap du user connecté qui a lancé l'invite.
			group = App.current.user.amap;	
		}
		
		//store token
		var k = sugoi.db.Session.generateId();
		sugoi.db.Cache.set("validation" + k, this.id, 60 * 60 * 24 * 30); //expire in 1 month
		
		var e = new sugoi.mail.Mail();
		if (group != null){
			e.setSubject(t._("Invitation")+" "+group.name);	
		}else{
			e.setSubject(t._("Invitation Cagette.net"));
		}
		
		e.addRecipient(this.email,this.getName());
		e.setSender(App.config.get("default_email"),t._("Cagette.net"));			
		
		var html = App.current.processTemplate("mail/invitation.mtt", { 
			email:email,
			email2:email2,
			groupName:(group == null?null:group.name),			
			name:firstName,
			k:k 			
		} );		
		e.setHtmlBody(html);
		
		App.sendMail(e);	
	}
	
	/**
	 * cleaning before saving
	 */
	override public function insert() {
		clean();
		super.insert();
	}
	
	override public function update() {
		clean();
		super.update();
	}
	
	function clean() {
		
		//emails
		this.email = this.email.toLowerCase();
		if (this.email2 != null) this.email2 = this.email2.toLowerCase();
		
		//lastname
		this.lastName = this.lastName.toUpperCase();
		if (this.lastName2 != null) this.lastName2 = this.lastName2.toUpperCase();
	}
	
	/**
	 * get form labels
	 */
	public static function getLabels():Map<String,String>{
		var t = sugoi.i18n.Locale.texts;
		return [
			"firstName"	=>	t._("First name"),
			"lastName"	=>	t._("Last name"),
			"email"		=>	t._("Email"),
			"phone"		=>	t._("Phone"),
			"firstName2"=>	t._("Partner first name"),
			"lastName2"	=>	t._("Partner last name"),
			"email2"	=>	t._("Partner email"),
			"phone2"	=>	t._("Partner phone"),
			"lang"		=>	t._("Language"),
			"address1"	=>	t._("Address 1"),
			"address2"	=>	t._("Address 2"),
			"zipCode"	=>	t._("Zip code"),
			"city"		=>	t._("City"),
			"rights"	=>	t._("Rights"),
			"cdate"		=>	t._("Registration date"),
			"flags"		=>	t._("Options"),
			"pass"		=>	t._("Password"),
		];
	}
	
	
}
