// Only the server can resolve a pending purchase; reopening does not allow duplicates.
params [["_success", false], ["_message", ""]];
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
missionNamespace setVariable ["BW_SHOP_PENDING", false];
missionNamespace setVariable ["BW_SHOP_MESSAGE", _message];
disableSerialization;
private _display = findDisplay 9998;
if (!isNull _display) then {(_display displayCtrl 1021) ctrlSetText _message};
if (!_success || {isNull _display}) then {hint _message};
