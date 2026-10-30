if (!isServer) exitWith {};
playersInWave = [];
publicVariable "playersInWave";
missionNamespace setVariable ["buildPhase", true, true];
[(missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) getOrDefault ["id", -1], "preparation"] call bulwark_fnc_endOfficerHunt;
[] call bulwark_fnc_endStorm;
// Remove rounds still airborne so wave artillery cannot hit the build phase.
{deleteVehicle _x} forEach BW_WAVE_PROJECTILES;
BW_WAVE_PROJECTILES = [];
[bulwarkBox, 1] remoteExecCall ["setFuel", bulwarkBox];
["TaskSucceeded", ["Complete", format ["Wave %1 complete!", attkWave]]] remoteExec ["BIS_fnc_showNotification", 0];
[] call bulwark_fnc_refreshRespawns;
{
    if (lifeState _x == "INCAPACITATED") then {
        ["#rev", 1, _x] remoteExecCall ["BIS_fnc_reviveOnState", _x];
    };
} forEach ([] call bulwark_fnc_humanPlayers);
["Terminate"] remoteExec ["BIS_fnc_EGSpectator", 0];
{_x setDamage 1} forEach MIND_CONTROLLED_AI;
MIND_CONTROLLED_AI = [];
publicVariable "MIND_CONTROLLED_AI";
private _wait = ("DOWN_TIME" call BIS_fnc_getParamValue) +
    (240 min (attkWave * ("ADDITIONAL_DOWN_TIME" call BIS_fnc_getParamValue)));
BW_READY_PHASE = BW_READY_PHASE + 1;
BW_READY_VOTERS = [];
BW_READY_OPEN = missionNamespace getVariable ["BW_READY_VOTE_ENABLED", true];
BW_READY_MIN_DEADLINE = time + (0 max (missionNamespace getVariable ["BW_READY_MIN_PREP", 15]));
// Shared with startWave: natural preparation duration plus final warning.
BW_PREP_DEADLINE = time + (0 max _wait) + 15;
while {time < BW_PREP_DEADLINE - 15 && {!missionExtract} && {runMissionLoop} &&
    {(missionNamespace getVariable ["BW_DEBUG_NEXT_SPECIAL", ""]) == ""}} do {
    [] call bulwark_fnc_tacticalState;
    isNil {[] call bulwark_fnc_updateReadyVote};
    private _state = missionNamespace getVariable ["BW_READY_STATE", [0, false, [], 0, 1]];
    private _caption = format ["<t>%1</t>", ceil (BW_PREP_DEADLINE - time)];
    if (_state select 1) then {
        _caption = _caption + format ["<br/><t size='0.5'>Ready: %1/%2 (%3 needed). Use Ready to skip preparation.%4</t>",
            count (_state select 2), _state select 3, _state select 4,
            if (time < BW_READY_MIN_DEADLINE) then {format [" Skip unlocks in %1s.", ceil (BW_READY_MIN_DEADLINE - time)]} else {""}];
    };
    [_caption, 0, 0, 1, 0] remoteExec ["BIS_fnc_dynamicText", 0];
    [] call bulwark_fnc_refreshRespawns;
    {
        if (lifeState _x == "INCAPACITATED") then {
            ["#rev", 1, _x] remoteExecCall ["BIS_fnc_reviveOnState", _x];
        };
    } forEach ([] call bulwark_fnc_humanPlayers);
    if (time < BW_PREP_DEADLINE - 15) then {sleep 1};
};
BW_READY_OPEN = false;
isNil {[] call bulwark_fnc_updateReadyVote};
