// One owned self-action, including JIP, respawns and action-removing scripts.
if (!hasInterface || {missionNamespace getVariable ["BW_READY_ACTION_RUNNING", false]}) exitWith {};
BW_READY_ACTION_RUNNING = true;
private _unit = objNull;
private _action = -1;
private _phase = -1;
while {true} do {
    [] call bulwark_fnc_stormClient;
    [] call bulwark_fnc_tacticalClient;
    private _state = missionNamespace getVariable ["BW_READY_STATE", [0, false, [], 0, 1]];
    private _show = !isNull player && {_state select 1} && {alive player} &&
        {lifeState player != "INCAPACITATED"} && {side group player == west} &&
        {!(getPlayerUID player in (_state select 2))};
    if (!_show || {!(_unit isEqualTo player)} || {_phase != (_state select 0)}) then {
        if (!isNull _unit && {_action >= 0}) then {_unit removeAction _action};
        _action = -1;
    };
    if (_show) then {
        if (_action < 0 || {!(_action in (actionIDs player))}) then {
            _unit = player;
            _phase = _state select 0;
            _action = _unit addAction ["Ready to skip preparation", {
                params ["_target", "_caller", "_id", "_phase"];
                [_caller, _phase] remoteExecCall ["bulwark_fnc_requestReady", 2];
            }, _phase, 1.5, false, true, "", "_target == _this", 0];
        };
        _unit setUserActionText [_action, format ["Ready to skip preparation (%1/%2 ready; %3 needed)",
            count (_state select 2), _state select 3, _state select 4]];
    };
    sleep 1;
};
