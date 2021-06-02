package service;

import haxe.Json;

typedef Slot2 = {
	var id:Int;
	var start:Date;
	var end:Date;
	var registeredUserIds:Array<Int>;
	var selectedUserIds:Array<Int>;
};

class TimeSlotsService2 {
	var distribution:db.MultiDistrib;
	var timeSlots:Null<Array<Slot2>>;

	public function new(d:db.MultiDistrib) {
		this.distribution = d;
		if (distribution.timeSlots != null) {
			this.timeSlots = Json.parse(distribution.timeSlots);
		} else {
			this.timeSlots = null;
		}
	}

	public function userStatus(userId:Int) {
		if (this.timeSlots == null) {
			return null;
		}

		var registered = Lambda.fold(this.timeSlots, function(slot, acc) {
			if (acc == true)
				return acc;
			if (slot.registeredUserIds.indexOf(userId) != -1) {
				return true;
			}
			return acc;
		}, false);

		var registeredSlotIds:Array<Int> = [];
		if (registered == true) {
			Lambda.foreach(this.timeSlots, function(slot) {
				if (slot.registeredUserIds.indexOf(userId) != -1) {
					registeredSlotIds.push(slot.id);
				}
				return true;
			});
		}

		return {
			registered: registered,
			isResolved: Lambda.fold(this.timeSlots, function(slot, acc) {
				if (acc == true)
					return acc;
				if (slot.selectedUserIds.length > 0) {
					return true;
				}
				return acc;
			}, false),
			registeredSlotIds: registeredSlotIds
		}
	}

	public function getSlots() {
		return this.timeSlots;
	}

	public function getSlotById(slotId:Int) {
		var founded = null;
		Lambda.foreach(this.timeSlots, function(slot) {
			if (slot.id == slotId) {
				founded = slot;
			}
			return true;
		});
		return founded;
	}
}
