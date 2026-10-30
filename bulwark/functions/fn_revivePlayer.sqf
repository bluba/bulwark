params ["_unit", ["_consumeMedikit", true]];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!local _unit || {!alive _unit}) exitWith {
    if (local _unit) then {_unit setVariable ["RevByMedikit", false, true]};
};
if (_consumeMedikit && {!("Medikit" in items _unit)}) exitWith {_unit setVariable ["RevByMedikit", false, true]};
if (_consumeMedikit) then {_unit removeItem "Medikit"};
_unit setUnconscious false;
["#rev", 1, _unit] call BIS_fnc_reviveOnState;
_unit setDamage 0;
_unit playAction "agonyStop";
sleep 15;
_unit setVariable ["RevByMedikit", false, true];
