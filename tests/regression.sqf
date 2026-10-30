/* Run on a server in an isolated editor test session:
   [] execVM "tests\regression.sqf";
   This creates temporary test objects away from the mission and removes them.
*/
if (!isServer) exitWith {};
private _failures = [];
private _assert = {
    params ["_condition", "_message"];
    if (!_condition) then {_failures pushBack _message; diag_log ("BULWARK TEST FAILED: " + _message)};
};
private _position = [getPosATL bulwarkBox, 300, 400, 5, 0] call BIS_fnc_findSafePos;
private _away = [getPosATL bulwarkBox, 600, 700, 5, 0] call BIS_fnc_findSafePos;
private _box = createVehicle ["Box_NATO_Support_F", _position, [], 0, "NONE"];
{
    private _kits = _x;
    clearItemCargoGlobal _box;
    _box addItemCargoGlobal ["FirstAidKit", _kits];
    _box addItemCargoGlobal ["ToolKit", 2];
    _box addItemCargoGlobal ["Medikit", 1];
    [_box] call bulwark_fnc_convertMedikits;
    private _items = itemCargo _box;
    [({_x == "FirstAidKit"} count _items) == (_kits mod 10), format ["FAK remainder for %1", _kits]] call _assert;
    [({_x == "Medikit"} count _items) == (1 + floor (_kits / 10)), format ["Medikit conversion for %1", _kits]] call _assert;
    [({_x == "ToolKit"} count _items) == 2, format ["Other inventory preserved for %1", _kits]] call _assert;
    private _before = getItemCargo _box;
    [_box] call bulwark_fnc_convertMedikits;
    [(getItemCargo _box) isEqualTo _before, "Repeated conversion is idempotent"] call _assert;
} forEach [0, 9, 10, 20, 25];
deleteVehicle _box;
private _group = createGroup [west, true];
private _units = [];
for "_i" from 1 to 4 do {_units pushBack (_group createUnit ["B_Soldier_F", _away, [], 0, "NONE"])};
{_x disableAI "MOVE"; _x allowDamage false} forEach _units;
(_units select 0) setPosATL _position;
for "_poll" from 1 to 5 do {
    [!([_position, _units] call bulwark_fnc_extractionReady), "One player cannot accumulate extraction visits"] call _assert;
};
{_x setPosATL _position} forEach _units;
[[_position, _units] call bulwark_fnc_extractionReady, "Whole team at extraction"] call _assert;
[!([_position, []] call bulwark_fnc_extractionReady), "Empty roster cannot win"] call _assert;
(_units select 0) setPosATL _away;
[!([_position, _units] call bulwark_fnc_extractionReady), "Leaving extraction revokes readiness"] call _assert;
{_x setPosATL _position; _x setUnconscious true} forEach _units;
sleep 0.2;
[!([_position, _units] call bulwark_fnc_extractionReady), "All unconscious cannot win"] call _assert;
{deleteVehicle _x} forEach _units;
deleteGroup _group;
missionNamespace setVariable ["BW_regressionFailures", _failures];
diag_log format ["BULWARK REGRESSION COMPLETE: %1 failures", count _failures];
