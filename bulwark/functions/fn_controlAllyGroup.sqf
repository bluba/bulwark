// Owner-local controller. 75 m is a horizontal recall boundary, not a teleport wall.
params ["_group", "_asset", "_truck"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _group || {!local _group} || {side _group != west} ||
    {!(_group getVariable ["bw_allyManaged", false])} || {!alive _truck}) exitWith {};
private _allowed = {
    (units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
        {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}}) < 0
};
if !(call _allowed) exitWith {};
private _units = units _group select {alive _x};
if (_units isEqualTo []) exitWith {};
_group setVariable ["bw_allyLease", diag_tickTime + 8];
private _newOwner = (_group getVariable ["bw_allyMachine", -1]) != clientOwner;
if (_newOwner) then {
    _group setVariable ["bw_allyMachine", clientOwner];
    _group setVariable ["bw_allyMode", ""];
    // Stop our overrides on expiry/ownership change, without resetting player orders.
    [_group] spawn {
        params ["_group"];
        waitUntil {
            sleep 1;
            isNull _group || {!local _group} || {!(_group getVariable ["bw_allyManaged", false])} ||
            {diag_tickTime > (_group getVariable ["bw_allyLease", 0])} ||
            {(units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
                {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}}) >= 0}
        };
        if (!isNull _group && {local _group}) then {
            private _safe = (units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
                {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}}) < 0;
            if (_safe) then {[_group, true, true] call lambs_wp_fnc_taskReset};
            {if (!isPlayer _x && {isNull (remoteControlled _x)}) then {
                _x enableAI "AUTOCOMBAT";
                _x setVariable ["lambs_danger_disableAI", nil, true];
            }} forEach units _group;
            _group setVariable ["bw_allyMachine", -1];
            _group setVariable ["bw_allyMode", "", true];
        };
        // Clear this machine's latch even after transfer, so returning ownership
        // starts a fresh watchdog rather than reusing an expired local session.
        if (!isNull _group) then {_group setVariable ["bw_allyMachine", -1]};
    };
};

private _type = _group getVariable ["bw_allyType", "infantry"];
private _center = getPosATL _truck;
private _lastTruck = _group getVariable ["bw_allyTruckPos", _center];
private _moving = abs speed _truck > 1 || {_center distance2D _lastTruck > 1};
if (_moving) then {_group setVariable ["bw_allyMovingUntil", diag_tickTime + 6]};
_group setVariable ["bw_allyTruckPos", _center];
_moving = _moving || {diag_tickTime < (_group getVariable ["bw_allyMovingUntil", 0])};
private _oldMode = _group getVariable ["bw_allyMode", ""];
private _outside = (_units findIf {_x distance2D _truck > 75}) >= 0;
private _regrouping = _oldMode == "follow" && {(_units findIf {_x distance2D _truck > 45}) >= 0};
private _mode = if (_moving || {_outside} || {_regrouping}) then {"follow"} else {_group getVariable ["bw_allyDuty", "patrol"]};
if (_type == "vehicle") then {if (_mode != "follow") then {_mode = "sentry"}};
if (_type == "static") then {_mode = "static"};
if (!isNull _asset && {_asset getVariable ["buildItemHeld", false] || {!isNull attachedTo _asset}}) then {_mode = "held"};

private _oldCenter = _group getVariable ["bw_allyDutyCenter", _center];
private _changed = _newOwner || {_mode != _oldMode} ||
    {_mode in ["patrol", "camp", "sentry"] && {_center distance2D _oldCenter > 10}};
if (_changed) then {
    [_group, true, true] call lambs_wp_fnc_taskReset;
    {_x enableAI "AUTOCOMBAT"; _x setVariable ["lambs_danger_disableAI", nil, true]} forEach _units;
    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setVariable ["bw_allyMode", _mode, true];
    _group setVariable ["bw_allyDutyCenter", _center];
    _group setVariable ["bw_allyMoveTarget", [0, 0, 0]];
    switch (_mode) do {
        case "held": {{_x disableAI "PATH"} forEach _units};
        case "patrol": {
            // Inner radius leaves room for waypoint tolerance and brief truck drift.
            [_group, _center, 50, 4, [], false, false, false] call lambs_wp_fnc_taskPatrol;
        };
        case "camp": {
            // A cancellable guard position: no delayed camp callbacks or split groups.
            private _position = _center getPos [20, random 360];
            if (surfaceIsWater _position) then {_position = _center};
            private _wp = _group addWaypoint [_position, 0];
            _wp setWaypointType "HOLD";
            _group setSpeedMode "NORMAL";
        };
        case "sentry";
        case "static": {
            private _wp = _group addWaypoint [getPosATL (leader _group), 0];
            _wp setWaypointType "HOLD";
        };
    };
};
if (_mode == "follow") then {
    // Recall overrides combat movement while retaining target/weapon AI.
    {_x enableAI "PATH"; _x disableAI "AUTOCOMBAT";
        _x setVariable ["lambs_danger_disableAI", true, true]} forEach _units;
    _group setSpeedMode "FULL";
    private _target = _center getPos [20, (getDir _truck) + 180];
    if (surfaceIsWater _target) then {_target = _center};
    private _oldTarget = _group getVariable ["bw_allyMoveTarget", [0, 0, 0]];
    if (_changed || {_target distance2D _oldTarget > 8} || {unitReady leader _group}) then {
        while {count waypoints _group > 0} do {deleteWaypoint ((waypoints _group) select 0)};
        private _wp = _group addWaypoint [_target, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 10;
        {_x doFollow (leader _group)} forEach (_units - [leader _group]);
        (leader _group) doMove _target;
        _group setVariable ["bw_allyMoveTarget", _target];
        if (_type == "vehicle" && {_asset isKindOf "Air"}) then {_asset flyInHeight 35};
    };
};
