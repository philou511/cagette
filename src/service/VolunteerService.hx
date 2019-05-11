package service;
import Common;
import tink.core.Error;

/**
 * Volunteer Service
 * @author web-wizard
 */
class VolunteerService 
{

	public static function deleteVolunteerRole(role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;

		if ( db.Volunteer.manager.count($volunteerRole == role) == 0 ) {

			role.lock();
			role.delete();
		}
		else {

			throw new tink.core.Error(t._("You can't delete this role because there are volunteers assigned to this role. You need to delete the volunteers first."));
		}
	}

	public static function updateVolunteers(multidistrib: db.MultiDistrib, rawData: Map<String, Dynamic>) {

		var t = sugoi.i18n.Locale.texts;

		var userIdByRoleId = new Map<Int, Int>();
		var uniqueUserIds = [];
		var volunteerRoles = multidistrib.getVolunteerRoles();
		if (volunteerRoles == null) {

			throw new Error(t._("You need to first select the volunteer roles for this distribution."));
		}

		for ( role in volunteerRoles ) {

			var userId = rawData[Std.string(role.id)];
			if ( !Lambda.has(uniqueUserIds, userId) ) {

				if( userId != null ) {
					uniqueUserIds.push(userId);
				}
				userIdByRoleId[role.id] = userId;
			}
			else {

				throw new Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
			}				
		}

		var volunteers = multidistrib.getVolunteers();
		for ( volunteer in volunteers ) {

			var userIdForThisRole = userIdByRoleId[volunteer.volunteerRole.id];
			if ( userIdForThisRole != volunteer.user.id ) {
			
				volunteer.lock();
				if ( userIdForThisRole == null ) {

					volunteer.delete();
				} 
				else {

					var volunteerCopy = new db.Volunteer();
					volunteerCopy.user = db.User.manager.get(userIdForThisRole);
					volunteerCopy.multiDistrib = multidistrib;
					volunteerCopy.volunteerRole = volunteer.volunteerRole;					
					volunteerCopy.insert();		
					volunteer.delete();				
				}

				userIdByRoleId.remove(volunteer.volunteerRole.id);
			
			}
			else {
				
				userIdByRoleId.remove(volunteer.volunteerRole.id);
			}
		}

		for ( roleId in userIdByRoleId.keys() ) {

			var userIdForThisRole = userIdByRoleId[roleId];
			if ( userIdForThisRole != null ) {

				var volunteer = new db.Volunteer();
				volunteer.user = db.User.manager.get(userIdForThisRole);
				volunteer.multiDistrib = multidistrib;
				volunteer.volunteerRole = db.VolunteerRole.manager.get(roleId);					
				volunteer.insert();

			}					
		}
		
	}

	public static function addUserToRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;
		if ( multidistrib == null ) throw new Error(t._("Multidistribution is null"));
		if ( role == null ) throw new Error(t._("Role is null"));

		//Check that the user is not already assigned to a role for this multidistrib
		var userAlreadyAssigned = multidistrib.getVolunteerForUser(user);
		if ( userAlreadyAssigned != null ) {

			throw new tink.core.Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
		}
		else {
			
			var existingVolunteer = multidistrib.getVolunteerForRole(role);
			if ( existingVolunteer == null ) {
				var volunteer = new db.Volunteer();
				volunteer.user = user;
				volunteer.multiDistrib = multidistrib;
				volunteer.volunteerRole = role;					
				volunteer.insert();
			}
			else {

				throw new tink.core.Error(t._("This role is already filled by a volunteer!"));
			}				
		}
				

	}

	public static function removeUserFromRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;
		if ( user != null && multidistrib != null && role != null ) {

			//Look for the volunteer for that user
			var foundVolunteer = multidistrib.getVolunteerForUser(user);
			if ( foundVolunteer != null && foundVolunteer.volunteerRole.id == role.id ) {

				foundVolunteer.lock();
				foundVolunteer.delete();
			}
			else {
				
				throw new tink.core.Error(t._("This user is not assigned to this role!"));				
			}
		}
		else {

			throw new tink.core.Error(t._("Missing distribution or role in the url!"));
		}			
	}

	public static function updateMultiDistribVolunteerRoles(multidistrib: db.MultiDistrib, rolesIds: String) {

		var t = sugoi.i18n.Locale.texts;

		var volunteers = multidistrib.getVolunteers();

		if ( volunteers != null ) {

			var roleIds = rolesIds.split(',');
			for ( roleId in roleIds ) {

				volunteers = Lambda.array(Lambda.filter(volunteers, function(volunteer) return volunteer.volunteerRole.id != Std.parseInt(roleId)));
			}
		}
		
		if ( volunteers == null || volunteers.length == 0 ) {

			multidistrib.lock();
			multidistrib.volunteerRolesIds = rolesIds;
			multidistrib.update();
		}
		else {

			throw new tink.core.Error(t._("You can't remove some roles because there are volunteers assigned to those roles. You need to delete the volunteers first."));
		}
	}

	public static function createRoleForContract(c:db.Contract,number:Int){
		var t = sugoi.i18n.Locale.texts;
		for ( i in 1...(number+1) ) {
			
			var role = new db.VolunteerRole();
			role.name = t._("Duty period") + " " + c.name + " " + i;
			role.group = c.amap;
			role.contract = c;
			role.insert();
		
		}
	} 

}