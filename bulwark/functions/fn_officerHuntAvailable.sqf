params ["_wave", ["_plan", []]];
private _settings = [] call bulwark_fnc_officerSettings;
if (count _settings == 0) exitWith {false};
private _enabled = missionNamespace getVariable ["BW_OFFICER_ENABLED", true];
private _last = missionNamespace getVariable ["BW_OFFICER_LAST_WAVE", -1];
private _forced = [_wave, "officerHunt"] call bulwark_fnc_debugForced;
(_forced || {_enabled isEqualTo true && {_wave >= (_settings get "MIN_WAVE")} &&
    {("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0}}) &&
{!("officerHunt" in _plan)} && {!("encampment" in _plan)} &&
{count (missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) == 0} &&
{!(missionNamespace getVariable ["BW_FOB_SETUP_PENDING", false])} &&
{((missionNamespace getVariable ["BW_ACTIVE_FOBS", []]) findIf {alive _x}) < 0} &&
{_forced || {_last < 0 || {_wave > _last + (_settings get "COOLDOWN_WAVES")}}}
