if (!isServer) exitWith {};
{
    private _player = _x;
    if (alive _player && {lifeState _player == "INCAPACITATED"} &&
        {!(_player getVariable ["RevByMedikit", false])} &&
        {!(missionNamespace getVariable ["buildPhase", true])}) then {
        private _medical = (nearestObjects [_player, ["CUP_B_nM997_NATO_T"], 10]) findIf {alive _x};
        if ("Medikit" in items _player || {_medical >= 0}) then {
            // Reserve on the server before sending work to the player's owner.
            _player setVariable ["RevByMedikit", true, true];
            [_player, _medical < 0] remoteExec ["bulwark_fnc_revivePlayer", _player];
        };
    };
} forEach ([] call bulwark_fnc_humanPlayers);
