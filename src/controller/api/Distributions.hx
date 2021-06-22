package controller.api;

import haxe.DynamicAccess;
import tink.core.Error;
import db.UserGroup;
import haxe.Json;
import Common;
import db.MultiDistrib;

class Distributions extends Controller {
	private var distrib:db.MultiDistrib;

	public function new(distrib:db.MultiDistrib) {
		super();
		this.distrib = distrib;
	}

	// public function doSlots(d:haxe.web.Dispatch) {
	// 	d.dispatch(new controller.api.DistributionsSlots(distrib));
	// }

	private function checkAdminRights() {
		if (!App.current.user.isGroupManager()) {
			throw new tink.core.Error(403, "Forbidden, you're not group manager");
		}
		if (app.user.getGroup().id != this.distrib.getGroup().id) {
			throw new tink.core.Error(403, "Forbidden, this distrib does not belong to the groupe you're connected to");
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
	}
}
