params [["_wave", attkWave]];
while {[_wave] call bulwark_fnc_waveActive} do {
    private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
    {
        private _bomber = _x;
        if (alive _bomber && {_bomber getVariable ["bw_suicideBomber", false]}) then {
            if ((_players findIf {_bomber distance2D _x < 10}) >= 0) then {_bomber setDamage 1};
        };
    } forEach allUnits;
    sleep 0.2;
};
