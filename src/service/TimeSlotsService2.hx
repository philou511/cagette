package service;

import tools.DateTool;
import haxe.Json;

typedef Slot2 = {
	var id:Int;
	var start:Date;
	var end:Date;
	var registeredUserIds:Array<Int>;
	var selectedUserIds:Array<Int>;
};

typedef SlotJSon = {
	var id:Int;
	var start:String;
	var end:String;
	var registeredUserIds:Array<Int>;
	var selectedUserIds:Array<Int>;
};

class TimeSlotsService2 {
	private var distribution:db.MultiDistrib;
	private var timeSlots:Null<Array<Slot2>>;

	public function new(d:db.MultiDistrib) {
		this.distribution = d;
		if (distribution.timeSlots != null) {
			var parsed: Array<SlotJSon> = Json.parse(distribution.timeSlots);
			this.timeSlots = []; 
			Lambda.foreach(parsed, function(p) {
				this.timeSlots.push({
					id: p.id,
					start: DateTool.fromJs(p.start),
					end: DateTool.fromJs(p.end),
					registeredUserIds: p.registeredUserIds,
					selectedUserIds: p.selectedUserIds,
				});
				return true;
			});
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

		var isResolved = Lambda.fold(this.timeSlots, function(slot, acc) {
			if (acc == true)
				return acc;
			if (slot.selectedUserIds.length > 0) {
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

		var selectedSlotId = null;
		if (registered) {
			Lambda.foreach(this.timeSlots, function(slot) {
				if (slot.selectedUserIds.indexOf(userId) != -1) {
					selectedSlotId = slot.id;
				}
				return true;
			});
		}

		var out = {
			registered: registered,
			isResolved: isResolved,
			registeredSlotIds: registeredSlotIds,
			selectedSlotId: selectedSlotId,
		};
		
		return out;
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
