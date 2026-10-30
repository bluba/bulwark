params ["_kind"];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
private _key = switch (_kind) do {
    case "active": {"STR_BW_OFFICER_START"};
    case "killed": {"STR_BW_OFFICER_KILLED"};
    case "expired": {"STR_BW_OFFICER_EXPIRED"};
    default {""};
};
if (_key != "") then {hint localize _key};
