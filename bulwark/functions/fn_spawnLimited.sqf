/* Server scheduled spawn gateway. Reservations prevent simultaneous producers oversubscribing. */
params ["_args", "_kind", "_wave", ["_ordinary", false], ["_guard", objNull], ["_deadline", -1]];
private _empty = switch (_kind) do {case "group": {grpNull}; case "unit": {objNull}; default {[objNull, [], grpNull]}};
if (!isServer || {!canSuspend} || {!([_wave] call bulwark_fnc_waveActive)} ||
    {!(_deadline isEqualType 0)} || {!finite _deadline} || {_deadline != -1 && {_deadline < 0}} ||
    {_deadline >= 0 && {time >= _deadline}}) exitWith {_empty};
private _arrival = "";
if (_kind == "vehicle" && {missionNamespace getVariable ["BW_VEHICLE_TICKETS_ACTIVE",true]}) then {
 private _class = _args select 2;
 if (_class isKindOf "Air" && {getNumber (configFile >> "CfgVehicles" >> _class >> "isUav") == 0}) then {_arrival = "air"};
 if (_class in ["RHS_Ural_Open_MSV_01","B_Truck_01_transport_F","O_Truck_03_transport_F"]) then {_arrival = "groundDelivery"};
 if (_arrival != "" && {_deadline < 0}) then {_deadline = time + 180};
};
private _needed = 1;
if (_kind == "group") then {_needed = count (_args select 2)};
if (_kind == "vehicle") then {
    private _cfg = configFile >> "CfgVehicles" >> (_args select 2);
    // Count all potentially occupied turrets conservatively, including nested turrets.
    private _turretCount = {
        params ["_cfg"];
        private _n = 0;
        {if (getNumber (_x >> "dontCreateAI") == 0) then {_n = _n + 1}; _n = _n + ([_x >> "Turrets"] call _turretCount)} forEach ("true" configClasses _cfg);
        _n
    };
    _needed = (getNumber (_cfg >> "hasDriver")) + ([_cfg >> "Turrets"] call _turretCount);
    _needed = _needed max 1;
};
private _limit = if (_ordinary) then {floor (BW_ENEMY_LIMIT * 0.8)} else {BW_ENEMY_LIMIT};
if (_needed > _limit) exitWith {diag_log format ["Bulwark: spawn request %1 exceeds capacity %2", _needed, _limit]; _empty};
private _guarded = !isNull _guard;
if (_guarded) then {isNil {_guard setVariable ["bw_capacityWaiting", (_guard getVariable ["bw_capacityWaiting", 0]) + 1, true]}};
private _ticket = [];
isNil {BW_SPAWN_SERIAL = BW_SPAWN_SERIAL + 1; _ticket = [BW_SPAWN_SERIAL, _wave, _needed, false, _thisScript, _arrival]; BW_SPAWN_QUEUE pushBack _ticket};
private _granted = false;
waitUntil {
    if (!([_wave] call bulwark_fnc_waveActive) || {_guarded && {!alive _guard}} || {_deadline >= 0 && {time >= _deadline}}) exitWith {true};
    isNil {
        private _active = {alive _x && {side group _x in [east, resistance]}} count allUnits;
        private _reserved = 0;
        {if ((_x select 1) == _wave && {_x select 3}) then {_reserved = _reserved + (_x select 2)}} forEach BW_SPAWN_QUEUE;
        private _arrivalFree = true;
        if (_arrival != "") then {
            _arrivalFree = (vehicles findIf {alive _x && {_x getVariable ["bw_arrivalChannel",""] == _arrival} && {(_x getVariable ["bw_hostileWave",-1]) == _wave} && {({alive _x} count crew _x) > 0}}) < 0 &&
                {(BW_SPAWN_QUEUE findIf {(_x select 1) == _wave && {(_x select 0) < (_ticket select 0)} && {(_x param [5,""]) == _arrival}}) < 0};
        };
        if (_arrivalFree && {_active + _reserved + _needed <= _limit}) then {_ticket set [3, true]; _granted = true};
    };
    if (!_granted) then {sleep 5};
    _granted
};
private _result = _empty;
if (_granted && {[_wave] call bulwark_fnc_waveActive} && {!_guarded || {alive _guard}} && {_deadline < 0 || {time < _deadline}}) then {
    _result = switch (_kind) do {
        case "group": {_args call BIS_fnc_spawnGroup};
        case "unit": {(_args select 0) createUnit (_args select 1)};
        default {_args call BIS_fnc_spawnVehicle};
    };
};
// Engine helpers may yield while creating a group. Recheck before exposing the
// result, including wave cancellation and deletion of a once-valid guard.
isNil {
    if (!([_wave] call bulwark_fnc_waveActive) || {_guarded && {!alive _guard}} || {_deadline >= 0 && {time >= _deadline}}) then {
        switch (_kind) do {
            case "group": {{deleteVehicle _x} forEach units _result; deleteGroup _result};
            case "unit": {deleteVehicle _result};
            default {
                _result params ["_vehicle", "_crew", "_group"];
                {deleteVehicle _x} forEach _crew;
                deleteVehicle _vehicle;
                deleteGroup _group;
            };
        };
        _result = _empty;
    };
    if (_kind == "group" && {_guarded} && {!isNull _result}) then {_result setVariable ["bw_scriptedMovement", true, true]};
    if (_kind == "vehicle" && {!isNull (_result select 0)}) then {(_result select 0) setVariable ["bw_hostileWave", _wave]; (_result select 0) setVariable ["bw_arrivalChannel",_arrival]};
    if (_guarded && {!isNull _guard}) then {_guard setVariable ["bw_capacityWaiting", 0 max ((_guard getVariable ["bw_capacityWaiting", 0]) - 1), true]};
    BW_SPAWN_QUEUE = BW_SPAWN_QUEUE select {(_x select 0) != (_ticket select 0) || {(_x select 1) != _wave}};
};
_result
