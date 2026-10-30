// Cancellation deletion must check takeover on the unit's owner, not the server.
params ["_unit", "_id"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _unit || {!local _unit} || {(_unit getVariable ["bw_officerId", -1]) != _id} ||
    {isPlayer _unit} || {!isNull (remoteControlled _unit)} ||
    {!isNull (_unit getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}) exitWith {};
deleteVehicle _unit;
