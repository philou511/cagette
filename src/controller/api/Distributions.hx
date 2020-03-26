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

    this.distrib.lock();
    
    var slotDuration = 1000 * 60 * 15;
    var nbSlots = Math.floor((this.distrib.distribEndDate.getTime() - this.distrib.distribStartDate.getTime()) / slotDuration);
    this.distrib.slots = new Array<Slot>();
    for (slotId in 0...nbSlots) {
      this.distrib.slots.push({
        id: slotId,
        distribId: this.distrib.id,
        selectedUserIds: new Array<Int>(),
        registeredUserIds: new Array<Int>(),
        start: DateTools.delta(this.distrib.distribStartDate, slotDuration * slotId),
        end: DateTools.delta(this.distrib.distribStartDate, (slotDuration + 1) * slotId),
      });
    }

    this.distrib.update();

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

    this.distrib.lock();

    // check slots validity
    var slotIds = slotIdsQuery.split(",");
    if (slotIdsQuery == "" || slotIds.length < 1) throw new tink.core.Error(400, "Bad Request");
    for (slotId in 0...slotIds.length) {
      if (Lambda.find(this.distrib.slots, (slot) -> slot.id == slotId) == null) {
        throw new tink.core.Error(400, "Bad Request");
      }
    }

    // add user to slots
    var updatedSlots = Lambda.map(this.distrib.slots, (slot) -> {
      if (slotIds.indexOf(Std.string(slot.id)) != -1) {
        return slot;
      }
      var updatedSlot = slot;
      updatedSlot.registeredUserIds.push(App.current.user.id);
      return updatedSlot;
    });

    // this.distrib.slots = updatedSlots;
    this.distrib.update();

    Sys.print(Json.stringify({message: "success", slots: this.distrib.slots}));
  }
}