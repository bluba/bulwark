params ["_corpse"];
private _droneSession = missionNamespace getVariable ["BW_droneControlSession", []];
if !(_droneSession isEqualTo []) then {[_droneSession select 0] call supports_fnc_endDroneControl};
// Freeze locally before the round trip; the server alone reserves a ticket.
setPlayerRespawnTime 99999;
[_corpse] remoteExecCall ["bulwark_fnc_requestRespawn", 2];
sleep 0.1;
if (!isNull _corpse && {!alive player}) then {
    ["Initialize", [_corpse, [west], false, true, true, false, true, true, true, true]] call BIS_fnc_EGSpectator;
};
