params ["_wave"];
private _launchAt = time + random 120;
waitUntil {sleep 0.5; time >= _launchAt || {!([_wave] call bulwark_fnc_waveActive)}};
if !([_wave] call bulwark_fnc_waveActive) exitWith {};
private _dirX = selectRandom [-1, 1];
private _dirY = selectRandom [-1, 1];
for "_salvo" from 1 to 3 do {
    for "_round" from 1 to 41 do {
        if !([_wave] call bulwark_fnc_waveActive) exitWith {};
        private _position = [([] call bulwark_fnc_spawnAnchor), 50, 300, 1, 0] call BIS_fnc_findSafePos;
        private _shell = createVehicle ["CUP_R_GRAD_HE", [(_position select 0) + 2800 * _dirX, (_position select 1) + 2800 * _dirY, 1000], [], 0, "CAN_COLLIDE"];
        BW_WAVE_PROJECTILES pushBack _shell;
        _shell setVelocity [-200 * _dirX, -200 * _dirY, -5];
        sleep 0.5;
    };
    if !([_wave] call bulwark_fnc_waveActive) exitWith {};
    sleep (0.5 + random 15);
};
