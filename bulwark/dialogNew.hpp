class startBox_DialogNew
{
    idd = 9998;
    movingEnabled = false;
    onUnload = "['save'] call bulwark_fnc_shop;";
    class controlsBackground
    {
        class Panel: RscText
        {
            idc = -1;
            x = 0.10 * safezoneW + safezoneX;
            y = 0.10 * safezoneH + safezoneY;
            w = 0.80 * safezoneW;
            h = 0.79 * safezoneH;
            colorBackground[] = {0.035,0.045,0.055,0.97};
        };
    };
    class controls
    {
        class Title: RscText
        {
            idc = 1002;
            text = "BULWARK";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.22 * safezoneW;
            h = 0.04 * safezoneH;

        };
        class Balances: RscText
        {
            idc = 1005;
            text = "";
            x = 0.34 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.48 * safezoneW;
            h = 0.04 * safezoneH;

        };
        class Close: RscButton
        {
            idc = 1603;
            text = "Close";
            x = 0.825 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.06 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
        class Build: RscButton
        {
            idc = 1600;
            text = "Build";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.175 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['tab', 0] call bulwark_fnc_shop;";
        };
        class Support: RscButton
        {
            idc = 1601;
            text = "Support";
            x = 0.235 * safezoneW + safezoneX;
            y = 0.175 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['tab', 1] call bulwark_fnc_shop;";
        };
        class Supplies: RscButton
        {
            idc = 1614;
            text = "Supplies";
            x = 0.355 * safezoneW + safezoneX;
            y = 0.175 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['tab', 3] call bulwark_fnc_shop;";
        };
        class Admin: RscButton
        {
            idc = 1610;
            text = "Admin";
            x = 0.475 * safezoneW + safezoneX;
            y = 0.175 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['tab', 2] call bulwark_fnc_shop;";
        };
        class AmountLabel: RscText
        {
            idc = 1003;
            text = "Transfer amount";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.13 * safezoneW;
            h = 0.035 * safezoneH;

        };
        class Amount: RscEdit
        {
            idc = 1400;
            text = "";
            x = 0.25 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.035 * safezoneH;
            tooltip = "Enter the number of points to transfer.";
        };
        class Deposit: RscButton
        {
            idc = 1605;
            text = "Deposit to bank";
            x = 0.38 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.16 * safezoneW;
            h = 0.035 * safezoneH;
            action = "[] execVM 'bulwark\depositPoint.sqf';";
        };
        class Withdraw: RscButton
        {
            idc = 1604;
            text = "Withdraw from bank";
            x = 0.55 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.18 * safezoneW;
            h = 0.035 * safezoneH;
            action = "[] execVM 'bulwark\withdrawPoint.sqf';";
        };
        class SearchLabel: RscText
        {
            idc = 1024;
            text = "Search all items";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.285 * safezoneH + safezoneY;
            w = 0.13 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class Search: RscEdit
        {
            idc = 1401;
            text = "";
            x = 0.25 * safezoneW + safezoneX;
            y = 0.285 * safezoneH + safezoneY;
            w = 0.365 * safezoneW;
            h = 0.04 * safezoneH;
            tooltip = "Search item names across Build, Support and Supplies.";
        };
        class ClearSearch: RscButton
        {
            idc = 1606;
            text = "Clear search";
            x = 0.625 * safezoneW + safezoneX;
            y = 0.285 * safezoneH + safezoneY;
            w = 0.26 * safezoneW;
            h = 0.04 * safezoneH;
            action = "((findDisplay 9998) displayCtrl 1401) ctrlSetText ''; ['list'] call bulwark_fnc_shop;";
        };
        class ItemsLabel: RscText
        {
            idc = 1022;
            text = "Items";
            x = 0.32 * safezoneW + safezoneX;
            y = 0.333 * safezoneH + safezoneY;
            w = 0.325 * safezoneW;
            h = 0.025 * safezoneH;

        };
        class Categories: RscListBox
        {
            idc = 1500;
            text = "";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.365 * safezoneH + safezoneY;
            w = 0.195 * safezoneW;
            h = 0.36 * safezoneH;
            colorBackground[] = {0,0,0,0.45};
        };
        class Items: RscListBox
        {
            idc = 1501;
            text = "";
            x = 0.32 * safezoneW + safezoneX;
            y = 0.365 * safezoneH + safezoneY;
            w = 0.325 * safezoneW;
            h = 0.36 * safezoneH;
            colorBackground[] = {0,0,0,0.45};
            colorTextRight[] = {1,1,1,1};
            colorSelectRight[] = {0,0,0,1};
            colorSelect2Right[] = {0,0,0,1};
        };
        class Preview: RscPicture
        {
            idc = 1200;
            text = "";
            x = 0.66 * safezoneW + safezoneX;
            y = 0.335 * safezoneH + safezoneY;
            w = 0.225 * safezoneW;
            h = 0.135 * safezoneH;
            style = 48 + 2048;
        };
        class Details: RscText
        {
            idc = 1020;
            text = "";
            x = 0.66 * safezoneW + safezoneX;
            y = 0.48 * safezoneH + safezoneY;
            w = 0.225 * safezoneW;
            h = 0.245 * safezoneH;
            style = 16; sizeEx = 0.0185 * safezoneH;
        };
        class Purchase: RscButton
        {
            idc = 1602;
            text = "Select an item";
            x = 0.59 * safezoneW + safezoneX;
            y = 0.74 * safezoneH + safezoneY;
            w = 0.295 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['buy'] call bulwark_fnc_shop;";
        };
        class Feedback: RscText
        {
            idc = 1021;
            text = "";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.735 * safezoneH + safezoneY;
            w = 0.46 * safezoneW;
            h = 0.05 * safezoneH;
            style = 16; sizeEx = 0.020 * safezoneH;
        };
        class RecentLabel: RscText
        {
            idc = 1023;
            text = "Buy again - recent purchases";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.79 * safezoneH + safezoneY;
            w = 0.7 * safezoneW;
            h = 0.025 * safezoneH;

        };
        class Recent0: RscButton
        {
            idc = 1615;
            text = "No recent purchase";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.825 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.045 * safezoneH;
            action = "['buy', '', -1, 0] call bulwark_fnc_recentPurchases;";
        };
        class Recent1: RscButton
        {
            idc = 1616;
            text = "No recent purchase";
            x = 0.375 * safezoneW + safezoneX;
            y = 0.825 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.045 * safezoneH;
            action = "['buy', '', -1, 1] call bulwark_fnc_recentPurchases;";
        };
        class Recent2: RscButton
        {
            idc = 1617;
            text = "No recent purchase";
            x = 0.635 * safezoneW + safezoneX;
            y = 0.825 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.045 * safezoneH;
            action = "['buy', '', -1, 2] call bulwark_fnc_recentPurchases;";
        };
        class DebugLabel: RscText
        {
            idc = 1010;
            text = "Host/admin tools";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.29 * safezoneH + safezoneY;
            w = 0.75 * safezoneW;
            h = 0.04 * safezoneH;

        };
        class KillEnemies: RscButton
        {
            idc = 1611;
            text = "Kill current enemies";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.35 * safezoneH + safezoneY;
            w = 0.36 * safezoneW;
            h = 0.04 * safezoneH;
            action = "[player, 'killEnemies'] remoteExecCall ['bulwark_fnc_requestDebugAction', 2];"; tooltip = "Queued reinforcements and FOBs remain active.";
        };
        class ResetZeus: RscButton
        {
            idc = 1613;
            text = "Reset Zeus";
            x = 0.49 * safezoneW + safezoneX;
            y = 0.35 * safezoneH + safezoneY;
            w = 0.395 * safezoneW;
            h = 0.04 * safezoneH;
            action = "[player, 'resetZeus'] remoteExecCall ['bulwark_fnc_requestDebugAction', 2];"; tooltip = "Close the shop, wait a moment, then press Y.";
        };
        class Specials: RscListBox
        {
            idc = 1510;
            text = "";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.41 * safezoneH + safezoneY;
            w = 0.77 * safezoneW;
            h = 0.25 * safezoneH;
            colorBackground[] = {0,0,0,0.45};
        };
        class ForceSpecial: RscButton
        {
            idc = 1612;
            text = "Force selected special";
            x = 0.115 * safezoneW + safezoneX;
            y = 0.68 * safezoneH + safezoneY;
            w = 0.77 * safezoneW;
            h = 0.04 * safezoneH;
            action = "[player, 'forceSpecial', lbData [1510, lbCurSel 1510]] remoteExecCall ['bulwark_fnc_requestDebugAction', 2];"; tooltip = "Ends the wave and starts the selected special, bypassing normal restrictions.";
        };
    };
};
