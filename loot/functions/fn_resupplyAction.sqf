// Reinstalled after placement; a stable JIP key retains only the latest action setup.
params ["_crate"];
if (!hasInterface || {isNull _crate} || {(_crate getVariable ["bw_supplyPurchase", ""]) == ""}) exitWith {};
_crate removeAction (_crate getVariable ["bw_resupplyAction", -1]);
private _family = _crate getVariable ["bw_supplyPurchase", ""];
private _row = BULWARK_SUPPLYITEMS select {(_x select 2) == _family};
if (_row isEqualTo []) exitWith {};
private _id = _crate addAction [format ["Resupply (%1 points)", _row select 0 select 0], {
    params ["_target", "_caller"];
    [_caller, _target, _target getVariable ["bw_resupplyRevision", 0]] remoteExecCall ["loot_fnc_resupply", 2];
}, nil, 1.5, true, true, "", "alive _target && {!(_target getVariable ['buildItemHeld',true])} && {isNull attachedTo _target} && {alive _this}", 5];
_crate setVariable ["bw_resupplyAction", _id];
