// Register placed objects once; one server worker handles all bomber proximity checks.
if (!isServer) exitWith {};
params ["_object"];
if (isNull _object) exitWith {};
isNil {
    private _objects = missionNamespace getVariable ["BW_OBSTACLE_OBJECTS", []];
    _objects pushBackUnique _object;
    missionNamespace setVariable ["BW_OBSTACLE_OBJECTS", _objects];
    _object setVariable ["bw_obstacleController", true];
    if (scriptDone (missionNamespace getVariable ["BW_OBSTACLE_JOB", scriptNull])) then {
        BW_OBSTACLE_JOB = [] spawn {
            private _running = true;
            while {_running} do {
                // Registry pruning and shutdown are atomic with new registrations.
                private _objects = [];
                isNil {
                    private _registered = missionNamespace getVariable ["BW_OBSTACLE_OBJECTS", []];
                    {
                        if (!isNull _x && {alive _x}) then {_objects pushBack _x} else {
                            if (!isNull _x) then {_x setVariable ["bw_obstacleController", false]};
                        };
                    } forEach _registered;
                    missionNamespace setVariable ["BW_OBSTACLE_OBJECTS", _objects];
                    _running = !(_objects isEqualTo []);
                    if (!_running) then {BW_OBSTACLE_JOB = scriptNull};
                };
                if ([missionNamespace getVariable ["attkWave", 0]] call bulwark_fnc_waveActive && {_running}) then {
                    // One unit snapshot per tick, instead of one spatial query per defense.
                    private _bombers = allUnits select {
                        alive _x && {_x getVariable ["bw_suicideBomber", false]} && {!isPlayer _x} &&
                        {side group _x in [east, resistance]} && {isNull objectParent _x} &&
                        {isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}
                    };
                    if !(_bombers isEqualTo []) then {
                        {
                            private _defense = _x;
                            if (!isNull _defense && {alive _defense} && {!(_defense getVariable ["buildItemHeld", false])}) then {
                                private _radius = (_defense getVariable ["Radius", 1]) + 1;
                                private _index = _bombers findIf {alive _x && {_x distance _defense <= _radius}};
                                if (_index >= 0) then {
                                    private _bomber = _bombers deleteAt _index;
                                    [_bomber, 1] remoteExecCall ["setDamage", _bomber];
                                    deleteVehicle _defense;
                                };
                            };
                        } forEach _objects;
                    };
                };
                if (_running) then {sleep 0.5};
            };
        };
    };
};
