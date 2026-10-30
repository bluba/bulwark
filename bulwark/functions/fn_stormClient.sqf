// Existing client tick also handles JIP; transient strikes are never replayed.
if (!hasInterface) exitWith {};
private _state = missionNamespace getVariable ["BW_STORM_STATE", []];
if (count _state != 3 || {_state isEqualTo (missionNamespace getVariable ["BW_STORM_LOCAL_STATE", []])}) exitWith {};
0 setLightnings (_state select 2);
BW_STORM_LOCAL_STATE = +_state;
