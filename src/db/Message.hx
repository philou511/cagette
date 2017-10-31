package db;
import sys.db.Object;
import sys.db.Types;
import tink.core.Noise;
import tink.core.Outcome;
import sugoi.mail.IMailer;


/**
 * log of sent emails
 */
class Message extends Object
{

	public var id : SId;
	@:relation(amapId) public var amap : SNull<Amap>;
	@:relation(senderId) public var sender : SNull<User>;
	
	public var recipientListId : SNull<SString<12>>;
	public var recipients : SNull<SData<Array<String>>>;
	
	public var title : SString<128>;
	public var body : SText;	
	public var date : SDateTime;
	
	public var rawStatus : SNull<SText>;
	public var status : SNull<SData<MailerResult>>; //map of emails with api/smtp results
	
	
	public function getMailerResultMessage(k:String):{failure:String, success:String}{
		var out = {failure:null, success:null};
		switch(status.get(k)){
			case tink.core.Outcome.Failure(f):
				out.failure = switch(f){
					case GenericError(e):
						t._("Generic error: ") + e.toString();
					case HardBounce : 
						t._("Mailbox does not exist");
					case SoftBounce : 
						t._("Mailbox full or blocked");
					case Spam:
						t._("Message considered as spam");
					case Unsub:
						t._("This user unsubscribed");
					case Unsigned:
						t._("Sender incorrect (Unsigned)");
					
				};
			case tink.core.Outcome.Success(d):
				out.success = t._("Sent");
		}
		return out;
		
	}
	
}