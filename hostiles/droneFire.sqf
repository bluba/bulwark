params [["_wave", attkWave]];
waitUntil {sleep 0.2; waveSpawned || {!([_wave] call bulwark_fnc_waveActive)}};
while {[_wave] call bulwark_fnc_waveActive} do {
    private _groups = droneSquad select {!isNull _x && {alive (leader _x)}};
    private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x && {lifeState _x != "INCAPACITATED"}};
    if (!(_groups isEqualTo []) && {!(_players isEqualTo [])}) then {
        private _drone = vehicle (leader (selectRandom _groups));
        if (alive _drone && {_drone isKindOf "Air"}) then {
            _drone fireAtTarget [selectRandom _players];
        };
    };
    private _nextShot = time + 30;
    waitUntil {sleep 0.5; time >= _nextShot || {!([_wave] call bulwark_fnc_waveActive)}};
};
