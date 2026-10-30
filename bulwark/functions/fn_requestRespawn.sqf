params [["_corpse", objNull, [objNull]]];
if (!([_corpse] call bulwark_fnc_validCaller) || {alive _corpse}) exitWith {};
// remoteExecCall and isNil keep ticket reservation atomic even for local callers.
isNil {
    private _free = missionNamespace getVariable ["buildPhase", true];
    private _reserved = _corpse getVariable ["bw_respawnReserved", false];
    if (!_free && {!_reserved} && {([west] call BIS_fnc_respawnTickets) > 0}) then {
        [west, -1] call BIS_fnc_respawnTickets;
        _reserved = true;
        _corpse setVariable ["bw_respawnReserved", true, true];
    };
    private _delay = 99999;
    if (_free) then {_delay = 0};
    if (!_free && {_reserved}) then {_delay = "RESPAWN_TIME" call BIS_fnc_getParamValue};
    [_corpse, _delay] remoteExecCall ["bulwark_fnc_applyRespawn", _corpse];
};
