// Scheduled, bounded transit wait shared by supports and hostile aircraft.
params ["_aircraft", "_target", "_radius", ["_timeout", 120], ["_wave", -1], ["_condition", {true}]];
private _deadline = time + _timeout;
private _validTarget = {_target isEqualType [] || {!isNull _target && {alive _target}}};
waitUntil {
    sleep 0.2;
    !alive _aircraft || {!(call _validTarget)} || {time >= _deadline} ||
    {missionNamespace getVariable ["missionExtract", false]} ||
    {!(missionNamespace getVariable ["runMissionLoop", true])} ||
    {_wave >= 0 && {!([_wave] call bulwark_fnc_waveActive)}} ||
    {!(call _condition)} ||
    {_aircraft distance2D _target <= _radius}
};
alive _aircraft && {call _validTarget} && {time < _deadline} &&
{!(missionNamespace getVariable ["missionExtract", false])} &&
{missionNamespace getVariable ["runMissionLoop", true]} &&
{_wave < 0 || {[_wave] call bulwark_fnc_waveActive}} &&
{call _condition} &&
{_aircraft distance2D _target <= _radius}
