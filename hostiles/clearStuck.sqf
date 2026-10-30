if (!isServer) exitWith {};
// Conservative fallback for local, distant infantry with an outstanding movement order.
// Scripted transports own their timeout/cleanup. Never destroy a vehicle from a crew sample.
private _eligible = {
    params ["_unit"];
    alive _unit && {local _unit} && {isNull objectParent _unit} && {!isPlayer _unit} &&
    {isNull (remoteControlled _unit)} && {side group _unit in [east, resistance]} &&
    {!(_unit getVariable ["bw_stationary", false])} &&
    {!((group _unit) getVariable ["bw_scriptedMovement", false])} &&
    {(units group _unit findIf {isPlayer _x || {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}}) < 0} &&
    {((group _unit) getVariable ["bw_aiMode", ""]) in ["rush", "creep"]} &&
    {behaviour _unit != "COMBAT"} && {currentCommand _unit in ["MOVE", "FOLLOW"]} && {!unitReady _unit}
};
while {missionNamespace getVariable ["runMissionLoop", true]} do {
    private _wave = missionNamespace getVariable ["attkWave", 0];
    private _samples = [];
    if ([_wave] call bulwark_fnc_waveActive) then {
        {
            if ([_x] call _eligible) then {
                private _target = (expectedDestination _x) select 0;
                if (_x distance2D _target > 25) then {_samples pushBack [_x, getPosATL _x, _target]};
            };
        } forEach allUnits;
    };
    sleep 60;
    if ([_wave] call bulwark_fnc_waveActive) then {
        private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
        if !(_players isEqualTo []) then {
            {
                _x params ["_unit", "_oldPosition", "_target"];
                private _stalled = [_unit] call _eligible &&
                    {_unit distance2D _oldPosition < 5} &&
                    {_target distance2D ((expectedDestination _unit) select 0) < 10} &&
                    {_unit distance2D _target > 25} &&
                    {(_players findIf {_x distance2D _unit < (BULWARK_RADIUS max 100)}) < 0} &&
                    {(west knowsAbout _unit) < 3.5};
                if (_stalled) then {
                    private _previous = _unit getVariable ["bw_stallSample", [-1, -1000]];
                    if ((_previous select 0) == _wave && {time - (_previous select 1) < 75}) then {
                        deleteVehicle _unit;
                    } else {_unit setVariable ["bw_stallSample", [_wave, time]]};
                } else {_unit setVariable ["bw_stallSample", nil]};
            } forEach _samples;
        };
    };
};
