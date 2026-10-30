params [["_player", objNull, [objNull]]];
if (!([_player] call bulwark_fnc_validCaller) || {!alive _player} ||
    {isNil "lootBox"} || {_player distance lootBox > 5}) exitWith {};
private _accepted = false;
private _box = lootBox;
isNil {
    if (!(_box getVariable ["bw_spinning", false]) && {[_player, SCORE_RANDOMBOX] call killPoints_fnc_spend}) then {
        _box setVariable ["bw_spinning", true, true];
        _accepted = true;
    };
};
if (_accepted) then {
    [_box] spawn {
        params ["_box"];
        private _job = [getPos _box, getPosATL _box, getDir _box] execVM "loot\spin\main.sqf";
        waitUntil {sleep 0.2; scriptDone _job};
        if (!isNull _box) then {_box setVariable ["bw_spinning", false, true]};
    };
};
