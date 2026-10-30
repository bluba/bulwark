params ["_event",["_details",[]]];
if (!isServer || {isRemoteExecuted} || {!(missionNamespace getVariable ["BW_FPV_LOG",true])}) exitWith {};
diag_log format ["[BW FPV] time=%1 wave=%2 event=%3 details=%4",time,missionNamespace getVariable ["attkWave",-1],_event,_details];
