if (!isServer) exitWith {};
params ["_wave"];
if !([_wave] call bulwark_fnc_waveActive) exitWith {};
private _location = [getPosATL bulwarkBox, 500, 1000, 10, 0] call BIS_fnc_findSafePos;
private _marker = format ["BulwarkBonus_%1", _wave];
createMarker [_marker, _location];
_marker setMarkerShape "ELLIPSE";
_marker setMarkerSize [100, 100];
_marker setMarkerColor "ColorWhite";
[] call bulwark_fnc_tacticalState;
["TaskAssigned", ["Bonus", "Reach the white objective during this wave for bonus funds."]] remoteExec ["BIS_fnc_showNotification", 0];
private _reached = false;
while {[_wave] call bulwark_fnc_waveActive} do {
    _reached = (([] call bulwark_fnc_humanPlayers) findIf {
        alive _x && {lifeState _x != "INCAPACITATED"} && {_x distance2D _location <= 100}
    }) >= 0;
    if (_reached) exitWith {};
    sleep 1;
};
if (_reached && {[_wave] call bulwark_fnc_waveActive}) then {
    isNil {
        private _bonus = _wave * 2000 + count ([] call bulwark_fnc_humanPlayers) * 500;
        bulwarkBox setVariable ["pointBankAmount", (bulwarkBox getVariable ["pointBankAmount", 0]) + _bonus, true];
    };
    ["TaskSucceeded", ["Bonus", "Location reached! Funds added to the bank."]] remoteExec ["BIS_fnc_showNotification", 0];
    [] remoteExecCall ["killPoints_fnc_updatePointBankAmount", 0];
};
deleteMarker _marker;
[] call bulwark_fnc_tacticalState;
