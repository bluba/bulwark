// One server director, at most two UAVs, no per-client or per-drone task loops.
params ["_r"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _aliveDrones = [];
{
    private _d = _x;
    private _uav = _d get "object";
    private _state = _d get "state";
    if (!alive _uav || {!local _uav} || {time >= (_d get "expires")} ||
        {_uav getVariable ["bw_fpvShotDown",false]} || {!isNull ((UAVControl _uav) param [0,objNull])}) then {_state = "Cleanup"};
    if (_state != "Cleanup") then {
        private _pos = getPosASL _uav;
        private _target = _d get "target";
        private _velocity = [0,0,0];
        if (_state == "Spawn") then {
            _velocity = [0,0,4];
            if (time >= (_d get "nextSearch")) then {_state = "Search"; _d set ["searchSince",time]};
        };
        if (_state in ["Approach","Attack"] && {
            !alive _target || {!isPlayer _target} || {side group _target != west} ||
            {lifeState _target == "INCAPACITATED"} || {!isNull objectParent _target} ||
            {!([_uav,_target] call bulwark_fnc_fpvVisible)}
        }) then {
            _d set ["target",objNull]; _state = "Search"; _d set ["searchSince",time];
        };
        if (_state == "Search") then {
            if (time - (_d getOrDefault ["searchSince",time]) >= 60) then {_state = "Cleanup"} else {
                if (time >= (_d get "nextSearch")) then {
                    _d set ["nextSearch",time + 2];
                    _target = [_r,_d] call bulwark_fnc_fpvTarget;
                    if (!isNull _target) then {_state = "Approach"};
                };
            };
        };
        if (_state == "Search") then {
            // Search a known defence area, never an unseen player's position.
            // Retain terrain/geometry collision checks below and the hard TTL.
            private _area = ATLToASL (_r get "origin");
            private _delta = _area vectorDiff _pos;
            _delta set [2,0];
            private _horizontal = if (vectorMagnitude _delta > 80) then {(vectorNormalized _delta) vectorMultiply 14} else {[0,0,0]};
            private _height = (_pos select 2) - getTerrainHeightASL (getPosATL _uav);
            _horizontal set [2,(-4 max ((25 - _height) * 2 + 0.5)) min 4];
            _velocity = _horizontal;
        };
        if (_state in ["Approach","Attack"]) then {
            private _aim = eyePos _target;
            private _distance = _pos distance _aim;
            if (_state == "Approach" && {_distance < 70} && {time - (_d get "acquired") >= 3}) then {_state = "Attack"};
            if (_state == "Approach") then {_aim set [2,(_aim select 2) + 12]};
            _velocity = (vectorNormalized (_aim vectorDiff _pos)) vectorMultiply (if (_state == "Attack") then {22} else {12});
            if (_state == "Attack" && {_distance <= 2} && {[_uav,_target] call bulwark_fnc_fpvVisible}) then {_state = "Detonation"};
        };
        // Test swept previous segment and next segment to avoid tunnelling/terrain.
        private _next = _pos vectorAdd (_velocity vectorMultiply 0.25);
        private _previous = _d get "previous";
        private _blocked = terrainIntersectASL [_pos,_next] || {terrainIntersectASL [_previous,_pos]} ||
            {!((lineIntersectsSurfaces [_pos,_next,_uav,_target,true,1,"GEOM","NONE"]) isEqualTo [])} ||
            {!((lineIntersectsSurfaces [_previous,_pos,_uav,_target,true,1,"GEOM","NONE"]) isEqualTo [])};
        if (_blocked && {_state != "Cleanup"}) then {
            if ((_d get "blockedSince") < 0) then {_d set ["blockedSince",time]};
            private _up = _pos vectorAdd [0,0,3];
            _velocity = [0,0,0];
            if (!terrainIntersectASL [_pos,_up] && {(lineIntersectsSurfaces [_pos,_up,_uav,objNull,true,1,"GEOM","NONE"]) isEqualTo []}) then {_velocity = [0,0,3]};
            _state = "Search"; _d set ["target",objNull]; _d set ["searchSince",time];
            if (time - (_d get "blockedSince") >= 5) then {_state = "Cleanup"};
        } else {_d set ["blockedSince",-1]};
        if (_state == "Detonation") then {
            // The native Hit handler stays disarmed until this atomic commit.
            isNil {
                if ((_r get "state") == "active" && {alive (_r get "operator")} && {alive (_r get "device")} &&
                    {alive _uav} && {local _uav} && {!(_uav getVariable ["bw_fpvShotDown",false])} &&
                    {[_r get "wave"] call bulwark_fnc_waveActive} && {time < (_r get "deadline")} &&
                    {alive _target} && {isPlayer _target} && {isNull objectParent _target} &&
                    {lifeState _target != "INCAPACITATED"} && {_uav distance (ASLToATL eyePos _target) <= 2} &&
                    {[_uav,_target] call bulwark_fnc_fpvVisible}) then {
                    _uav setVariable ["UA_FPV_PayloadSwapProtected",false,true];
                    private _done = ["detonate",_uav] call bulwark_fnc_fpvAdapter;
                    ["detonationResult",[_r get "id",_done]] call bulwark_fnc_fpvLog;
                };
            };
            _state = "Cleanup";
        };
        if (_state != "Cleanup") then {
            if (vectorMagnitude _velocity > 0.1) then {
                private _dir = vectorNormalized _velocity;
                if (abs (_dir select 2) < 0.95) then {_uav setVectorDirAndUp [_dir,[0,0,1]]};
            };
            _uav setVelocity _velocity;
            _d set ["previous",_pos];
        };
    };
    if (_state != (_d get "state")) then {
        ["droneState",[_r get "id",_uav,_d get "state",_state,"alive",alive _uav,"local",local _uav,"shotDown",_uav getVariable ["bw_fpvShotDown",false]]] call bulwark_fnc_fpvLog;
    };
    if (time >= (_d getOrDefault ["nextLog",0])) then {
        _d set ["nextLog",time+5];
        ["droneHeartbeat",[_r get "id",_uav,_state,getPosATL _uav,velocity _uav,_d get "target"]] call bulwark_fnc_fpvLog;
    };
    _d set ["state",_state];
    if (_state == "Cleanup") then {
        ["cleanup",_uav] call bulwark_fnc_fpvAdapter;
        _d set ["target",objNull];
    } else {_aliveDrones pushBack _d};
} forEach (_r get "drones");
_r set ["drones",_aliveDrones];
