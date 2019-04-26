package controller.amapadmin;
import sugoi.form.elements.IntSelect;
import sugoi.form.elements.StringInput;

class Volunteers extends controller.Controller
{
	@tpl("amapadmin/volunteers/default.mtt")
	function doDefault() {

		view.volunteerRoles = db.VolunteerRole.manager.search($group == app.user.amap);
		
		checkToken();

	}

	/**
		Insert a volunteer role
	**/
	@tpl("form.mtt")
	function doInsertRole() {

		var role = new db.VolunteerRole();
		var form = new sugoi.form.Form("volunteerrole");

		form.addElement( new StringInput("name", t._("Volunteer role name"), null, true) );
		var activeContracts = Lambda.array(Lambda.map(app.user.amap.getActiveContracts(), function(contract) return { label: contract.name, value: contract.id }));
		form.addElement( new IntSelect('contract',t._("Contract"), activeContracts, null, false, t._("All contracts")) );
	                                                
		if (form.isValid()) {
			
			role.name = form.getValueOf("name");
			role.group = app.user.amap;
			var contractId = form.getValueOf("contract");
		
			if (contractId != null)  
			{
				role.contract = db.Contract.manager.get(contractId);
			}
			role.insert();
			throw Ok("/amapadmin/volunteers", t._("Volunteer Role has been successfully added"));
			
		}

		view.title = t._("Create a volunteer role");
		view.form = form;

	}

	/**
	 * Edit a volunteer role
	 */
	@tpl('form.mtt')
	function doEditRole(role:db.VolunteerRole) {

		var form = new sugoi.form.Form("volunteerrole");

		form.addElement( new StringInput("name", t._("Volunteer role name"), role.name, true) );
		var activeContracts = Lambda.array(Lambda.map(app.user.amap.getActiveContracts(), function(contract) return { label: contract.name, value: contract.id }));
		var defaultContractId = role.contract != null ? role.contract.id : null;
		form.addElement( new IntSelect('contract',t._("Contract"), activeContracts, defaultContractId, false, t._("All contracts")) );
	                                                
		if (form.isValid()) {
			
			role.lock();

			role.name = form.getValueOf("name");
			var contractId = form.getValueOf("contract");
			role.contract = contractId != null ? db.Contract.manager.get(contractId) : null;
			
			role.update();

			throw Ok("/amapadmin/volunteers", t._("Volunteer Role has been successfully updated"));
			
		}

		view.title = t._("Create a volunteer role");
		view.form = form;

	}

	/**
	 * Delete a volunteer role
	 */
	function doDeleteRole(role: db.VolunteerRole, args: { token:String }) {

		if ( checkToken() ) {

			if (db.Volunteer.manager.count($volunteerRole == role) == 0) {

				role.lock();
				role.delete();
				throw Ok("/amapadmin/volunteers", t._("Volunteer Role has been successfully deleted"));

			}
			else {

				throw Error('/amapadmin/volunteers', t._("You can't delete this role because some users are linked to it."));

			}
			
		}
		else {

			throw Redirect("/amapadmin/volunteers");

		}
		
	}
		
}
