// Idempotent client finalizer. A stale watcher must not release a newer session.
params ["_serial"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!hasInterface) exitWith {};
private _session = missionNamespace getVariable ["BW_droneControlSession", []];
if (_session isEqualTo [] || {(_session select 0) != _serial}) exitWith {};
_session params ["_id", "_operator", "_uav", "_crew"];
missionNamespace setVariable ["BW_droneControlSession", []];

private _controlled = remoteControlled _operator;
private _otherControl = !isNull _controlled && {!(_controlled in _crew)};
private _camera = cameraOn;
private _ownCamera = isNull _camera ||
    {!isNull _uav && {_camera isEqualTo _uav}} ||
    {(_crew findIf {!isNull _x && {_camera isEqualTo _x}}) >= 0};
if (!_otherControl) then {
    // A dead/deleted target may no longer be returned by remoteControlled.
    if (!isNull _controlled || {_ownCamera} || {_camera isEqualTo player}) then {_operator remoteControl objNull};
    if (_ownCamera && {!isNull player}) then {player switchCamera "INTERNAL"};
    if (!isNull _uav && {(getConnectedUAV _operator) isEqualTo _uav}) then {_operator connectTerminalToUAV objNull};
};
