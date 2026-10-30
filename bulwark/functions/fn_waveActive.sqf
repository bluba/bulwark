params ["_wave"];
(missionNamespace getVariable ["runMissionLoop", false]) &&
{!(missionNamespace getVariable ["missionExtract", false])} &&
{!(missionNamespace getVariable ["buildPhase", true])} &&
{_wave == (missionNamespace getVariable ["attkWave", 0])}
