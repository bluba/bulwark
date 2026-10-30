// Runs on the operator's client. Each activation owns one camera/control session.
params ["_operator", "_uav"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!hasInterface || {player != _operator} || {!alive _operator} || {!alive _uav}) exitWith {};
private _pilot = driver _uav;
if (isNull _pilot || {!alive _pilot}) exitWith {};

private _previous = missionNamespace getVariable ["BW_droneControlSession", []];
if !(_previous isEqualTo []) then {[_previous select 0] call supports_fnc_endDroneControl};
private _serial = (missionNamespace getVariable ["BW_droneControlSerial", 0]) + 1;
missionNamespace setVariable ["BW_droneControlSerial", _serial];
private _crew = crew _uav;
missionNamespace setVariable ["BW_droneControlSession", [_serial, _operator, _uav, _crew]];

_operator linkItem "B_UavTerminal";
_operator connectTerminalToUAV objNull;
_operator connectTerminalToUAV _uav;
_operator remoteControl objNull;
_pilot switchCamera "INTERNAL";
_operator remoteControl _pilot;

// The client observes death/deletion even if the server support script is sleeping.
// Switching between pilot and gunner of this UAV remains part of the same session.
waitUntil {
    sleep 0.1;
    private _session = missionNamespace getVariable ["BW_droneControlSession", []];
    private _controlled = remoteControlled _operator;
    _session isEqualTo [] || {(_session select 0) != _serial} ||
    {!alive _uav} || {!alive _operator} || {player != _operator} ||
    {!isRemoteControlling _operator} ||
    {!isNull _controlled && {!alive _controlled || {!(_controlled in _crew)}}} ||
    {isNull _controlled}
};
[_serial] call supports_fnc_endDroneControl;
