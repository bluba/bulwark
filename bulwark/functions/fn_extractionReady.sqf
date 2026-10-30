params ["_location", ["_roster", [] call bulwark_fnc_humanPlayers]];
private _survivors = _roster select {alive _x};
!(_survivors isEqualTo []) &&
{(_survivors findIf {lifeState _x != "INCAPACITATED"}) >= 0} &&
{(_survivors findIf {_x distance2D _location > 100}) < 0}
