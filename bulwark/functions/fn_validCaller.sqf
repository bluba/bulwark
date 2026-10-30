params [["_player", objNull, [objNull]], ["_nearShop", false, [true]]];
if (!isServer || {isNull _player} || {!isPlayer _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != 2} && {remoteExecutedOwner != owner _player}) exitWith {false};
if (_nearShop && {(!alive _player) || {lifeState _player == "INCAPACITATED"} ||
    {isNil "bulwarkBox"} || {_player distance bulwarkBox > 10}}) exitWith {false};
true
