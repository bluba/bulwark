if (!isServer) exitWith {};
waitUntil {sleep 1; (attkWave > 4) || {!(missionNamespace getVariable ["runMissionLoop", true])}};
if (!(missionNamespace getVariable ["runMissionLoop", true])) exitWith {};
private _location = [getPosATL bulwarkBox, 5000, 5500, 10, 0] call BIS_fnc_findSafePos;
private _roads = _location nearRoads 500;
if !(_roads isEqualTo []) then {
    _roads = [_roads, [], {_location distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;
    _location = getPosATL (_roads select 0);
};
createMarker ["Extract Area", _location];
"Extract Area" setMarkerShape "ELLIPSE";
"Extract Area" setMarkerSize [100, 100];
"Extract Area" setMarkerColor "ColorBlue";
["TaskAssigned", ["Extraction", "Bring every surviving player into the blue extraction zone."]] remoteExec ["BIS_fnc_showNotification", 0];
while {missionNamespace getVariable ["runMissionLoop", true]} do {
    // Recalculate the full roster on every poll, never accumulate visits.
    if ([_location] call bulwark_fnc_extractionReady) exitWith {missionExtract = true};
    sleep 1;
};
