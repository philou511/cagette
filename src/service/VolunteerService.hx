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

}