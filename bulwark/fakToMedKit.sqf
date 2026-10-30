if (!isServer) exitWith {};
// Preserve the existing ten-kit cost. Process each nearby container only once per poll.
while {missionNamespace getVariable ["runMissionLoop", true]} do {
    private _containers = [bulwarkBox];
    {
        {_containers pushBackUnique _x} forEach (nearestObjects [_x, ["Box_NATO_Support_F"], 15]);
    } forEach ([] call bulwark_fnc_humanPlayers);
    {[_x] call bulwark_fnc_convertMedikits} forEach _containers;
    sleep 2;
};
