// Client supplies its player object and the phase captured by its local action.
params [["_player", objNull, [objNull]], ["_phase", -1, [0]]];
if (!([_player] call bulwark_fnc_validCaller)) exitWith {};
if (!(missionNamespace getVariable ["BW_READY_OPEN", false]) ||
    {_phase != BW_READY_PHASE} || {!buildPhase} || {missionExtract} ||
    {!runMissionLoop} || {time >= BW_PREP_DEADLINE - 15}) exitWith {};
if !(_player in ([] call bulwark_fnc_readyVoters)) exitWith {};
BW_READY_VOTERS pushBackUnique (getPlayerUID _player);
