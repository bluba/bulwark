localWave =attkWave;
while(localWave==attkWave) then {
    localPlayer = objNull;
    if(localPlayer == objNull) then {
        localPlayer = selectRandom allPlayers;
        localPos = getPos localPlayer;
        localPlayer setUnitPos [1,1];
        {
            localPlayer remoteControl _x;
            break;
        } foreach allUnits;
    }
}