package react.map;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

using Lambda;

/**
 *  Externs for react-leaflet 
 *  @doc https://react-leaflet.js.org/docs/en/intro.html
 */
@:jsRequire('react-leaflet', 'Map')  
extern class LeafMap extends ReactComponent {}
@:jsRequire('react-leaflet', 'TileLayer')  
extern class TileLayer extends ReactComponent {}
@:jsRequire('react-leaflet', 'Marker')  
extern class Marker extends ReactComponent {}
@:jsRequire('react-leaflet', 'CircleMarker')  
extern class CircleMarker extends ReactComponent {}
@:jsRequire('react-leaflet', 'Popup')  
extern class Popup extends ReactComponent {}
@:jsRequire('react-leaflet', 'FeatureGroup')  
extern class FeatureGroup extends ReactComponent {}
@:jsRequire('react-leaflet', 'LayerGroup')  
extern class LayerGroup extends ReactComponent {}

@:jsRequire('leaflet')  
extern class L2 {
	static function icon(a:Dynamic):Dynamic;
  static function latLng(lat:Float, lng:Float):Dynamic;
}

/**
 * GroupItem
 * @author rcrestey
 */

typedef GroupMapProps = {
  var addressCoord:Dynamic;
	var groups:Array<GroupOnMap>;
	var fetchGroupsInsideBox:Box->Void;
	var groupFocusedId:Int;
};

typedef GroupMapState = {
  var isFitting:Bool;
  var focusedMarker:Dynamic;
};

typedef Box = {
  var minLat:Float;
  var maxLat:Float;
  var minLng:Float;
  var maxLng:Float;
};

class GroupMap extends ReactComponentOfPropsAndState<GroupMapProps, GroupMapState> {
  static inline var DEFAULT_LAT = 46.52863469527167; // center of France
	static inline var DEFAULT_LNG = 2.43896484375; // center of France
	static inline var INIT_ZOOM = 6;
	static inline var DEFAULT_ZOOM = 13;

  var map:Dynamic;
  var featureGroup:Dynamic;
  var markerMap = new Map<Int,Dynamic>();

  var groupIcon = L2.icon({
    iconUrl: 'https://image.flaticon.com/icons/svg/33/33622.svg',
    iconSize: [40, 40],
    iconAnchor: [20, 40],
    popupAnchor: [0, -30],
    className: 'icon'
  });

  var homeIcon = L2.icon({
    iconUrl: 'https://image.flaticon.com/icons/svg/9/9282.svg',
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -30],
    className: 'icon'
  });

  function new() {
    super();
    state = {
      isFitting: false,
      focusedMarker: null
    };
  }

  function getMap(element:Dynamic):Void {
    map = element.leafletElement;
  }

  function getFeatureGroup(element:Dynamic):Void {
    featureGroup = element.leafletElement;
    setState({
      isFitting: true
    }, fitBounds);
  }

  function getMarker(element:Dynamic, id:Int):Void {
    if (element != null && !markerMap.exists(id))
      markerMap.set(id, element.leafletElement);
  }

  function getGroups() {
    var bounds = map.getBounds();
    var southWest = bounds.getSouthWest();
		var northEast = bounds.getNorthEast();

    props.fetchGroupsInsideBox({
      minLat: southWest.lat,
      maxLat: northEast.lat,
      minLng: southWest.lng,
      maxLng: northEast.lng
    });
  }

  function fitBounds() {  
    map.fitBounds(featureGroup.getBounds(), {
      padding: [10, 10]
    });
  }

  function handleMoveEnd() {
    if (
      props.addressCoord != null &&
      !Lambda.empty(props.groups) &&
      map.distance(map.getCenter(), props.addressCoord) == 0
    )
      setState({
        isFitting: true
      }, fitBounds);
    else if (state.isFitting)
      setState({
        isFitting: false
      });
    else
      getGroups();
  }

  function handleFocusedMarker() {
    
  }

  override public function componentDidMount() {
    if (props.addressCoord == null)
      getGroups();
  }

  override public function shouldComponentUpdate(nextProps:GroupMapProps, nextState:GroupMapState) {
    if (nextState.focusedMarker != state.focusedMarker)
      return false;
    return true;
  }

  override public function componentDidUpdate(prevProps:GroupMapProps, prevState:GroupMapState) {
    if (props.groupFocusedId != null) {
      var focusedMarker = markerMap.get(props.groupFocusedId);
      focusedMarker.openPopup();

      setState({
        focusedMarker: focusedMarker
      });
    }
    else if (state.focusedMarker != null) {
      state.focusedMarker.closePopup();

      setState({
        focusedMarker: null
      });
    }
  }

	override public function render() {
    var center = props.addressCoord == null
      ? L2.latLng(DEFAULT_LAT, DEFAULT_LNG)
      : props.addressCoord;

    var zoom = props.addressCoord == null
      ? INIT_ZOOM
      : DEFAULT_ZOOM;

		return jsx('
      <LeafMap
        center=${center}
        zoom=${zoom}
        ref=${getMap}
        onMoveEnd=${handleMoveEnd}
      >
        <TileLayer
          attribution="&amp;copy <a href=&quot;http://osm.org/copyright&quot;>OpenStreetMap</a> contributors"
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FeatureGroup
          ref=${getFeatureGroup}
        >
          ${renderGroupMarkers()}
          ${renderHomeMarker()}
        </FeatureGroup>
      </LeafMap>
		');
	}
 
	function renderGroupMarkers() {
		var markers = props.groups.map(function(group) {
      var coord = [group.place.latitude, group.place.longitude];

      function markerGetter(e:Dynamic) {
        getMarker(e, group.place.id);
      }

			return jsx('
				<Marker
          position=${coord}
          ref=${markerGetter}
          key=${group.place.id}
          icon=${groupIcon}
        >
					<Popup className="popup">
            <div>
              <span>${group.name}</span>
              <img src=${group.image} width=${50} height=${50}/>
            </div>
					</Popup>
				</Marker>
			');
		});

		return jsx('<div>${markers}</div>');
	}

  function renderHomeMarker() {
    if (props.addressCoord != null)
      return jsx('<Marker position=${props.addressCoord} icon=${homeIcon} />');
    return null;
  }
}
