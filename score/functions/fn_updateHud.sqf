// Existing score HUD, extended with the server's public team-state snapshot.
if (!hasInterface) exitWith {};
disableSerialization;
private _state = missionNamespace getVariable ["BW_TEAM_STATUS", [0, "Loading", 0, 0, 0, false]];
_state params ["_wave", "_phase", "_tickets", "_bank", "_fobs", "_bonus"];
private _objectives = [];
if (_fobs > 0) then {_objectives pushBack format [localize "STR_BW_FOB_OBJECTIVE", _fobs]};
if (_bonus) then {_objectives pushBack localize "STR_BW_BONUS_OBJECTIVE"};
private _officer = missionNamespace getVariable ["BW_OFFICER_STATUS", []];
if (count _officer == 5 && {_phase == "Combat"} && {side group player == west} &&
    {(_officer select 1) == _wave} && {serverTime < (_officer select 4)}) then {
    _objectives pushBack format [localize "STR_BW_OFFICER_HUD", ceil ((_officer select 4) - serverTime)];
};
{
    _x params ["_key", "_label", "_deliveryKey", "_inboundLabel", "_descendingLabel"];
    private _supply = missionNamespace getVariable [_key, []];
    private _delivery = missionNamespace getVariable [_deliveryKey, []];
    if (count _supply == 5 && {side group player == west} && {alive (_supply select 1)} &&
        {serverTime < (_supply select 3)}) then {
        _objectives pushBack format [localize _label, ceil ((_supply select 3) - serverTime)];
    } else {
        if (count _delivery == 5 && {_phase == "Combat"} && {side group player == west} &&
            {(_delivery select 2) == _wave} && {serverTime < (_delivery select 3)} &&
            {(_delivery select 4) in ["inbound", "descending"]}) then {
            _objectives pushBack localize (if ((_delivery select 4) == "descending") then {_descendingLabel} else {_inboundLabel});
        };
    };
} forEach [
    ["BW_SUPPLY_STATUS", "STR_BW_MEDICAL_CACHE", "BW_SUPPLY_DELIVERY_STATUS", "STR_BW_MEDICAL_INBOUND", "STR_BW_MEDICAL_DESCENDING"],
    ["BW_ENGINEERING_STATUS", "STR_BW_ENGINEERING_CACHE", "BW_ENGINEERING_DELIVERY_STATUS", "STR_BW_ENGINEERING_INBOUND", "STR_BW_ENGINEERING_DESCENDING"]
];
if (_objectives isEqualTo []) then {
    _objectives pushBack localize (if (_phase == "Combat") then {"STR_BW_DEFEND"} else {"STR_BW_PREPARE"});
};
if (_phase in ["Extraction", "Ended"]) then {_objectives = [localize ("STR_BW_" + _phase)]};
// Keep player-controlled names out of structured markup.
private _hudText = format [localize "STR_BW_BOARD",
    player getVariable ["killPoints", 0], _wave, localize ("STR_BW_" + _phase), _tickets, _bank, _objectives joinString "<br/>"];
private _ui = uiNamespace getVariable ["KillPointsHud", displayNull];
if (isNull _ui) then {
    1000 cutRsc ["KillPointsHud", "PLAIN"];
    _ui = uiNamespace getVariable ["KillPointsHud", displayNull];
};
private _control = _ui displayCtrl 99999;
_control ctrlSetStructuredText parseText _hudText;
_control ctrlSetPositionH ((ctrlTextHeight _control) + 0.015);
_control ctrlCommit 0;
