// Server-owned, finite work per tick; persistent until its originating wave ends.
if (!isServer || {!canSuspend}) exitWith {};
params ["_wave"];
private _nextStrike = time + 20 + random 15;
while {[_wave] call bulwark_fnc_waveActive} do {
    BW_STORM_TARGETS = BW_STORM_TARGETS select {
        _x params ["_target", "_expiry"];
        if (time >= _expiry) then {deleteVehicle _target};
        !isNull _target
    };
    if (time >= _nextStrike) then {
        private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
        if !(_players isEqualTo []) then {
            private _anchor = getPosATL (selectRandom _players);
            private _position = [];
            for "_attempt" from 1 to 12 do {
                private _candidate = _anchor getPos [100 + random 150, random 360];
                _candidate set [2, 0];
                if ((_candidate select 0) > 0 && {(_candidate select 1) > 0} &&
                    {(_candidate select 0) < worldSize} && {(_candidate select 1) < worldSize} &&
                    {!surfaceIsWater _candidate} &&
                    {(_players findIf {_x distance2D _candidate < 60}) < 0} &&
                    {isNil "bulwarkBox" || {isNull bulwarkBox} || {bulwarkBox distance2D _candidate >= 75}} &&
                    {nearestObjects [_candidate, ["House", "StaticWeapon", "ReammoBox_F", "LandVehicle"], 25] isEqualTo []}) exitWith {
                    _position = _candidate;
                };
            };
            // Only this atomic commit may create/dispatch a strike. No targets
            // are added to Zeus, avoiding native module deletion of real assets.
            isNil {
                if (!(_position isEqualTo []) && {[_wave] call bulwark_fnc_waveActive}) then {
                    private _target = createVehicle ["Land_HelipadEmpty_F", _position, [], 0, "CAN_COLLIDE"];
                    if (!isNull _target) then {
                        _target setVariable ["bw_stormTarget", true, true];
                        BW_STORM_TARGETS pushBack [_target, time + 10];
                        [_target, _wave, serverTime] remoteExec ["bulwark_fnc_stormStrike", 0];
                    };
                };
            };
        };
        _nextStrike = time + 35 + random 30;
    };
    sleep 0.5;
};
[_wave] call bulwark_fnc_endStorm;
