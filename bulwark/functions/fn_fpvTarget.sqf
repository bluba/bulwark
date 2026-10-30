params ["_r","_d"];
private _uav = _d get "object";
private _history = _r get "history";
private _busy = (_r get "drones") apply {_x get "target"};
private _candidates = [];
{
    private _uid = getPlayerUID _x;
    private _last = _history getOrDefault [_uid,-1000];
    if (alive _x && {side group _x == west} && {lifeState _x != "INCAPACITATED"} &&
        {isNull objectParent _x} && {_uid != ""} && {!(_x in _busy)} &&
        {time - _last >= ((_r get "settings") get "TARGET_COOLDOWN")} &&
        {_uav distance2D _x <= 1000} && {[_uav,_x] call bulwark_fnc_fpvVisible}) then {
        private _score = 100 - ((_uav distance2D _x) / 20) - (0 max (120 - (time - _last)));
        _candidates pushBack [_score,random 1,_x];
    };
} forEach ([] call bulwark_fnc_humanPlayers);
if (_candidates isEqualTo []) exitWith {objNull};
_candidates sort false;
private _target = (selectRandom (_candidates select [0,3])) select 2;
// One director owns assignments; selection and reservation do not suspend.
_d set ["target",_target];
_history set [getPlayerUID _target,time];
_d set ["acquired",time];
["incoming"] remoteExecCall ["bulwark_fnc_fpvNotice",owner _target];
_target
