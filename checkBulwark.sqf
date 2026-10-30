bulwarkPos = [0,0];
while {true} do {
	if(!(isNull bulwarlBox)) then {
		if(!(alive bulwarkBox )) then {
			_newpos = [bulwarkPos, 0, 50,1,0] call BIS_fnc_findSafePos; 
			bulwarkBox = createVehicle ["PSZ_PL_WDL10_Star_1466", _newpos, [], 0, "CAN_COLLIDE"];
			// pointBankAmount for the Bulwark box
			bulwarkBox setVariable ["pointBankAmount", POINT_BANK_INIT_AMOUNT, true];

			_bulMon = createVehicle ["Land_Laptop_device_F", [0,0,0], [], 0, "CAN_COLLIDE"];
			_bulMon allowDamage false;
			bulwarkBox allowDamage false;
			bulwarkFallDamage = {
			_damage = 0;
			if((_this select 4) != "") then
			{
			_damage = _this select 2;
			};
			_damage
			};
			bulwarkBox addEventHandler ["HandleDamage", { _this call bulwarkFallDamage }];
			clearItemCargoGlobal bulwarkBox;
			clearWeaponCargoGlobal bulwarkBox;
			clearMagazineCargoGlobal bulwarkBox;
			clearBackpackCargoGlobal bulwarkBox;
			[_bulMon,[0,"preview.paa"]] remoteExec ["setObjectTexture",0,true];
			_bulMon enableSimulation false;
			_bulMon attachTo [bulwarkBox, [0,0.1,0.6]];
			_bulMon setDir 180;

			publicVariable "bulwarkCity";

			//bulwarkBox addWeaponCargoGlobal["hgun_P07_F",10];
			//bulwarkBox addMagazineCargoGlobal ["16Rnd_9x21_Mag",20];
			if(BULWARK_MEDIKITS > 0) then {
				bulwarkBox addItemCargoGlobal ["Medikit", BULWARK_MEDIKITS];
			};

			//Add actions to Bulwark Box
			[bulwarkBox, ["<t color='#00ffff'>" + "Pickup", "bulwark\moveBox.sqf","",1,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];
			[bulwarkBox, ["<t color='#00ff00'>" + "Shop +", "[] spawn bulwark_fnc_purchaseGuiNew; ShopCaller = _this select 1", "",1.5, false,false, "true", "true", 2.5]] remoteExec ["addAction", 0, true];
			/*[bulwarkBox, ["<t color='#0000ff'>" + "Old Shop", "[] spawn bulwark_fnc_purchaseGui; ShopCaller = _this select 1","",1.5,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];*/
			[bulwarkBox, ["<t color='#ff0000'>" + "Heal Yourself: 200p", "
				_player = _this select 1;
				_points = _player getVariable 'killPoints';
				if (_points >= 500) then {
					[_player, 0] remoteExec ['setDamage', 0, true];
					[_player, 200] remoteExec ['killPoints_fnc_spend', 2];
					[true] remoteExec ['disableUserInput', _player];
					[_player, 'AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon'] remoteExec ['switchMove', 0];
					sleep 1;
					[false] remoteExec ['disableUserInput', _player];
				};
			","",1,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];

			//Add Bulwark Box to Zeus
			mainZeus addCuratorEditableObjects [[bulwarkBox], true];

			//Add EH for text to explain the FAK to Medkit feature
			[bulwarkBox, ["ContainerOpened", {
				_playerId = _this select 1;
				["<t size = '.5'>Place 15 FAKs into the Bulwark to convert them into a Medikit</t>", 0, 1, 60, 0] remoteExec ["BIS_fnc_dynamicText", _playerId];
			}]] remoteExec ["addEventHandler", 0, true];
			[bulwarkBox, ["ContainerClosed", {
				_playerId = _this select 1;
				["", 0, 1, 0.05, 0] remoteExec ["BIS_fnc_dynamicText", _playerId];
			}]] remoteExec ["addEventHandler", 0, true];
		};
		bulwarkCity = getPos bulwarkbox;
		bulwarkPos = getPos bulwarkBox;
	};
	sleep 10;
};