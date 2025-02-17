package service;
import Common;
import sugoi.mail.Mail;
import tink.core.Error;

/**
 * Volunteer Service
 * @author web-wizard
 */
class VolunteerService 
{

	public static function deleteVolunteerRole(role: db.VolunteerRole, ?force=false) {

		var t = sugoi.i18n.Locale.texts;
		
		if ( db.Volunteer.manager.count($volunteerRole == role) == 0 || force) {

			var roleId = Std.string(role.id);
			role.lock();
			role.delete();

			//Let's find all the multidistribs that have this role in volunteerRolesIds
			var roleIdInMultidistribs = Lambda.array( db.MultiDistrib.manager.search( $group == role.group && $volunteerRolesIds.like("%" + roleId + "%"), true ) );
			for ( multidistrib in roleIdInMultidistribs ) {

				var roleIds = multidistrib.volunteerRolesIds.split(',');
				if ( roleIds.remove(roleId) ) {
					multidistrib.volunteerRolesIds = roleIds.join(',');
					multidistrib.update();
				}
			}
		} else {
			var str = "Vous ne pouvez pas supprimer ce rôle car il y a des bénévoles inscrits à ce rôle.";
			str += "<a href='/amapadmin/volunteers/deleteRole/"+role.id+"?token="+App.current.view.token+"&force=1' class='btn btn-default'>Supprimer quand-même</a>";
			throw new Error( str );
		}
	}

	/**
		Update volunteers for a distrib (admin action)
	**/
	public static function updateVolunteers(multiDistrib: db.MultiDistrib, roleIdsToUserIds: Map<Int, Int>) {

		var t = sugoi.i18n.Locale.texts;

		var volunteerRoles = multiDistrib.getVolunteerRoles();
		if (volunteerRoles == null) {
			throw new Error(t._("You need to first select the volunteer roles for this distribution."));
		}

		//synchronize the map to a volunteer list
		var ls = new tools.ListSynchronizer< {role:Int,user:Int} , db.Volunteer>();

		var source = [];
		for( k in roleIdsToUserIds.keys()){
			if(k!=null && roleIdsToUserIds[k]!=null) source.push({role:k,user:roleIdsToUserIds[k]});
		}
		ls.setSourceDatas( source );
		ls.setDestinationDatas( multiDistrib.getVolunteers() );
		ls.isEqualTo = function(s,v){
			return s.user==v.user.id && s.role==v.volunteerRole.id;
		};
		ls.createNewEntity = function(s){
			var v = new db.Volunteer();
			v.user = db.User.manager.get(s.user,false);
			v.multiDistrib = multiDistrib;
			v.volunteerRole = db.VolunteerRole.manager.get(s.role,false);
			v.insert();
			return v;
		};
		ls.deleteEntity = function(v){
			v.delete();
		};
		ls.updateEntity = function(s,v){
			return v;
		};
		var newList = ls.sync();
	}

	/**
		A user suscribes to a role.
		An error is thrown if the role is already filled.
	**/
	public static function addUserToRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;
		if ( multidistrib == null ) throw "Multidistribution is null";
		if ( role == null ) throw "Role is null";
		if ( multidistrib.isConfirmed() ) throw new Error(t._("This distribution has already been validated"));

		//Check that the user is not already assigned to a role for this multidistrib
		/*var userAlreadyAssigned = multidistrib.getVolunteerForUser(user);
		if ( userAlreadyAssigned != null ) {
			throw new Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
		}
		*/
			
		var existingVolunteer = multidistrib.getVolunteerForRole(role);
		if ( existingVolunteer == null ) {
			var volunteer = new db.Volunteer();
			volunteer.user = user;
			volunteer.multiDistrib = multidistrib;
			volunteer.volunteerRole = role;					
			volunteer.insert();
			return volunteer;
		} else {
			throw new Error(t._("This role is already filled by a volunteer!"));
		}				
		
	}

	public static function removeUserFromRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole, reason: String ) {

		var t = sugoi.i18n.Locale.texts;
		if ( user != null && multidistrib != null && role != null ) {

			//Look for the volunteer for that user adn this role
			var foundVolunteer = Lambda.find(multidistrib.getVolunteerForUser(user), function(v) return v.volunteerRole.id==role.id);
			if ( foundVolunteer != null ) {

				//Send notification email to either the coordinators or all the members depending on the current date
				var mail = new Mail();
				mail.setSender(App.current.getTheme().email.senderEmail, App.current.getTheme().name);
				var now = Date.now();
				var alertDate = DateTools.delta( multidistrib.distribStartDate, - 1000.0 * 60 * 60 * 24 * multidistrib.group.vacantVolunteerRolesMailDaysBeforeDutyPeriod );

				if ( now.getTime() <=  alertDate.getTime() ) {

					//Recipients are the coordinators
					var rights = if(foundVolunteer.volunteerRole.catalog==null){
						[ Right.GroupAdmin ];
					}else{
						[ Right.ContractAdmin(foundVolunteer.volunteerRole.catalog.id) ];
					}
					var adminUsers = service.GroupService.getGroupMembersWithRights( multidistrib.group, rights );
					for ( admin in adminUsers ) {
						mail.addRecipient( admin.email, admin.getName() );
						if ( admin.email2 != null ) {
							mail.addRecipient( admin.email2 );
						}
					}
				}else{

					var members = Lambda.array( multidistrib.group.getMembers() );
					//Recipients are all members
					for ( member in members ) {
						mail.addRecipient( member.email, member.getName() );
						if ( member.email2 != null ) {
							mail.addRecipient( member.email2 );
						}
					}
				}
				var date = App.current.view.hDate(multidistrib.distribStartDate);
				var subject = t._( "A role has been left for ::date:: distribution",{date:date});
				mail.setSubject( subject );
				var html = App.current.processTemplate("mail/volunteerUnsuscribed.mtt", { fullname : user.getName(), role : role.name, reason : reason, group: multidistrib.group  } );
				mail.setHtmlBody( html );
				App.sendMail(mail, multidistrib.group);

				//delete assignment
				foundVolunteer.lock();
				foundVolunteer.delete();
			} else {				
				throw new Error(t._("This user is not assigned to this role!"));				
			}
		} else {
			throw new Error(t._("Missing distribution or role in the url!"));
		}			
	}

	/**
		update roles needed for distribution
	**/
	public static function updateMultiDistribVolunteerRoles(multidistrib: db.MultiDistrib, rolesIds: Array<Int>) {

		var t = sugoi.i18n.Locale.texts;
		var volunteers = multidistrib.getVolunteers();
		

		// is there volunteers registred for a role that is not needed anymore
		if ( volunteers != null && volunteers.length>0 ) {			
			for ( volunteer in volunteers ) {
				if( Lambda.find(rolesIds, function(roleId) return roleId==volunteer.volunteerRole.id)==null ){
					throw new Error('Impossible de désélectionner le rôle "${volunteer.volunteerRole.name}", car il y a des personnes qui se sont inscrites à ce rôle (${volunteer.user.getName()})');
				}				
			}
		}
		
		//update roles
		multidistrib.lock();
		rolesIds = tools.ArrayTool.deduplicate(rolesIds);
		multidistrib.volunteerRolesIds = rolesIds.join(",");
		multidistrib.update();
	}

	public static function createRoleForContract(c:db.Catalog,number:Int){
		var t = sugoi.i18n.Locale.texts;
		number = number>20 ? 20 : number;
		for ( i in 1...(number+1) ) {
			
			var role = new db.VolunteerRole();
			role.name = t._("Duty period");
			role.name += " " + c.name + " " + i;
			role.group = c.group;
			role.catalog = c;
			role.insert();	
		}
	}

	public static function isNumberOfDaysValid( numberOfDays: Int, type: String ) {

		var t = sugoi.i18n.Locale.texts;

		switch( type ) {

			case "volunteersCanJoin":
				if ( numberOfDays <  7 ) {
					throw new Error(t._("The number of days before the volunteers can join a duty period needs to be greater than 6 days."));
				} else if ( numberOfDays > 181 ) {
					throw new Error(t._("The number of days before the volunteers can join a duty period needs to be lower than 181 days."));
				}

			case "instructionsMail":
				if ( numberOfDays <  2 ) {
					throw new Error(t._("The number of days before the duty periods to send the instructions mail to all the volunteers needs to be greater than 1 day."));
				} else if ( numberOfDays > 15 ) {
					throw new Error(t._("The number of days before the duty periods to send the instructions mail to all the volunteers needs to be lower than 15 days."));
				}

			case "vacantRolesMail":
				if ( numberOfDays <  2 ) {
					throw new Error(t._("The number of days before the duty periods to send the vacant roles mail to all members needs to be greater than 1 day."));
				} else if ( numberOfDays > 15 ) {
					throw new Error(t._("The number of days before the duty periods to send the instructions mail to all members needs to be lower than 15 days."));
				}
		}
		
	}

	public static function getRolesFromGroup(group:db.Group):Array<db.VolunteerRole>{
		return Lambda.array(db.VolunteerRole.manager.search($group==group,{orderBy:[catalogId,name]}));
	}

	public static function getRolesFromContract(catalog:db.Catalog):Array<db.VolunteerRole>{
		return Lambda.array(db.VolunteerRole.manager.search($catalog==catalog,{orderBy:[catalogId,name]}));
	}

	/**
		Get user participation in this group on a defined timeframe.
	**/
	public static function getUserParticipation(users:Array<db.User>,group:db.Group,from:Date,to:Date){

		//map key is userId
		var out = new Map<Int,{genericRolesDone:Int, genericRolesToBeDone:Int, contractRolesDone:Int, contractRolesToBeDone:Int}>();

		var multiDistribs = db.MultiDistrib.getFromTimeRange(group, from, to);
		var members = group.getMembers();
		
		var genericRolesToBeDone = 0;	

		var contractRolesToBeDoneByContractId = new Map<Int, Int>();
		var membersNumByContractId = new Map<Int, Int>();
		var membersListByContractId = new Map<Int, Array<db.User>>();

		multiDistribs.foreach(md -> md.useCache=true);

		for (md in multiDistribs) {
			for (role in md.getVolunteerRoles()) {
				if (role.isGenericRole()) {
					genericRolesToBeDone++;
				} else {
					if (contractRolesToBeDoneByContractId[role.catalog.id] == null) {
						contractRolesToBeDoneByContractId[role.catalog.id] = 1;
					} else {
						contractRolesToBeDoneByContractId[role.catalog.id]++;
					}
				}
			}
		}

		// generic roles to be done spread over members
		genericRolesToBeDone = Math.ceil(genericRolesToBeDone / members.length);

		// populate member list by contract id
		for (cid in contractRolesToBeDoneByContractId.keys()){
			membersListByContractId[cid] = [];
		}
		for (md in multiDistribs) {
			var distributions = md.getDistributions();
			if(distributions.length==0) continue;
			var dids = distributions.map(d->d.id);
			//build orders list made in all these distribs
			var orders = new Map<Int,Array<db.UserOrder>>();	//key is distribution Id
			for( o in db.UserOrder.manager.search($distributionId in dids,false)){
				var did:Int = untyped o.distributionId;
				if(orders.get(did)==null){
					orders.set(did,[]);
				} 

				var distribOrders = orders.get(did);
				distribOrders.push(o);
				orders.set(did,distribOrders);
			}

			for (d in distributions) {
				if (membersListByContractId[d.catalog.id] == null) {
					// this contract has no roles
					continue;
				}

				for (u in members) {
					var catId = d.catalog.id;
					//do not search if user has orders if is already in the list
					if( membersListByContractId[catId].find(user -> user.id==u.id) == null){
						//do not user d.hasUserOrder(u) because its very DB intensive !!
						/*if (d.hasUserOrders(u)) {
							membersListByContractId[catId].push(u);
						}*/
						if( orders.get(d.id)!=null && orders.get(d.id).find(order -> untyped order.userId==u.id || untyped order.user2Id==u.id) != null ){
							membersListByContractId[catId].push(u);
						}


					}
				}
			}
		}

		//populate members num by contract Id
		for (cid in membersListByContractId.keys()) {
			membersListByContractId[cid] = tools.ObjectListTool.deduplicate(membersListByContractId[cid]);
			membersNumByContractId[cid] = membersListByContractId[cid].length;
		}


		//compute values for each user
		for( user in users ){

			var o = {
				genericRolesDone : 0,   	//generic roles done (registered to a generic role)
				genericRolesToBeDone : genericRolesToBeDone, //number of generic role occurences divided by the number of group members (same for all group users)
				contractRolesDone : 0, 		//contract roles done (registered to a contract role)
				contractRolesToBeDone : 0 	//sum of (contract roles occurences divided by the number of contract suscribers) for each contract
			};

			// populate genericRolesDone and contractRolesDone
			for (md in multiDistribs) {			
				for (v in md.getVolunteers()) {
					if (v.user.id != user.id)
						continue;
					if (v.volunteerRole.isGenericRole()) {
						o.genericRolesDone++;
					} else {
						o.contractRolesDone++;
					}
				}
			}

			for (cid in membersListByContractId.keys()) {
				// if this user is involved in this contract
				if ( membersListByContractId[cid].find( u -> u.id == user.id) != null) {
					// role to be done for this user = contract roles to be done for this contract / members num involved in this contract
					o.contractRolesToBeDone += Math.ceil(contractRolesToBeDoneByContractId[cid] / membersNumByContractId[cid]);
				}
			}

			out.set(user.id,o);
		}

		return out;
	}


	/**
		get unique roles needed in a list of multidistribs
	**/
	public static function getUsedRolesInMultidistribs(multidistribs:Array<db.MultiDistrib>):Array<db.VolunteerRole>{

		// Let's find all the unique volunteer roles for this set of multidistribs
		var uniqueRolesIds = [];
		for (md in multidistribs) {
			uniqueRolesIds = uniqueRolesIds.concat(md.getVolunteerRoleIds());			
		}
		var uniqueRoles = tools.ArrayTool.deduplicate(uniqueRolesIds).map( rid -> return db.VolunteerRole.manager.get(rid,false));
		uniqueRoles = uniqueRoles.filter(u -> u!=null);

		//sort by catalog id and role name
		uniqueRoles.sort(function(b, a) {
			var a_str = (a.catalog == null ? "null" : Std.string(a.catalog.id)) + a.name.toLowerCase();
			var b_str = (b.catalog == null ? "null" : Std.string(b.catalog.id)) + b.name.toLowerCase();
			return a_str < b_str ? 1 : -1;
		});

		return uniqueRoles;

	}
	
	

}