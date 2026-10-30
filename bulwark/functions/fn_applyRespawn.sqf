// Server response, bound to the specific corpse so late messages cannot affect a new life.
params ["_corpse", "_delay"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (hasInterface && {player isEqualTo _corpse} && {!alive player}) then {
    setPlayerRespawnTime _delay;
};
