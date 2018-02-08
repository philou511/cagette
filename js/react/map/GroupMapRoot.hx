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
	var groupFocusedId:String;
};

class GroupMapRoot extends ReactComponentOfState<GroupMapRootState>{

	static inline var GROUP_MAP_URL = '/api/group/map';

	var distanceMap = new Map<Int,Dynamic>();

	public function new(props) 
	{
		super(props);

		state = { 
			point: null,
			address: '',
			// address: '165 rue du Tondu, Bordeaux, France',
			groups: [],
			groupFocusedId: null
		};
	}

	function onChange(address) {
		setState({
			address: address
		});
	}

	function openPopup(group:Dynamic) {
		setState({
			groupFocusedId: [group.place.latitude, group.place.longitude].join('')
		});
	}

	function closePopup() {
		setState({
			groupFocusedId: null
		});
	}

	function geocodeByAddress(address:String):Promise<Dynamic> {
		return GeoUtil.geocodeByAddress(state.address)
		.then(function(results) {
			var lat = results[0].geometry.location.lat();
			var lng = results[0].geometry.location.lng();

			return {lat: lat, lng: lng};
		});
	}

	function fetchGroups(lat:Float, lng:Float):Promise<Dynamic> {
		return HttpUtil.fetch(GROUP_MAP_URL, GET, {lat: lat, lng: lng}, JSON);
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

	function orderGroupsByDistance() {
		state.groups.sort(function(a, b) {
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
			return fetchGroups(coord.lat, coord.lng)
			.then(function(results) {
				var groups:Array<Dynamic> = results.groups;

				setState({
					point: L.latLng(coord.lat, coord.lng),
					groups: results.groups
				}, fillDistanceMap);
			});
		})
		.catchError(function(error) {
			trace('Error', error);
		});
  }

	override public function componentDidMount() {
		if (state.address != '') {
			handleSelect(state.address);
		}
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

		return jsx('
			<div className="group-map">
      	<Autocomplete
					inputProps=${inputProps}
					onSelect=${handleSelect}
					classNames=${cssClasses}
				/>
				${renderGroupList()}
				${renderGroupMap()}
      </div>
		');
	}

	function renderGroupMap() {
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

		return jsx('
			<div
				onMouseEnter=${function() { openPopup(group); }}
				onMouseLeave=${closePopup}
				className="group"
				key=${group.place.id}
			>
				<h2>${group.name}</h2>
				${addressBlock}
				<div>${convertDistance(distanceMap.get(group.place.id))}</div>
			</div>
		');
	}
}
