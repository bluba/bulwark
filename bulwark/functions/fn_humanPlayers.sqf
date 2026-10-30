// Includes dead players; excludes headless clients.
allPlayers select {isPlayer _x && {!(_x isKindOf "HeadlessClient_F")}}
