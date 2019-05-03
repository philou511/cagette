package service;
import Common;
import tink.core.Error;

/**
 * Volunteer Service
 * @author web-wizard
 */
class VolunteerService
{
	public static function updateVolunteers(multiDistrib: db.MultiDistrib, userIdByRoleId: Map<Int, Int>) {

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