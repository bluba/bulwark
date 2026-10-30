diag_log "LOC GEN SPECIFIC";
List_SpecificPoint = [getMarkerPos "specBulwarkLoc"];
deleteMarker "specBulwarkLoc";
diag_log List_SpecificPoint;

diag_log "LOC GEN MARKERS";
diag_log allMapMarkers;
_zoneMarkers = [];
{
    _currMarker = toArray _x;
    if(count _currMarker >= 4) then {
        _currMarker resize 11;
        _currMarker = toString _currMarker;
        if(_currMarker == "bulwarkzone") then{
            _zoneMarkers append [getMarkerPos _x];
            deleteMarker _x;
        };
    };
} foreach allMapMarkers;
diag_log _zoneMarkers;
List_LocationMarkers =_zoneMarkers;

diag_log "LOC GEN DEFAULT";
_allLocations = [];
{
    _allLocations append [locationPosition _x];
} forEach nearestLocations [[0,0,0], ["NameCity", "NameCityCapital", "Airport","NameLocal"], 40000];
diag_log _allLocations;
List_AllCities = _allLocations;
