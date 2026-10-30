params [["_wave", attkWave]];
while {[_wave] call bulwark_fnc_waveActive} do {
    private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
    {
        private _bomber = _x;
        if (alive _bomber && {_bomber getVariable ["bw_suicideBomber", false]} &&
            {time >= (_bomber getVariable ["bw_nextShout", 0])} &&
            {(_players findIf {_x distance2D _bomber < 70}) >= 0}) then {
            [_bomber, "SuicideSound"] remoteExec ["sound_fnc_say3DGlobal", 0];
            _bomber setVariable ["bw_nextShout", time + 2 + random 3];
        };
    } forEach allUnits;
    sleep 0.5;
};
