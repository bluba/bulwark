// Reuse existing server phase ticks. No world/unit scan or new polling script.
if (!isServer || {isRemoteExecuted}) exitWith {};
[] call bulwark_fnc_updateOfficerHunt;
// Keep cleanup's read/modify/publish atomic with incoming remoteExecCall requests.
isNil {
private _running = missionNamespace getVariable ["runMissionLoop", false];
private _extract = missionNamespace getVariable ["missionExtract", false];
private _prep = missionNamespace getVariable ["buildPhase", true];
private _wave = missionNamespace getVariable ["attkWave", 0];
private _bank = if (isNil "bulwarkBox") then {0} else {bulwarkBox getVariable ["pointBankAmount", 0]};
private _fobs = {alive _x} count (missionNamespace getVariable ["BW_ACTIVE_FOBS", []]);
private _bonus = markerShape (format ["BulwarkBonus_%1", _wave]) != "";
private _phase = if (!_running) then {"Ended"} else {if (_extract) then {"Extraction"} else {
    if (_prep) then {"Preparation"} else {"Combat"}
}};
private _state = [_wave, _phase, 0 max ([west] call BIS_fnc_respawnTickets), _bank, _fobs, _bonus && {!_prep}];
if !(_state isEqualTo (missionNamespace getVariable ["BW_TEAM_STATUS", []])) then {
    missionNamespace setVariable ["BW_TEAM_STATUS", _state, true];
};
private _old = missionNamespace getVariable ["BW_TACTICAL_PINGS", []];
private _pings = _old select {
    _running && {!_extract} && {serverTime < (_x select 5)} &&
    {isPlayer (_x select 1)} && {alive (_x select 1)} && {side group (_x select 1) == west}
};
if !(_pings isEqualTo _old) then {missionNamespace setVariable ["BW_TACTICAL_PINGS", _pings, true]};
};
