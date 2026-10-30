// Existing tactical tick handles JIP, respawn and local expiry without extra loops.
if (!hasInterface) exitWith {[]};
// Local positional playback; short samples expire naturally after attack/cleanup.
// Current public object state also supports clients joining during an attack.
// Let positional audio handle distance: Zeus/spectator camera may be far from player.
{
    if (_x getVariable ["bw_fpvOwned",false] && {_x getVariable ["bw_fpvAttackAudio",false]} &&
        {alive _x} &&
        {time >= (_x getVariable ["bw_fpvNextBuzzLocal",0])}) then {
        _x setVariable ["bw_fpvNextBuzzLocal",time+1];
        _x say3D ["BW_FPV_AttackBuzz",150,1];
    };
} forEach vehicles;
private _s = missionNamespace getVariable ["BW_FPV_STATUS",[]];
private _phase = (missionNamespace getVariable ["BW_TEAM_STATUS",[]]) param [1,"Ended"];
private _visible = count _s == 5 && {side group player == west} && {_phase == "Combat"} &&
    {!(missionNamespace getVariable ["buildPhase",true])} &&
    {(_s select 1) == (missionNamespace getVariable ["attkWave",-1])} && {serverTime < (_s select 4)};
private _old = missionNamespace getVariable ["BW_LOCAL_FPV_MARKER",""];
private _seconds = -1;
if (_visible) then {
    _seconds = ceil ((_s select 4) - serverTime);
    private _name = format ["BW_Fpv_%1",_s select 0];
    if (_old != _name || {markerShape _name == ""}) then {
        if (_old != "") then {deleteMarkerLocal _old};
        createMarkerLocal [_name,_s select 2];
        _name setMarkerShapeLocal "ELLIPSE";
        _name setMarkerBrushLocal "Border";
        _name setMarkerColorLocal "ColorOrange";
        _name setMarkerSizeLocal [_s select 3,_s select 3];
        _name setMarkerTextLocal localize "STR_BW_FPV_SEARCH";
        BW_LOCAL_FPV_MARKER = _name;
    };
} else {
    if (_old != "") then {deleteMarkerLocal _old; BW_LOCAL_FPV_MARKER = ""};
};
[_s,_seconds]
