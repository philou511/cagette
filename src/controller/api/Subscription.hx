package controller.api;
import haxe.Json;
import neko.Web;

class Subscription extends Controller
{

	public function doDefault(sub:db.Subscription){

        // Create a new sub
        var post = StringTools.urlDecode( sugoi.Web.getPostData() );
        if(post!=null && sub==null){
            /**
            {
                distributions:[
                    {id:id,orders:[
                        
                    ]}
                ]
            }

            **/
            var newSubData = Json.parse(post);
            

        }    

        return json({
            startDate : sub.startDate,
            endDate : sub.endDate,
            user : sub.user.infos(),
            user2 : sub.user2==null ? null : sub.user2.infos(),
            catalogId : sub.catalog.id
        });

    }

}