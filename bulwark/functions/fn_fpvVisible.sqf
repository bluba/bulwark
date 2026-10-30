// All positions in ASL. Test terrain as well as object geometry.
params ["_drone","_target"];
private _from = getPosASL _drone;
private _to = eyePos _target;
!terrainIntersectASL [_from,_to] &&
{(lineIntersectsSurfaces [_from,_to,_drone,_target,true,1,"GEOM","NONE"]) isEqualTo []}
