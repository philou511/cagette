package controller.amapadmin;
import sugoi.form.elements.IntInput;
import sugoi.form.elements.IntSelect;
import sugoi.form.elements.StringInput;
import sugoi.form.elements.TextArea;

class Volunteers extends controller.Controller
{
	@tpl("amapadmin/volunteers/default.mtt")
	function doDefault() {

		view.volunteerRoles = db.VolunteerRole.manager.search($group == app.user.amap);
		
		checkToken();

		var form = new sugoi.form.Form("msg");
		form.addElement( new IntInput("dutyperiodsopen", t._("Number of days before duty periods open to volunteers:"), app.user.amap.daysBeforeDutyPeriodsOpen, true) );
		form.addElement( new IntInput("maildays", t._("Number of days before duty period to send mail:"), app.user.amap.volunteersMailDaysBeforeDutyPeriod, true) );
		form.addElement( new TextArea("mailcontent", t._("Message:"), app.user.amap.volunteersMailContent, true, null, "style='height:300px;'") );
		form.addElement( new IntInput("alertmaildays", t._("Number of days before duty period to send mail for vacant volunteer roles:"), app.user.amap.vacantVolunteerRolesMailDaysBeforeDutyPeriod, true) );

		if (form.isValid()) {
			
			app.user.amap.lock();
			app.user.amap.daysBeforeDutyPeriodsOpen = form.getValueOf("dutyperiodsopen");
			app.user.amap.volunteersMailDaysBeforeDutyPeriod = form.getValueOf("maildays");
			app.user.amap.volunteersMailContent = form.getValueOf("mailcontent");
			app.user.amap.vacantVolunteerRolesMailDaysBeforeDutyPeriod = form.getValueOf("alertmaildays");
			app.user.amap.update();
			
			throw Ok("/amapadmin/volunteers", t._("Volunteers Mail has been successfully updated"));
			
		}
		
		view.form = form;

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

			try {

				service.VolunteerService.deleteVolunteerRole(role);
			}
			catch(e: tink.core.Error){

				throw Error("/amapadmin/volunteers", e.message);
			}

			throw Ok("/amapadmin/volunteers", t._("Volunteer Role has been successfully deleted"));
		}
		else {

			throw Redirect("/amapadmin/volunteers");

		}
	}
	
}
