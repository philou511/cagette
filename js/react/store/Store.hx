package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import js.html.XMLHttpRequest;
import haxe.Json;

// typedef RegisterBoxState = {

// };

/**
 * ...
 * @author fbarbut
 */
class Store extends react.ReactComponent
{
  public function new() {
    super();
    var url = '/api/shop/categories?date=2017-11-17&place=872';

    var request = new XMLHttpRequest();
    request.open('GET', url, true);

    // if (contentType != null && contentType.length > 0)
    //   http.setRequestHeader("Content-type", contentType);

    // if (accept != null)
    //   http.setRequestHeader("Accept", accept);

    request.onreadystatechange = function() {
      if (request.readyState == XMLHttpRequest.DONE)
      {
        try {
          var json = Json.parse(request.responseText);
          trace('SUCCESS', json);
          // resolve(json);
        }
        catch (err: Dynamic)
          trace('ERROR', err);
          // reject(err);
      }
    };

    request.send();


  }

  override public function render(){
    return jsx('
      <div>
        COUCOU TOI
      </div>
    ');
  }
}

