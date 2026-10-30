params ["_kind"];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {side group player != west}) exitWith {};
private _key = switch (_kind) do {
    case "active": {"STR_BW_FPV_START"};
    case "ended": {"STR_BW_FPV_END"};
    case "incoming": {"STR_BW_FPV_INCOMING"};
    default {""};
};
if (_key != "") then {hint localize _key};
