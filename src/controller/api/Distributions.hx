package controller.api;

import haxe.DynamicAccess;
import tink.core.Error;
import db.UserGroup;
import haxe.Json;
import Common;
import db.MultiDistrib;
import service.VolunteerService;
import service.DistributionService;

class Distributions extends Controller {
	

	public function new() {
		super();
	}

	/**
		multidistribs data for volunteer roles assignements calendar
	**/
	function doVolunteerRolesCalendar(from:Date,to:Date){

		var group = app.getCurrentGroup();
		var user = app.user;
		var multidistribs = db.MultiDistrib.getFromTimeRange(group, from, to);
		var uniqueRoles = VolunteerService.getUsedRolesInMultidistribs(multidistribs);
		var out = [];

		for( md in multidistribs){
			var o = {
				id 					: md.id,
				distribStartDate	: md.distribStartDate,
				hasVacantVolunteerRoles: md.hasVacantVolunteerRoles(),
				canVolunteersJoin	: md.canVolunteersJoin(),
				volunteersRequired	: md.getVolunteerRoles().length,
				volunteersRegistered: md.getVolunteers().length,
				hasVolunteerRole	: null,
				volunteerForRole 	: null,
			};

			//populate hasVolunteerRole
			var hasVolunteerRole:Dynamic = {};
			for( role in uniqueRoles ){
				Reflect.setField(hasVolunteerRole,Std.string(role.id),md.hasVolunteerRole(role));
			}
			o.hasVolunteerRole = hasVolunteerRole;

			//populate volunteerForRole
			var volunteerForRole = {};
			for(role in uniqueRoles ) {
				var vol = md.getVolunteerForRole(role);
				if(vol!=null){
					Reflect.setField(volunteerForRole,Std.string(role.id),{id:vol.user.id,coupleName:vol.user.getCoupleName()});
				}else{
					Reflect.setField(volunteerForRole,Std.string(role.id),null);
				}
			}
			o.volunteerForRole = volunteerForRole;
			
			out.push(o);
		}

		json(out);
                    

	}

	/*private function checkAdminRights() {
		if (!App.current.user.isGroupManager()) {
			throw new tink.core.Error(403, "Forbidden, you're not group manager");
		}
		if (app.user.getGroup().id != this.distrib.getGroup().id) {
			throw new tink.core.Error(403, "Forbidden, this distrib does not belong to the group you're connected to");
		}
	}

	private function checkIsGroupMember() {
		// user must be logged
		if (app.user == null)
			throw new tink.core.Error(403, "Forbidden, user is null");

		// user must be member of group
		if (UserGroup.get(app.user, distrib.getGroup()) == null) {
			throw new tink.core.Error(403, "User is not member of this group");
		}
	}*/
}
