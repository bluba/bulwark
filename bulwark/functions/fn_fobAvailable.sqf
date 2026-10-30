// Shared by wave selection and the atomic server-side setup reservation.
params ["_wave", ["_plan", []]];
private _lastWave = missionNamespace getVariable ["BW_FOB_LAST_WAVE", -1];
private _cooldown = 0 max floor (missionNamespace getVariable ["BW_FOB_COOLDOWN_WAVES", 2]);
private _forced = [_wave, "encampment"] call bulwark_fnc_debugForced;
(_forced || {_wave >= 7 && {("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0}}) &&
{!("encampment" in _plan)} &&
{!("officerHunt" in _plan)} &&
{!("fpvOperator" in _plan)} &&
{count (missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap]) == 0} &&
{count (missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) == 0} &&
{!(missionNamespace getVariable ["BW_FOB_SETUP_PENDING", false])} &&
{((missionNamespace getVariable ["BW_ACTIVE_FOBS", []]) findIf {alive _x}) < 0} &&
{_forced || {_lastWave < 0 || {_wave > _lastWave + _cooldown}}}
