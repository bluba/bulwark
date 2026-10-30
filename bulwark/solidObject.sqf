// One server controller per placed object, including repeated pickup/drop cycles.
if (!isServer) exitWith {};
params ["_object"];
if (isNull _object) exitWith {};
private _claimed = false;
isNil {
    if !(_object getVariable ["bw_obstacleController", false]) then {
        _object setVariable ["bw_obstacleController", true];
        _claimed = true;
    };
};
if (!_claimed) exitWith {};
while {!isNull _object && {alive _object}} do {
    if (!(_object getVariable ["buildItemHeld", false]) && {[attkWave] call bulwark_fnc_waveActive}) then {
        private _radius = (_object getVariable ["Radius", 1]) + 1;
        private _bombers = (_object nearEntities ["CAManBase", _radius]) select {
            alive _x && {_x getVariable ["bw_suicideBomber", false]} && {!isPlayer _x} &&
            {side group _x in [east, resistance]} && {isNull objectParent _x} &&
            {isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}
        };
        if !(_bombers isEqualTo []) then {
            [(_bombers select 0), 1] remoteExecCall ["setDamage", _bombers select 0];
            deleteVehicle _object;
        };
        // Ordinary infantry retains engine/LAMBS pathfinding. No permanent stance,
        // speed, behaviour or movement overrides from each nearby defense object.
    };
    sleep 0.5;
};
if (!isNull _object) then {_object setVariable ["bw_obstacleController", false]};
