package react.map;
import js.Promise;
import react.ReactComponent;
import react.ReactMacro.jsx;
import utils.HttpUtil;
import Common;


using Lambda;

@:jsRequire('react-places-autocomplete', 'default')  
extern class Autocomplete extends ReactComponent {}

@:jsRequire('react-places-autocomplete')
extern class GeoUtil {
	static function geocodeByAddress(address:Dynamic):Promise<Dynamic>;
}

// @:jsRequire('leaflet', 'LatLng')
// extern class LatLng {}

@:jsRequire('leaflet')  
extern class L {
  static function latLng(lat:Float, lng:Float):Dynamic;
	static function icon(a:Dynamic):Dynamic;
}

@:jsRequire('geolib')  
extern class Geolib {
  static function getDistance(start:Dynamic, end:Dynamic):Float;
}

/**
 * Groups Map
 * @author rcrestey
 */

typedef GroupMapRootState = {
	var point:Dynamic;
	var address:String;
	var groups:Array<GroupOnMap>;
	var groupFocusedId:Int;
	var isInit:Bool;
};

typedef GroupMapRootProps = {
	var lat:Float;
	var lng:Float;
	var address:String;
};

class GroupMapRoot extends ReactComponentOfState<GroupMapRootState>{

	static inline var GROUP_MAP_URL = '/api/group/map';

	var distanceMap = new Map<Int,Dynamic>();

	public function new(props) 
	{
		super(props);

		state = { 
			point: L.latLng(props.lat, props.lng),
			address: props.address,
			groups: [],
			groupFocusedId: null,
			isInit: false
		};
	}

	function onChange(address) {
		setState({
			address: address
		});
	}

	function openPopup(group:Dynamic) {
		setState({
			groupFocusedId: group.place.id
		});
	}

	function closePopup() {
		setState({
			groupFocusedId: null
		});
	}

	function geocodeByAddress(address:String):Promise<Dynamic> {
		return GeoUtil.geocodeByAddress(address)
		.then(function(results) {
			var lat = results[0].geometry.location.lat();
			var lng = results[0].geometry.location.lng();

			return {lat: lat, lng: lng};
		});
	}

	function fetchGroups(lat:Float, lng:Float) {
		HttpUtil.fetch(GROUP_MAP_URL, GET, {lat: lat, lng: lng}, JSON)
		.then(function(results) {
			setState({
				point: L.latLng(lat, lng),
				groups: results.groups,
				isInit: true
			}, fillDistanceMap);
		})
		.catchError(function(error) {
			trace('Error', error);
		});
	}

	function fetchGroupsInsideBox(newBox) {
		HttpUtil.fetch(GROUP_MAP_URL, GET, newBox, JSON)
		.then(function(results) {
			setState({
				groups: results.groups
			}, fillDistanceMap);
		})
		.catchError(function(error) {
			trace('Error', error);
		});
  }

	function getGroupDistance(group:GroupOnMap):Float {
		if (state.point == null)
			return null;
		
		var start = {
			latitude: state.point.lat,
			longitude: state.point.lng
		};
		var end = {
			latitude: group.place.latitude,
			longitude: group.place.longitude
		};

		return Geolib.getDistance(start, end);
	}

	function fillDistanceMap() {
		for (group in state.groups) {
			distanceMap.set(group.place.id, getGroupDistance(group));
		}
		forceUpdate();
	}

	function orderGroupsByDistance(groups:Array<GroupOnMap>) {
		groups.sort(function(a, b) {
			return distanceMap.get(a.place.id) - distanceMap.get(b.place.id);
		});
	}

	function convertDistance(distance:Int):String { // to test
		if (distance > 10000)
			return Math.floor(distance / 1000) + ' km';
		if (distance > 1000)
			return Math.floor(distance / 100) / 10 + ' km';
		return distance + ' m';
	}

  function handleSelect(address:String) {
		setState({
			address: address
		});

		geocodeByAddress(address)
		.then(function(coord) {
			fetchGroups(coord.lat, coord.lng);
		})
		.catchError(function(error) {
			trace('Error', error);
		});
  }

	override public function componentDidMount() {
		if (state.point != null)
			fetchGroups(state.point.lat, state.point.lng);
		else if (state.address != '')
			handleSelect(state.address);
	}

	function renderSuggestion(obj:Dynamic) {
		return jsx('
      <div className="autocomplete-item">
        <i className="fa fa-map-marker autocomplete-icon" />
        <strong>${obj.formattedSuggestion.mainText}</strong>&nbsp;
        <small className="text-muted">${obj.formattedSuggestion.secondaryText}</small>
      </div>
    ');
	}

	override public function render() {
		var inputProps = {
			value: state.address,
			onChange: onChange
		};

		var cssClasses = {
      root: 'form-group',
      input: 'autocomplete-input',
      autocompleteContainer: 'autocomplete-results',
    };

		orderGroupsByDistance(state.groups);

		return jsx('
			<div className="group-map">
      	<Autocomplete
					inputProps=${inputProps}
					onSelect=${handleSelect}
					classNames=${cssClasses}
					renderSuggestion=${renderSuggestion}
				/>
				${renderGroupList()}
				${renderGroupMap()}
      </div>
		');
	}

	function renderGroupMap() {
		if (!state.isInit)
			return null;
		
		return jsx('
			<GroupMap
				addressCoord=${state.point}
				groups=${state.groups}
				fetchGroupsInsideBox=${fetchGroupsInsideBox}
				groupFocusedId=${state.groupFocusedId}
			/>
		');
	}

	function renderGroupList() {
		var groups = state.groups.map(function(group) {
			return renderGroup(group);
		});

		return jsx('
			<div className="groups">
				${groups}
			</div>
		');
	}

	function renderGroup(group) {
		var address = [
      group.place.address1,
      group.place.address2,
      [group.place.zipCode, group.place.city].join(" "),
    ];
		var addressBlock = Lambda.array(address.mapi(function(index, element) {
      if (element != null)
      	return jsx('<div className="address" key=${index}>$element</div>');
			
			return null;
    }));

		var distance = null;
		if (distanceMap.get(group.place.id) != null)
			distance = jsx('<div>${convertDistance(distanceMap.get(group.place.id))}</div>');

		var classNames = ['group'];
		if (group.place.id == state.groupFocusedId)
			classNames.push('focused');

		return jsx('
			<a
				target=""
				onMouseEnter=${function() { openPopup(group); }}
				onMouseLeave=${closePopup}
				className=${classNames.join(' ')}
				key=${group.place.id}
			>
				<h2>${group.name}</h2>
				${addressBlock}
				${distance}
			</a>
		');
	}
}
