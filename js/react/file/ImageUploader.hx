package react.file;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.ReactRef;

import mui.core.Button;

import haxe.Json;
import js.Promise;
import js.html.XMLHttpRequest;

@:jsRequire('react-dropzone', 'Dropzone')  
extern class DropZone extends ReactComponent {}

@:jsRequire('react-avatar-editor', 'AvatarEditor')  
extern class AvatarEditor extends ReactComponent {

    public function getImageScaledToCanvas() : js.html.CanvasElement;
    public function getCroppingRect() : { x : Float, y : Float, width : Float, height : Float };
}

  
typedef ImageUploaderProps = {

  var uploadURL : String;
  // var uploadField : String;
  // var uploadResponseField : String;
  var uploadCallback : String -> Void;
};

typedef ImageUploaderState = {

	var image : js.html.File;
  var position : { x : Float, y : Float };
  var scale : Float;
  var rotate : Int;
  var preview : { img : Dynamic, rect : { x : Float, y : Float, width : Float, height : Float },  scale : Float, width : Int, height : Int, borderRadius : Float };
  var width : Int;
  var height : Int;
  var uploading : Bool;
  var uploadProgress : { state : String, percentage : Float };
  var successfullUploaded : Bool;
};

class ImageUploader extends ReactComponentOfPropsAndState<ImageUploaderProps, ImageUploaderState> {

  var avatarEditorRef : react.ReactRef<AvatarEditor>;

  public function new( props : ImageUploaderProps ) {

    super(props);
    state = { image : null, position : { x: 0.5, y: 0.5 }, scale : 1, rotate : 0, preview : null, width : 400, height : 200,
    uploading : false, uploadProgress : { state : "notstarted", percentage : 0}, successfullUploaded : false };
    avatarEditorRef  = React.createRef();
  }
 
  function updateImage( e : js.html.Event ) {

    e.preventDefault();		

		var newImage : js.html.File = untyped ( e.target.files[0] );
		setState( { image : newImage } );	
  }

  function updatePreview( e : js.html.Event ) {

    e.preventDefault();		

    var image = avatarEditorRef.current.getImageScaledToCanvas().toDataURL();
    var rect = avatarEditorRef.current.getCroppingRect();

    setState( { preview : { img : image, rect : rect, scale : state.scale, width: state.width, height: state.height, borderRadius: 0 } } );
  }

  function updateScale( e : js.html.Event ) {

    e.preventDefault();		
   
    var scale : Float = untyped (e.target.value == "") ? null : e.target.value;
    setState( { scale : scale } );
  }  

  function rotateLeft( e : js.html.Event ) {
    
    e.preventDefault();		

    // Hack: Swap width and height on +/- 90° rotation, because of bug in react-avatar-editor (rotation rotates canvas and image, instead of image only)
    setState( { rotate : state.rotate - 90, width : state.height, height : state.width } );
  }

  function rotateRight( e : js.html.Event ) {
    
    e.preventDefault();		

    // Hack: Swap width and height on +/- 90° rotation, because of bug in react-avatar-editor (rotation rotates canvas and image, instead of image only)
    setState( { rotate : state.rotate + 90, width : state.height, height : state.width } );
  }

  function logCallback( e : String ) {
    
    trace("****CALLBACK*****");
    trace(e);
  }

  function updatePosition( e : js.html.Event, position : { x : Float, y : Float } ) {

    e.preventDefault();

    setState( { position : position } );
  }

  function handleDrop( acceptedFiles : Array<js.html.File> ) {

    setState( { image : acceptedFiles[0] } );
  }  

  function uploadImage() {

    setState( { uploading: true } );
    var image = avatarEditorRef.current.getImageScaledToCanvas().toDataURL();

    var promises = [];
		promises.push( sendRequest(image) );

    var initRequest = js.Promise.all(promises).then(

				function(data:Dynamic) {

          trace("Successfull upload");
          setState( { successfullUploaded : true, uploading : false } );
			  }
			).catchError (
				function(error) {
					trace("Error while uploading:", error);
          setState( { successfullUploaded: false, uploading: false } );
          throw error;
				}
			);

  }

  function sendRequest( image : Dynamic ) {

    return new Promise( function( resolve : Dynamic -> Void, reject ) {

      var request = new XMLHttpRequest();
      request.responseType = js.html.XMLHttpRequestResponseType.JSON;

      request.upload.addEventListener("progress", function(event) {

        if ( event.lengthComputable ) {

          setState({ uploadProgress: { state : "pending", percentage : ( event.loaded / event.total ) * 100 } });
        }
      });

      request.upload.addEventListener("load", function(event) {
          
        setState({ uploadProgress: { state: "done", percentage: 100 } });
      });     

      request.upload.addEventListener("error", function(event) {
          
        setState( { uploadProgress : { state: "error", percentage: 0 } } );
        reject( request.responseText );
      });

      request.onreadystatechange = function () {
      
        if (request.readyState == 4) {

          switch (request.status) {

            case 200:
              if ( request.responseType != js.html.XMLHttpRequestResponseType.JSON ) {

                trace( "Wrong response type" );
                reject( request.responseText );
              }
              if ( request.response ) {

                // && state.uploadResponseField in request.response  A RAJOUTER

                trace( "received response:", request.responseText );
               
                var json = Json.parse(request.responseText);
                resolve( json );
                trace(json);
                //if ( Reflect.hasField(json, props.uploadResponseField) ) {
                  //A RAJOUTER
                  // props.uploadCallback( json[props.uploadResponseField] );
                //}                
              }
              else {
                
                trace( "Wrong response content" );
                reject( request.responseText );
              }

              case 204:
							  resolve(true);

						  default:
                trace( "Wrong response status" );
						  	reject( request.responseText );
          }
        }
      }

      var data = new js.html.FormData();
       // If we had a real file, we could use `file.name` as third argument
      data.append("file", image);
      request.open("POST", props.uploadURL);
      request.send(data);
    });
  }

  override public function render() {

    return jsx('
      <div className="image-import-edit-upload-component">
        <DropZone className="dropzone" onDrop=$handleDrop multiple={false} style=${{ width: state.width + 50, height: state.height + 50 }} >
          ${ state.image != null ? jsx('
            <div>
              <AvatarEditor ref=$avatarEditorRef scale=${state.scale} width=${state.width} height=${state.height}
              position=${state.position} onPositionChange=$updatePosition rotate=${state.rotate} borderRadius="0"
              onLoadFailure=${logCallback.bind('onLoadFailed')} onLoadSuccess=${logCallback.bind('onLoadSuccess')}
              onImageReady=${logCallback.bind('onImageReady')} image=${state.image} className="editor-canvas" />
            </div>
          ') : jsx('
            <label htmlFor="newImage" className="field-label">
              <div className="dropzone--empty">Déposez une image ici ou cliquez sur Parcourir</div>
            </label>')}          
        </DropZone>
        <br/>
        <label htmlFor="newImage">
          <Button variant={Contained} component="span">Parcourir</Button>
        </label>
        <br/>
        <input id="newImage" name="newImage" type="file" onChange=$updateImage className="input--file" />

        ${ state.image != null ? jsx('
          <div>
            Zoom           
            <input name="scale" type="range" onChange=$updateScale min="0.1" max="2" step="0.01" defaultValue="1" />
            <div style=${{ display: "inline-block", width: "4em", verticalAlign: "top" }}>
              ${ state.scale * 100 } %
            </div>
            <br/>
            <Button variant={Contained} onClick=$rotateLeft className="rotate-left-button">↶</Button>
            <Button variant={Contained} onClick=$rotateRight className="rotate-right-button">↷</Button>
            <br/>
            <br/>
            <Button variant={Contained} onClick=$updatePreview className="preview-button">Preview</Button>
            <Button variant={Contained} color={Primary} onClick=$uploadImage className="upload-button">Upload</Button>
            <br/>
          </div>') : null }
          
          ${ state.preview != null ? jsx('
          <img src=${state.preview.img} style=${{ borderRadius: (Math.min( state.preview.height, state.preview.width ) + 10 ) + "px" }} alt="preview" />
        ') : null }
       
      </div>');
  }

}