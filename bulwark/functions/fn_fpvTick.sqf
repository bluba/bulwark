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
            if (time >= (_d get "nextSearch")) then {_state = "Search"};
        };
        if (_state in ["Approach","Attack"] && {
            !alive _target || {!isPlayer _target} || {side group _target != west} ||
            {lifeState _target == "INCAPACITATED"} || {!isNull objectParent _target} ||
            {!([_uav,_target] call bulwark_fnc_fpvVisible)}
        }) then {
            private _lostReason = switch (true) do {
                case (!alive _target): {"deadOrDeleted"};
                case (!isPlayer _target): {"notPlayer"};
                case (side group _target != west): {"side"};
                case (lifeState _target == "INCAPACITATED"): {"incapacitated"};
                case (!isNull objectParent _target): {"inVehicle"};
                default {"noLineOfSight"};
            };
            ["targetLost",[_r get "id",_uav,_target,_lostReason]] call bulwark_fnc_fpvLog;
            _d set ["target",objNull]; _state = "Search";
        };
        if (_state == "Search" && {time >= (_d get "nextSearch")}) then {
            _d set ["nextSearch",time + 2];
            _target = [_r,_d] call bulwark_fnc_fpvTarget;
            if (!isNull _target) then {_state = "Approach"};
        };
        if (_state == "Search") then {
            private _origin = _r get "origin";
            private _area = ATLToASL _origin;
            private _speed = 14;
            private _altitude = 25;
            if (_uav distance2D _origin <= 150 || {_d getOrDefault ["searchInArea",false]}) then {
                _d set ["searchInArea",true];
                private _waypoint = _d getOrDefault ["searchWaypoint",[]];
                if (_waypoint isEqualTo [] || {time >= (_d getOrDefault ["nextWaypoint",0])} ||
                    {_uav distance2D _waypoint < 10}) then {
                    // Sample a search area near a defender, not a direct attack aim.
                    private _people = ([] call bulwark_fnc_humanPlayers) select {
                        alive _x && {side group _x == west} && {lifeState _x != "INCAPACITATED"} &&
                        {isNull objectParent _x} && {_x distance2D _origin <= 250}
                    };
                    private _center = if (_people isEqualTo []) then {_origin} else {getPosATL (selectRandom _people)};
                    _waypoint = _center getPos [25 + random 45,random 360];
                    _waypoint set [2,18 + random 10];
                    _d set ["searchWaypoint",_waypoint];
                    _d set ["nextWaypoint",time + 6 + random 4];
                    ["searchWaypoint",[_r get "id",_uav,_waypoint]] call bulwark_fnc_fpvLog;
                };
                _area = ATLToASL _waypoint;
                _altitude = _waypoint select 2;
                _speed = 9;
            };
            private _delta = _area vectorDiff _pos;
            _delta set [2,0];
            private _horizontal = (vectorNormalized _delta) vectorMultiply (_speed min (vectorMagnitude _delta));
            private _height = (_pos select 2) - getTerrainHeightASL (getPosATL _uav);
            _horizontal set [2,(-4 max ((_altitude - _height) * 2 + 0.5)) min 4];
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
            _state = "Search"; _d set ["target",objNull];
            _d set ["nextWaypoint",0];
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
