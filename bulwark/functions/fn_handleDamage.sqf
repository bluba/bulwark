params ["_unit", "_selection", "_damage", "_source", "_projectile", "_index", ["_instigator", objNull]];
private _humans = [] call bulwark_fnc_humanPlayers;
private _shooter = if (isNull _instigator) then {_source} else {_instigator};
private _friendly = (_shooter in _humans) && {_shooter != _unit};
if (_projectile == "" || {lifeState _unit == "INCAPACITATED"} ||
    {_unit getVariable ["RevByMedikit", false]} ||
    {_friendly && {!(missionNamespace getVariable ["TEAM_DAMAGE", true])}}) exitWith {
    if (_index >= 0) then {_unit getHitIndex _index} else {damage _unit}
};
_this call BIS_fnc_reviveEhHandleDamage
