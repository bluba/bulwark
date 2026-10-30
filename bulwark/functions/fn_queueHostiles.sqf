// Register finite producers before they can run, so an empty battlefield cannot end their wave.
params ["_args", "_script"];
private _handle = scriptNull;
isNil {_handle = _args execVM _script; BW_SPAWN_JOBS pushBack _handle};
_handle
