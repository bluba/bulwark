// No engine spawning. Optional [0,1) samples make plans reproducible in tests.
params ["_wave","_start","_humans","_catalogue",["_samples",[]],["_last",""],["_settings",[3,0.75,0.30,2,30,0.20]]];
_samples = +_samples;
private _draw = {private _v = if (_samples isEqualTo []) then {random 1} else {_samples deleteAt 0}; 0 max (0.999999 min _v)};
private _plan = createHashMapFromArray [["wave",_wave],["budget",0],["unused",0],["entries",[]]];
if (_start >= 9999 || {_wave < _start}) exitWith {_plan};
private _age = _wave - _start;
_settings params ["_base","_growth","_playerStep","_playerCap","_targetCap","_spread"];
private _target = _targetCap min ((_base + _growth * _age) * (_playerCap min (1 + _playerStep * (0 max (_humans - 2)))));
private _low = 2 max floor (_target * (1 - _spread));
private _high = _low max ceil (_target * (1 + _spread));
private _budget = _low + floor ((call _draw) * (_high - _low + 1));
private _left = _budget;
private _entries = [];
private _theme = ["patrol","truck","armour","combatAir"] select floor ((call _draw)*4);
for "_i" from 1 to (if (_age < 3) then {2} else {4}) do {
 private _heavy = {(_x select 3) in ["heavy","combatAir"]} count _entries;
 private _eligible = _catalogue select {
  private _candidate = _x;
  (_x select 1) > 0 && {(_x select 1) <= _left} &&
  {({_x isEqualTo _candidate} count _entries) < 2} &&
  {!((_x select 3) in ["heavy","combatAir"]) || {_heavy < (if (_age < 14) then {1} else {2})}} &&
  {(_x select 3) != "combatAir" || {(_entries findIf {(_x select 3) == "combatAir"}) < 0}}
 };
 if (_eligible isEqualTo []) exitWith {};
 // Buy a main threat from the upper cost band before filling support slots.
 // This band follows actual affordable candidates, so sparse addon sets still work.
 if (_i == 1) then {
  private _highest = 0; {_highest = _highest max (_x select 1)} forEach _eligible;
  private _minimum = ceil (_highest * 0.75);
  _eligible = _eligible select {(_x select 1) >= _minimum};
 };
 private _weights = _eligible apply {
  private _role = _x select 3;
  (if (_role == _theme) then {2} else {1}) / ({(_x select 3) == _role} count _eligible) * (if ((_x select 0) == _last) then {0.5} else {1})
 };
 private _sum = 0; {_sum = _sum + _x} forEach _weights;
 private _roll = (call _draw)*_sum;
 private _index = count _eligible - 1;
 {_roll = _roll - _x; if (_roll < 0) exitWith {_index = _forEachIndex}} forEach _weights;
 private _entry = +(_eligible select _index);
 _entries pushBack _entry; _left = _left - (_entry select 1);
};
_plan set ["budget",_budget]; _plan set ["unused",_left]; _plan set ["entries",_entries]; _plan set ["theme",_theme];
_plan
