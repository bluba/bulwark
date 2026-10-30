params ["_r"];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _spawned = false;
isNil {
    private _current = missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap];
    private _s = _r get "settings";
    private _humans = ([] call bulwark_fnc_humanPlayers) select {alive _x && {side group _x == west}};
    private _cap = (_s get "CAP") min (if (count _humans <= 1) then {1} else {2});
    private _pos = (_r get "position") vectorAdd [0,0,4];
    private _seen = _humans findIf {
        !terrainIntersectASL [eyePos _x,ATLToASL _pos] && {!lineIntersects [eyePos _x,ATLToASL _pos,_x,objNull]}
    };
    if ((_current getOrDefault ["id",-1]) == (_r get "id") && {(_r get "state") == "active"} &&
        {[_r get "wave"] call bulwark_fnc_waveActive} && {alive (_r get "operator")} && {alive (_r get "device")} &&
        {time < (_r get "deadline")} && {_seen < 0} && {count (_r get "drones") < _cap} &&
        {bulwarkBox isEqualTo (_r get "anchor")} && {bulwarkBox distance2D (_r get "origin") < 150} &&
        {(_r get "starts") < (_s get "START_LIMIT")}) then {
        private _class = if ((_r get "side") == resistance) then {"I_UAFPV_OG7V_AP"} else {"O_UAFPV_OG7V_AP"};
        // Crewless physical UAV. Separate hard cap, no invisible AI crew slots.
        private _uav = createVehicle [_class,_pos,[],0,"CAN_COLLIDE"];
        if (!isNull _uav) then {
            _uav setVariable ["bw_fpvOwned",true,true];
            _uav setVariable ["bw_fpvId",_r get "id",true];
            _uav setVariable ["bw_hostileWave",_r get "wave",true];
            // Supersede the addon's scheduled takeoff reset before it can arm.
            if (!(["prepare",_uav] call bulwark_fnc_fpvAdapter)) exitWith {
                ["cleanup",_uav] call bulwark_fnc_fpvAdapter;
            };
            (_r get "drones") pushBack (createHashMapFromArray [["object",_uav],["state","Spawn"],
                ["target",objNull],["born",time],["expires",time + (_s get "DRONE_LIFETIME")],
                ["nextSearch",time + 3],["acquired",time],["blockedSince",-1],["previous",getPosASL _uav]]);
            _r set ["starts",(_r get "starts") + 1];
            _spawned = true;
        };
    };
};
_spawned
