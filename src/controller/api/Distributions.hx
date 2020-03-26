package controller.api;
import haxe.Json;
import Common;
import db.MultiDistrib;

/**
 * Groups API
 * @author fbarbut
 */
class Distributions extends Controller {

  private var distrib: db.MultiDistrib;

  public function new(distrib: db.MultiDistrib) {
    super();
    this.distrib = distrib;
  }

  public function doActivateSlots() {
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");
    if (!App.current.user.isAmapManager()) throw new tink.core.Error(403, "Forbidden");
    if (this.distrib.slots != null) throw new tink.core.Error(403, "Forbidden");

    this.distrib.generateSlots();
    
    Sys.print(Json.stringify(this.distrib.slots));
  }

  public function doRegisterUserSlots(slotIdsQuery: String) {
    // allow only POST method
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");

    // TODO : distrib should be opened

    // user must be logged
    if (App.current.user == null) throw new tink.core.Error(403, "Forbidden");
    
    // user must be member of group
    // TODO if (!App.current.user.isMemberOf(this.distrib.getGroup())) throw new tink.core.Error(403, "Forbidden");
    
    // distrib slots must be activated 
    if (this.distrib.slots == null) throw new tink.core.Error(403, "Forbidden");

    // parse query to slotIds
    var slotIds = new Array<Int>();
    var strSlotIds = slotIdsQuery.split(",");
    for (index in 0...strSlotIds.length) {
      slotIds.push(Std.parseInt(strSlotIds[index]));
    }

    // check slots validity
    if (slotIdsQuery == "" || slotIds.length < 1) throw new tink.core.Error(400, "Bad Request");
    for (slotId in 0...slotIds.length) {
      if (Lambda.find(this.distrib.slots, (slot) -> slot.id == slotId) == null) {
        throw new tink.core.Error(400, "Bad Request");
      }
    }

    this.distrib.registerUserToSlot(App.current.user.id, slotIds);

    Sys.print(Json.stringify({message: "success", slots: this.distrib.slots}));
  }

  public function doTest() {
    var fakeUserIds = new Array<Int>();
    for (i in 0...15) {
      fakeUserIds.push(i);
    }

    this.distrib.generateSlots(true);

    this.distrib.registerUserToSlot(fakeUserIds[0], [0]);
    this.distrib.registerUserToSlot(fakeUserIds[1], [0, 1, 2, 3]);

    for (userIndex in 2...fakeUserIds.length) {
      var slotIds = new Array<Int>();
      for (slotIndex in 0...this.distrib.slots.length) {
        var slot = this.distrib.slots[slotIndex];
        if (Math.random() > 0.7) {
          slotIds.push(slot.id);
        }
      }
      this.distrib.registerUserToSlot(fakeUserIds[userIndex], slotIds);
    }

    Sys.print(Json.stringify({
      // slots: this.distrib.slots,
      result: this.distrib.resolveSlots()
    }));
  }
}