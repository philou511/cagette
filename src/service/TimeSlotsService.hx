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

class TimeSlotsService {
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

	public function updateUserToSlot(userId: Int, slotIds: Array<Int>) {
		if (distribution.slots == null) return false;
		if (!userIsAlreadyAdded(userId)) return false;

		distribution.lock();
		distribution.slots = distribution.slots.map(slot -> {
			slot.registeredUserIds = slot.registeredUserIds.filter(id -> id != userId);
			return slot;
		});
		distribution.slots = distribution.slots.map(slot -> {
			if (slotIds.indexOf(slot.id) != -1) {
				slot.registeredUserIds.push(userId);
			}
			return slot;
		});
		distribution.update();
		return true;
	}

	



}


typedef Slot = {
	id: Int,
  	distribId: Int,
  	selectedUserIds: Array<Int>,
	registeredUserIds: Array<Int>,
	start: Date,
  	end: Date
}

// typedef SlotResolver = {
// 	id: Int,
// 	selectedUserIds: Array<Int>,
//   potentialUserIds: Array<Int>,
// }

class SlotResolver {
	public var id(default, null): Int;
	public var potentialUserIds(default, null): Array<Int>;
	public var selectedUserIds(default, null): Array<Int>;

	public function new (id: Int, potentialUserIds: Array<Int>, ?selectedUserIds: Array<Int>) {
		this.id = id;
		this.potentialUserIds = potentialUserIds;
		this.selectedUserIds = (selectedUserIds == null) ? new Array<Int>() : selectedUserIds;
	}

	public function selectUser(userId: Int) {
		var founded = false;
		this.potentialUserIds = this.potentialUserIds.filter(id -> {
			if (userId == id) {
				founded = true;
				return false;
			}
			return true;
		});
		return founded;
	}
}
