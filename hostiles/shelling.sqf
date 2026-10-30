params ["_wave"];
while {[_wave] call bulwark_fnc_waveActive} do {
    for "_i" from 0 to (1 + floor random 5) do {
        if !([_wave] call bulwark_fnc_waveActive) exitWith {};
        private _position = [([] call bulwark_fnc_spawnAnchor), 25, 200, 1, 0] call BIS_fnc_findSafePos;
        private _shell = createVehicle ["Sh_155mm_AMOS", [_position select 0, _position select 1, 500], [], 0, "CAN_COLLIDE"];
        BW_WAVE_PROJECTILES pushBack _shell;
        _shell setVelocity [0, 0, -50];
        sleep (0.5 + random 1);
    };
    private _next = time + 0.5 + random 30;
    waitUntil {sleep 0.5; time >= _next || {!([_wave] call bulwark_fnc_waveActive)}};
};
