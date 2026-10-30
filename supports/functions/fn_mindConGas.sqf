params ["_player", "_targetPos"];
if (!isServer || {isNull _player}) exitWith {};
if (_targetPos isEqualTo []) then {_targetPos = _player getRelPos [30, 0]};
private _smoke = "SmokeShellPurple" createVehicle _targetPos;
private _wave = attkWave;
for "_radius" from 1 to 8 do {
    if !([_wave] call bulwark_fnc_waveActive) exitWith {};
    private _units = (_smoke nearEntities ["Man", _radius]) select {
        alive _x && {side _x in [east, resistance]} && {!isPlayer _x}
    };
    _units joinSilent (group _player);
    {
        _x setVariable ["bw_stationary", false, true];
        _x setVariable ["aiMode", "NonCQB", true];
        MIND_CONTROLLED_AI pushBackUnique _x;
    } forEach _units;
    publicVariable "MIND_CONTROLLED_AI";
    sleep 1;
};
deleteVehicle _smoke;
