// Called once per second by the existing player action maintenance loop.
if (!hasInterface) exitWith {};
disableSerialization;
private _oldUnit = missionNamespace getVariable ["BW_PING_ACTION_UNIT", objNull];
private _ids = missionNamespace getVariable ["BW_PING_ACTION_IDS", []];
if (!(_oldUnit isEqualTo player) || {count _ids != 4} ||
    {(_ids findIf {!(_x in (actionIDs player))}) >= 0}) then {
    if (!isNull _oldUnit) then {{_oldUnit removeAction _x} forEach _ids};
    _ids = [];
    if (!isNull player) then {
        {
            _ids pushBack (player addAction [format [localize "STR_BW_PING_ACTION", localize _x], {
                params ["_target", "_caller", "_id", "_kind"];
                if (diag_tickTime < (missionNamespace getVariable ["BW_PING_LOCAL_NEXT", 0])) exitWith {
                    hint localize "STR_BW_PING_WAIT";
                };
                private _pos = screenToWorld [0.5, 0.5];
                if (_caller distance2D _pos > 1000) exitWith {hint localize "STR_BW_PING_RANGE"};
                BW_PING_LOCAL_NEXT = diag_tickTime + 5;
                [_caller, _kind, _pos] remoteExecCall ["bulwark_fnc_requestPing", 2];
            }, _forEachIndex, 0.5, false, true, "",
            "_target == _this && alive _this && lifeState _this != 'INCAPACITATED' && side group _this == west", 0]);
        } forEach ["STR_BW_THREAT", "STR_BW_SUPPLY", "STR_BW_REPAIR", "STR_BW_REGROUP"];
    };
    BW_PING_ACTION_UNIT = player;
    BW_PING_ACTION_IDS = _ids;
};
private _pings = (missionNamespace getVariable ["BW_TACTICAL_PINGS", []]) select {
    side group player == west && {serverTime < (_x select 5)} && {alive (_x select 1)} && {isPlayer (_x select 1)}
};
if !(_pings isEqualTo (missionNamespace getVariable ["BW_LOCAL_PINGS", []])) then {
    {deleteMarkerLocal _x} forEach (missionNamespace getVariable ["BW_LOCAL_PING_MARKERS", []]);
    private _markers = [];
    {
        _x params ["_uid", "_author", "_kind", "_pos", "_name", "_expiry"];
        private _marker = createMarkerLocal [format ["BW_Ping_%1", _uid], _pos];
        _marker setMarkerTypeLocal "mil_dot";
        _marker setMarkerColorLocal (["ColorRed", "ColorGreen", "ColorOrange", "ColorBlue"] select _kind);
        _marker setMarkerTextLocal format ["%1: %2", localize (["STR_BW_THREAT", "STR_BW_SUPPLY", "STR_BW_REPAIR", "STR_BW_REGROUP"] select _kind), _name];
        _markers pushBack _marker;
    } forEach _pings;
    BW_LOCAL_PING_MARKERS = _markers;
    BW_LOCAL_PINGS = _pings;
};
private _status = missionNamespace getVariable ["BW_TEAM_STATUS", []];
// F15 shows the landing zone while inbound, then the landed stock countdown.
private _hudSupplies = [];
{
    _x params ["_snapshotKey", "_markerKey", "_warnKey", "_label", "_color", "_deliveryKey", "_inboundLabel", "_descendingLabel"];
    private _supply = missionNamespace getVariable [_snapshotKey, []];
    private _delivery = missionNamespace getVariable [_deliveryKey, []];
    private _available = count _supply == 5 && {side group player == west} &&
        {alive (_supply select 1)} && {serverTime < (_supply select 3)};
    private _incoming = count _delivery == 5 && {side group player == west} &&
        {!(missionNamespace getVariable ["buildPhase", true])} &&
        {(_delivery select 2) == (missionNamespace getVariable ["attkWave", -1])} &&
        {serverTime < (_delivery select 3)} && {(_delivery select 4) in ["inbound", "descending"]} &&
        {!((_status param [1, "Ended"]) in ["Extraction", "Ended"])};
    private _marker = missionNamespace getVariable [_markerKey, ""];
    private _seconds = if (_available) then {ceil ((_supply select 3) - serverTime)} else {-1};
    if (_available || {_incoming}) then {
        private _id = if (_available) then {_supply select 0} else {_delivery select 0};
        private _position = if (_available) then {_supply select 2} else {_delivery select 1};
        private _name = format ["BW_Supply_%1", _id];
        if (_marker != _name || {markerShape _name == ""}) then {
            if (_marker != "") then {deleteMarkerLocal _marker};
            createMarkerLocal [_name, _position];
            _name setMarkerTypeLocal "mil_box";
            _name setMarkerColorLocal _color;
            missionNamespace setVariable [_markerKey, _name];
        };
        _name setMarkerPosLocal _position;
        private _text = if (_available) then {format [localize _label, _seconds]} else {
            localize (if ((_delivery select 4) == "descending") then {_descendingLabel} else {_inboundLabel})
        };
        _name setMarkerTextLocal _text;
        if (_available && {player distance2D _position < 5} &&
            {(missionNamespace getVariable [_warnKey, -1]) != _id}) then {
            hint localize "STR_BW_SUPPLY_TEMPORARY";
            missionNamespace setVariable [_warnKey, _id];
        };
    } else {
        if (_marker != "") then {deleteMarkerLocal _marker; missionNamespace setVariable [_markerKey, ""]};
    };
    _hudSupplies pushBack [_supply, _seconds, _delivery, _incoming];
} forEach [
    ["BW_SUPPLY_STATUS", "BW_LOCAL_SUPPLY_MARKER", "BW_SUPPLY_WARNED", "STR_BW_MEDICAL_CACHE", "ColorGreen", "BW_SUPPLY_DELIVERY_STATUS", "STR_BW_MEDICAL_INBOUND", "STR_BW_MEDICAL_DESCENDING"],
    ["BW_ENGINEERING_STATUS", "BW_LOCAL_ENGINEERING_MARKER", "BW_ENGINEERING_WARNED", "STR_BW_ENGINEERING_CACHE", "ColorOrange", "BW_ENGINEERING_DELIVERY_STATUS", "STR_BW_ENGINEERING_INBOUND", "STR_BW_ENGINEERING_DESCENDING"]
];
private _officer = missionNamespace getVariable ["BW_OFFICER_STATUS", []];
private _officerVisible = count _officer == 5 && {side group player == west} &&
    {! (missionNamespace getVariable ["buildPhase", true])} &&
    {(_officer select 1) == (missionNamespace getVariable ["attkWave", -1])} && {serverTime < (_officer select 4)} &&
    {!((_status param [1, "Ended"]) in ["Extraction", "Ended"])};
private _officerMarker = missionNamespace getVariable ["BW_LOCAL_OFFICER_MARKER", ""];
private _officerSeconds = if (_officerVisible) then {ceil ((_officer select 4) - serverTime)} else {-1};
if (_officerVisible) then {
    private _name = format ["BW_Officer_%1", _officer select 0];
    if (_officerMarker != _name || {markerShape _name == ""}) then {
        if (_officerMarker != "") then {deleteMarkerLocal _officerMarker};
        createMarkerLocal [_name, _officer select 2];
        _name setMarkerShapeLocal "ELLIPSE";
        _name setMarkerBrushLocal "Border";
        _name setMarkerColorLocal "ColorRed";
        _name setMarkerSizeLocal [_officer select 3, _officer select 3];
        _name setMarkerTextLocal localize "STR_BW_OFFICER_SEARCH";
        BW_LOCAL_OFFICER_MARKER = _name;
    };
} else {
    if (_officerMarker != "") then {deleteMarkerLocal _officerMarker; BW_LOCAL_OFFICER_MARKER = ""};
};
private _fpv = [] call bulwark_fnc_fpvClient;
private _hudState = [_status, player, player getVariable ["killPoints", 0], _hudSupplies, _officer, _officerSeconds, _fpv];
if (!(_hudState isEqualTo (missionNamespace getVariable ["BW_LAST_TEAM_HUD", []])) ||
    {isNull (uiNamespace getVariable ["KillPointsHud", displayNull])}) then {
    [] call killPoints_fnc_updateHud;
    BW_LAST_TEAM_HUD = _hudState;
};
