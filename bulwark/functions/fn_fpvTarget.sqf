params ["_r","_d"];
private _uav = _d get "object";
private _history = _r get "history";
private _busy = (_r get "drones") apply {_x get "target"};
private _candidates = [];
{
    private _uid = getPlayerUID _x;
    private _last = _history getOrDefault [_uid,-1000];
    private _reason = switch (true) do {
        case (!alive _x): {"dead"};
        case (side group _x != west): {"side"};
        case (lifeState _x == "INCAPACITATED"): {"incapacitated"};
        case (!isNull objectParent _x): {"inVehicle"};
        case (_uid == ""): {"missingUID"};
        case (_x in _busy): {"assigned"};
        case (time - _last < ((_r get "settings") get "TARGET_COOLDOWN")): {"cooldown"};
        case (_uav distance2D _x > 1000): {"range"};
        case (!([_uav,_x] call bulwark_fnc_fpvVisible)): {"noLineOfSight"};
        default {""};
    };
    if (_reason != "") then {["targetRejected",[_r get "id",_uav,name _x,_reason,_uav distance2D _x]] call bulwark_fnc_fpvLog};
    if (_reason == "") then {
        private _score = 100 - ((_uav distance2D _x) / 20) - (0 max (120 - (time - _last)));
        _candidates pushBack [_score,random 1,_x];
    };
} forEach ([] call bulwark_fnc_humanPlayers);
if (_candidates isEqualTo []) exitWith {["noEligibleTarget",[_r get "id",_uav,getPosATL _uav]] call bulwark_fnc_fpvLog; objNull};
_candidates sort false;
private _target = (selectRandom (_candidates select [0,3])) select 2;
// One director owns assignments; selection and reservation do not suspend.
_d set ["target",_target];
_history set [getPlayerUID _target,time];
_d set ["acquired",time];
["incoming"] remoteExecCall ["bulwark_fnc_fpvNotice",owner _target];
["targetAcquired",[_r get "id",_uav,name _target,_uav distance _target]] call bulwark_fnc_fpvLog;
_target
