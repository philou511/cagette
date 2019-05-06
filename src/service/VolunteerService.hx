package service;
import Common;

/**
 * Volunteer Service
 * @author web-wizard
 */
class VolunteerService 
{

	public static function updateVolunteers(multiDistrib: db.MultiDistrib, rawData: Map<String, Dynamic>) {

		var t = sugoi.i18n.Locale.texts;

		var userIdByRoleId = new Map<Int, Int>();
		var uniqueUserIds = [];
		var roleIds = [];
		if (multiDistrib.volunteerRolesIds != null) {

			roleIds = multiDistrib.volunteerRolesIds.split(",");
		}
		else {

			throw new tink.core.Error(t._("You need to first select the volunteer roles for this distribution."));
		}

		for ( id in roleIds ) {

			var userId = rawData[id];
			if ( !Lambda.has(uniqueUserIds, userId) ) {

				if( userId != null ) {
					uniqueUserIds.push(userId);
				}
				userIdByRoleId[Std.parseInt(id)] = userId;
			}
			else {

				throw new tink.core.Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
			}				
		}

		var volunteers = db.Volunteer.manager.search($multiDistrib == multiDistrib);
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
					volunteerCopy.multiDistrib = multiDistrib;
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
				volunteer.multiDistrib = multiDistrib;
				volunteer.volunteerRole = db.VolunteerRole.manager.get(roleId);					
				volunteer.insert();

			}					
		}
		
	}

	public static function addUserToRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;
		if ( multidistrib != null && role != null ) {

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
		else {

			throw new tink.core.Error(t._("Missing distribution or role in the url!"));
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

}