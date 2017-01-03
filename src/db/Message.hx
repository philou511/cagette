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
	@:relation(amapId) public var amap : Amap;
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
						"Erreur générique : " + e.toString();
					case HardBounce : 
						"Boîte email inexistante";
					case SoftBounce : 
						"Boîte email pleine ou bloquée";
					case Spam:
						"Message considéré comme spam";
					case Unsub:
						"Cet utilisateur s'est désabonné (Unsub)";
					case Unsigned:
						"Expéditeur incorrect (Unsigned)";
					
				};
			case tink.core.Outcome.Success(d):
				out.success = "Envoyé";
		}
		return out;
		
	}
	
}