// Dead spectators, incapacitated players, AI and headless clients do not vote.
([] call bulwark_fnc_humanPlayers) select {
    alive _x && {lifeState _x != "INCAPACITATED"} &&
    {side group _x == west} && {getPlayerUID _x != ""}
}
