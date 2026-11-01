// Server/editor: [] execVM "tests\vehicleTickets.sqf"; pure planner tests, no spawning.
private _failures = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label}};
private _catalogue = [["light",2,0,"patrol",0],["truck",3,2,"truck",5],["tank",10,8,"heavy",0],["heli",12,11,"combatAir",0]];
{
 private _h = _x;
 for "_wave" from 1 to 100 do {
  {
   private _samples = []; for "_j" from 1 to 8 do {_samples pushBack _x};
   private _p = [_wave,5,_h,_catalogue,_samples] call bulwark_fnc_vehiclePlan;
   private _entries = _p get "entries";
   private _sum = 0; {_sum = _sum + (_x select 1)} forEach _entries;
   [_sum + (_p get "unused") == (_p get "budget"),"accounting"] call _check;
   [(_p get "budget") <= 36,"budget cap"] call _check;
   [(_entries findIf {(_x select 2) > _wave - 5}) < 0,"unlock"] call _check;
   [count _entries <= (if (_wave < 8) then {2} else {4}),"package cap"] call _check;
   [({(_x select 3) == "combatAir"} count _entries) <= 1,"air cap"] call _check;
   if (_wave < 19) then {[({(_x select 3) in ["heavy","combatAir"]} count _entries) <= 1,"early heavy cap"] call _check};
   {private _c = _x; [({_x isEqualTo _c} count _entries) <= 2,"repeat cap"] call _check} forEach _entries;
   if (_wave < 5) then {[_entries isEqualTo [] && {(_p get "budget") == 0},"before unlock"] call _check};
   private _again = [_wave,5,_h,_catalogue,_samples] call bulwark_fnc_vehiclePlan;
   [(_again get "entries") isEqualTo _entries,"deterministic samples"] call _check;
  } forEach [0,0.5,0.999999];
 };
} forEach [1,2,3,4,8,16,32];
[(([100,9999,8,_catalogue] call bulwark_fnc_vehiclePlan) get "budget") == 0,"Never"] call _check;
[(([20,5,4,[]] call bulwark_fnc_vehiclePlan) get "entries") isEqualTo [],"empty catalogue"] call _check;
diag_log format ["Vehicle ticket planner tests: %1 failures: %2",count _failures,_failures];
if !(_failures isEqualTo []) then {throw str _failures};
