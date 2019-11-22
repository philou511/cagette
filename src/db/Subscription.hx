package db;
import sys.db.Object;
import sys.db.Types;
import Common;

class Subscription extends Object {

	public var id : SId;
	@formPopulate("populate") @:relation(userId) public var user : db.User;
	@:relation(catalogId) public var catalog : db.Catalog;
	public var startDate : SDate;
	public var endDate : SDate;

	public function populate() {
		
		return App.current.user.getGroup().getMembersFormElementData();
	}

	public static function getLabels() {

		var t = sugoi.i18n.Locale.texts;
		return [
			"user" 				=> t._("Member"),
			"startDate" 		=> t._("Start date"),
			"endDate" 			=> t._("End date")	
		];
	}
	
}