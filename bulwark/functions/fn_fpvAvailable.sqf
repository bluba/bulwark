params ["_wave", ["_plan", []]];
private _s = [] call bulwark_fnc_fpvSettings;
if (count _s == 0) exitWith {false};
private _forced = [_wave, "fpvOperator"] call bulwark_fnc_debugForced;
private _vehicleWave = "ARMOUR_START_WAVE" call BIS_fnc_getParamValue;
(["available"] call bulwark_fnc_fpvAdapter) &&
{_forced || {(missionNamespace getVariable ["BW_FPV_ENABLED", true]) isEqualTo true &&
    {_wave >= (_s get "MIN_WAVE")} && {("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0} &&
    {_vehicleWave < 9999 && {_wave >= _vehicleWave}}}} &&
{(_plan findIf {_x in ["fpvOperator", "encampment", "officerHunt"]}) < 0} &&
{count (missionNamespace getVariable ["BW_FPV_OPERATOR", createHashMap]) == 0} &&
{count (missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) == 0} &&
{!(missionNamespace getVariable ["BW_FOB_SETUP_PENDING", false])} &&
{((missionNamespace getVariable ["BW_ACTIVE_FOBS", []]) findIf {alive _x}) < 0} &&
{_forced || {private _last = missionNamespace getVariable ["BW_FPV_LAST_WAVE", -1];
    _last < 0 || {_wave > _last + (_s get "COOLDOWN")}}}
