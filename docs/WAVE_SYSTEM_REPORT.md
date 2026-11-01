# Wave system: detailed combined report

Updated 1 November 2026. Covers normal gameplay using current scripts. Defaults: RU vs PL faction mode, vehicle start wave 5, hostile multiplier 2, team multiplier 0.5. Lobby overrides change these results. Exact configured class arrays appear in the appendix.

## 1. Wave composition

Every wave combines ordinary infantry, independent regular vehicle rolls, and special/modifier selections. These layers can stack. There is no shared vehicle budget. Active enemy capacity limits simultaneous manpower rather than the total requested for a wave.

Selection is not a deployment guarantee: missing addons, invalid classes, unsuitable positions, transport destruction or cancellation can prevent a requested threat from appearing.

## 2. Ordinary infantry calculation

```text
H = human player count (excluding headless clients)
T = HOSTILE_TEAM_MULTIPLIER / 100
M = HOSTILE_MULTIPLIER / 100
Player factor = max(1, H * T)
For waves 1–2 only, M = 1
Infantry count = floor(wave * M * Player factor)
```

| Humans | Default player factor | Wave 2 | Wave 6 | Wave 10 |
| --- | ---: | ---: | ---: | ---: |
| 1–2 | 1 | 2 | 12 | 20 |
| 3 | 1.5 | 3 | 18 | 30 |
| 4 | 2 | 4 | 24 | 40 |
| 5 | 2.5 | 5 | 30 | 50 |
| 6 | 3 | 6 | 36 | 60 |
| 7 | 3.5 | 7 | 42 | 70 |
| 8 | 4 | 8 | 48 | 80 |
| 9 | 4.5 | 9 | 54 | 90 |

Fractional player scaling is preserved until the final infantry count is rounded down. At defaults, each player above two adds half a player factor: wave 6 has 12/18/24/30 ordinary infantry for 2/3/4/5 humans. This raises formerly rounded-down odd-player totals while preserving even-player totals. Vehicle crews, transported troops and special reinforcements are additional to this total.

## 3. Infantry progression

| Waves | Class pool | Selected infantry kill-point multiplier |
| --- | --- | ---: |
| 1–6 | Level 1 | 0.75 |
| 7–10 | Level 1 + Level 2 | 1.00 |
| 11–14 | Level 2 | 1.00 |
| 15–18 | Level 2 + Level 3 | 1.50 |
| 19+ | Level 3 | 1.50 |

Units are randomly selected from class arrays. Combining arrays does not enforce an equal split: larger lists contribute more entries, and a class present in both lists receives extra weight.

### RU vs PL pools

| Tier | Configured enemy types |
| --- | --- |
| Level 1: 4 entries | CUP squad leader, Saiga-equipped soldier, rifleman, MSV VSR-93 medic. |
| Level 2: 10 entries | AA specialist, team leader, assistant automatic rifleman, explosives specialist, machine gunner, medic, light rifleman, AT specialist, squad leader and grenadier. Mostly CUP MSV VSR-93 equipment. |
| Level 3: 19 entries | Russian recon medic, JTAC, marksman, light AT, grenadier and automatic rifleman; CUP Ratnik leaders, rifleman, medic, grenadier, machine gunner, heavy AT, light AT and AA; VDV sniper and KSVK sniper; additional Russian marksman and grenadier. |

The Level 1 medic also occurs in Level 2 and therefore receives extra weight in their combined pool. A JTAC unit does not itself trigger the separately selected airstrike special.

### Legacy pools

| Tier | Group configuration sources | General types |
| --- | --- | --- |
| Level 1 | IND_C_F / Infantry / BanditCombatGroup | Syndikat bandit infantry |
| Level 2 | OPF_F / Infantry / OIA_InfSquad, OIA_InfTeam_AT, OIA_InfTeam_AA | CSAT regular infantry with AT and AA specialists |
| Level 3 | OPF_F / SpecOps / OI_ViperTeam; Infantry / O_InfTeam_AT_Heavy, OIA_InfAssault | Viper special forces, heavy AT and assault troops |

These lists are assembled from loaded game configuration; fixed class arrays are not used for Legacy infantry.

### Equipment overrides and skill

Pistols-only defaults to waves 1–3 inclusive: ordinary infantry weapons are removed and replaced with a P07. Random weapons defaults to off; enabling it replaces primary weapons from the mission weapon pool. A class's normal equipment is therefore not always its actual loadout.

| Waves | Ordinary infantry base skill value |
| --- | ---: |
| 1–4 | 0.05 |
| 5–9 | 0.075 |
| 10–14 | 0.10 |
| 15–19 | 0.15 |
| 20–24 | 0.40 |
| 25–29 | 0.50 |
| 30+ | 1.00 |

Individual skill assignments use this value; it is not a literal hit percentage. Vehicle crews and special enemies may use different settings.

## 4. Regular vehicle chances

Let S be the vehicle start setting and d be waves since that particular family unlocked. Before unlock its chance is zero.

| Family | Unlock | Default wave | Chance after unlock | Maximum |
| --- | --- | ---: | --- | ---: |
| Armed cars | S | 5 | 20 + 4*d percent | 80% |
| Transport trucks | S+2 | 7 | 20 + 3*d percent | 65% |
| Transport helicopters | S+3 | 8 | 15 + 3*d percent | 60% |
| Combat helicopters | S+5 | 10 | 15 + 3*d percent | 60% |
| Armour | S+7 | 12 | 15 + 3*d percent | 65% |

Each family has its own independent roll per wave. Success requests a batch; it is not a separate roll for each vehicle. Changing S shifts all unlocks. Never (9999) disables regular vehicles.

| Wave | Cars | Trucks | Transport helis | Combat helis | Armour |
| --- | ---: | ---: | ---: | ---: | ---: |
| 5 | 20% | 0% | 0% | 0% | 0% |
| 6 | 24% | 0% | 0% | 0% | 0% |
| 7 | 28% | 20% | 0% | 0% | 0% |
| 8 | 32% | 23% | 15% | 0% | 0% |
| 10 | 40% | 29% | 21% | 15% | 0% |
| 12 | 48% | 35% | 27% | 21% | 15% |
| 20 | 80% | 59% | 51% | 45% | 39% |

At wave 7, both cars and trucks pass with probability 0.28*0.20 = 5.6%. At least one family passes with probability 1-(0.72*0.80) = 42.4%. Special selections are additional.

## 5. Vehicle quantities after successful rolls

Here d is waves since the corresponding family unlocked. U(a,b) means a uniform random integer from a through b inclusive.

| Family | Requested batch size |
| --- | --- |
| Cars | 1 + floor(d/10) + U(0, floor(H/2)) |
| Combat helicopters | 1 + floor(d/10) + U(0, floor(H/3)) |
| Armour | 1 + floor(d/20) + U(0, floor(H/4)) |
| Transport trucks | U(1, 1 + floor(d/9)) |
| Transport helicopters | U(1, 1 + floor(d/10)) |

Example: four players at wave 6 have a 24% chance of a car batch containing 1–3 cars. The base starts at one, but player bonuses apply immediately. Transport cargo adds infantry beyond the ordinary count.

## 6. Vehicle model pools

A successful family roll selects each model randomly from that family's valid classes. All valid models are available immediately when the family unlocks; there are no later model-specific tiers.

### RU vs PL

| Family | Types represented |
| --- | --- |
| Armed cars | UAZ Metis/MG/AA; Vodnik KPVT/BPPU/PK/AGS; Ural ZU-23; open Ural; Tigr; BRDM-2 variants; 82 mm mortar; open UAZ/SPG-9 candidates; PTS amphibious transport; Gaz-66 ZU-23. |
| Armour | T-72, T-90, BMP-2, BMP-3, BRDM-2, BTR-80/BTR-80A/BTR-90, Tunguska, D-30, 2S3, 2S1, T-14, T-15, T-80UM, T-90SM, BMD-4 and Sprut. |
| Combat helicopters | CUP Mi-8, Mi-24V dynamic loadout, Ka-60, Ka-52, Ka-50; RHS Mi-28N. |
| Transport truck | RHS_Ural_Open_MSV_01 |
| Transport helicopter | RHS_Mi8mt_Cargo_vvsc |

Category names are script labels. Armed cars includes transports, static mortar and powerful weapons; armour includes artillery and air defence. Combat helicopter candidates include utility/transport and dedicated attack models. Actual weapons depend on addon configuration.

The configured CUP_0_UAZ_Open_RU, CUP_0_UAZ_SPG9_RU and CUP_0_BTR80_GREEN_RU use digit zero rather than letter O. They are skipped unless those exact classes exist. The appendix records candidates, not confirmed runtime availability.

### Legacy vehicles

Cars are dynamically collected from Car vehicleClass entries with turret weapons. Armour uses Armored entries excluding O_MBT_02_arty_F. Both list builders currently use exitWith when a match is found, so each stops at the first matching entry rather than gathering every match. Exact results depend on configuration order.

The helicopter pool contains PSZ Mi-17/Mi-24 variants; CUP Ka-52/Ka-50/UH-1H variants; armed vanilla light helicopter; RHS Ka-52/Ka-60/Mi-24/Mi-28/UH-1H candidates. Some are base classes; class-existence filtering alone does not prove every entry is suitable for gameplay.

## 7. Main special selection

```text
Success if random(100) < 35 + wave
Effective chance = min(100, 35 + wave) percent
```

Examples: wave 5 = 40%, wave 6 = 41%, wave 10 = 45%, wave 20 = 55%, wave 30 = 65%, wave 65+ = 100%. Waves 1–4 have no main-special branch, so the roll adds nothing.

Success selects one eligible entry with equal weight per remaining entry:

| Pool | Used for | Entries |
| --- | --- | --- |
| Beginner | Main special, waves 5–6 | Civilians, fog, thunderstorm |
| Broad | Main special, waves 7–9 | Civilians, suicide wave, mortar, Grad, mine-clearing drones, defectors, night, fog, thunderstorm, artillery, paradrop, airstrike, FOB, convoy |
| Primary combat | Main special, wave 10+ | Civilians, suicide wave, mortar, mine-clearing drones, defectors, paradrop, airstrike, convoy, FOB, Officer Hunt, FPV Operator |
| Standard modifiers | Extra modifier slots | Fog, night, thunderstorm, artillery, Grad, paradrop, mortar, airstrike, convoy |
| Guaranteed addition | Every wave from 17 | Mortar, paradrop, convoy |

Specials and modifiers ultimately enter the same list and dispatch their scripts. The names describe selection slots, not separate spawning systems.

## 8. Modifier schedule

| Waves | On successful main roll | Independent additions |
| --- | --- | --- |
| 1–4 | Nothing | Nothing |
| 5–9 | One main selection | Nothing |
| 10–13 | Main selection plus 50% modifier roll | Nothing |
| 14–16 | Main selection plus 75% modifier roll | Nothing |
| 17–20 | Main selection plus independent 75% and 25% modifier rolls | One guaranteed-addition draw |
| 21+ | Main selection plus min(100,3*wave)% and min(100,2*wave)% modifier rolls | Guaranteed-addition draw; if main roll fails, separate 25% modifier roll |

Modifier chances in the middle column are conditional on main success. At wave 10, the overall extra-modifier chance is 45%*50% = 22.5%.

At wave 17: guaranteed addition, 52% main-special chance, and conditional 75%/25% rolls allow up to four effects, plus regular vehicles and infantry. The first late modifier roll becomes certain at wave 34; the second at wave 50; main success becomes certain at wave 65.

The guaranteed draw occurs before the main selection. An empty eligible pool adds nothing, including when all its entries are disabled by vehicle settings.

### Eligibility, cooldowns and repeats

- Fog, night and thunderstorm cannot each duplicate themselves. Different weather/time effects can coexist.
- FOB, Officer Hunt and FPV Operator exclude one another and check active/setup state.
- FOB minimum is wave 7. Default two-intervening-wave cooldown means wave 7 success permits another from wave 10.
- Officer Hunt and FPV minimum is wave 10, with default two-intervening-wave cooldowns. FPV also requires addon availability and its enabled setting.
- Other combat effects may repeat: duplicate convoy, mortar, paradrop or bombardment selections can add pressure.
- Filtering happens before random selection; an empty pool produces no effect.

### Lobby settings and debug

Special Waves Off clears the normal special/modifier list, including guaranteed additions. It does not turn off regular vehicles.

Before the configured vehicle start wave, or with Never selected, convoy, paradrop, airstrike, mortar and mine-clearing drone specials are excluded; FPV also requires vehicle eligibility. Special eligibility uses the general start setting, not the staggered regular-family unlocks. FOB remains an infantry objective.

Debug-forced specials replace normal selection and suppress regular vehicle rolls. The report's probabilities describe normal play.

## 9. Extra enemies, special vehicles and hazards

| Effect | Requested content or calculation |
| --- | --- |
| Convoy | max(1, floor(wave/3)) open Ural trucks per selection |
| Regular truck | Open Ural with crew and requested ten-person RHS VDV squad, trimmed to cargo capacity |
| Regular transport helicopter | RHS Mi-8 cargo helicopter with troop-delivery script |
| Paradrop | RHS_TU95MS_vvs_tambov carrier; ceil((1 + random(wave/4))*5) VDV troops requested |
| Airstrike | CUP_O_Su25_Dyn_RU; 1 + floor(random(wave/5)) strike flights requested |
| Mortar | O_Mortar_01_F, CSAT Mk6 82 mm mortar and crew |
| Civilians | Up to 20 civilians from public civilian person classes, using available building positions |
| Suicide wave | Ordinary infantry replaced with suicide pool; weapons removed. RU class is CUP_O_RU_Survivor_MSV_VSR93; Legacy uses bandits. |
| FOB | Level 3 infantry, or defector infantry if applicable |
| Officer Hunt | Level 2/defector infantry and separately configured officer |
| FPV Operator | Level 2/defector infantry and addon-provided FPV drones |
| Defectors | Replacement infantry and combat vehicle pools, described below |
| Fog/night/thunderstorm | Visibility, time and weather effects; thunderstorm also includes ground strikes |
| Artillery/Grad | Scripted bombardment producers |
| Mine-clearing drone wave | Drone hazard scripts and drone additions during infantry spawning |

Truck troops include sergeant, medic, automatic rifleman, riflemen and light AT. Paradrop candidates are sergeant, medic, automatic rifleman, RPK automatic rifleman, rifleman and light AT.

A special convoy at wave 7 requests two trucks and can stack with regular car and truck rolls. A special paradrop can appear before regular transport helicopters unlock. FOB selection from wave 7 can introduce Level 3 infantry before ordinary waves reach that tier.

## 10. Defector pools

In RU vs PL mode, the defector flag replaces ordinary infantry and regular car/armour/helicopter lists and switches their side to resistance:

| Category | Replacement types |
| --- | --- |
| Infantry | NATO recon team leader, medic, JTAC, marksman, sniper, patrol team leader, patrol automatic rifleman, recon sharpshooter, patrol medic |
| Cars | Hunter GMG, Hunter HMG, CUP M1025 M240, armed Prowler |
| Armour | CUP M1A2 SEP, Marshall, tracked NATO APC, Slammer UP, CUP Challenger 2 |
| Helicopters | Ghost Hawk, Huron, dynamic-loadout NATO light helicopter |

This overrides the ordinary infantry tier. Fixed-class transports and paradrops do not automatically change faction with regular vehicles. Legacy defectors use the dynamically assembled NATO infantry pool, Legacy car/armour lists and the configured defector helicopter list.

## 11. Simultaneous enemy limit

```text
Full limit = min(120, 30 + 4*H)
Ordinary infantry admission limit = floor(0.8 * Full limit)
```

| Humans | Full limit | Ordinary admission limit |
| --- | ---: | ---: |
| 1 | 34 | 27 |
| 4 | 46 | 36 |
| 8 | 62 | 49 |
| 16 | 94 | 75 |

The gateway counts living east/resistance units and reserved spawn capacity. Vehicle requests reserve crew capacity; group requests reserve their members. Requests generally wait for room, subject to cancellation and deadlines.

This is not a total-wave limit or vehicle budget. Several families may be selected even if they cannot all deploy immediately. Civilians and projectiles are outside hostile manpower accounting.

## 12. Remaining difficulty steps

- Wave 3: default hostile multiplier changes from 1 to 2.
- Wave 4: default pistol restriction ends.
- Wave 5: skill increases, cars unlock, beginner specials begin.
- Wave 7: Level 2 enters, broad specials start, trucks unlock; FOB may introduce Level 3 troops.
- Waves 8/10/12: further regular vehicle families unlock.
- Wave 10: conditional modifiers, Officer Hunt and FPV become possible.
- Waves 15/19: Level 3 enters and then takes over ordinary infantry.
- Wave 17: guaranteed combat addition begins; up to four selected effects.
- Waves 20/30: substantial ordinary infantry skill increases.

Staggered unlocks reduce the former wave-6 pile-up. Full model pools, independent rolls, player bonuses and special reinforcements still permit large differences between consecutive waves.

## 13. Source references

- [Wave selection](../bulwark/functions/fn_startWave.sqf)
- [Infantry totals and regular vehicle calculations](../hostiles/createWave.sqf)
- [Faction assignments](../editMe.sqf) and [lobby defaults](../description.ext)
- [Class pools](../hostiles/lists.sqf)
- [Infantry equipment and skill](../hostiles/spawnSquad.sqf)
- [Capacity gateway](../bulwark/functions/fn_spawnLimited.sqf)
- [Truck](../hostiles/spawnUaz.sqf), [transport helicopter](../hostiles/KillTeam.sqf), [paradrop](../hostiles/ParaDropNew.sqf), [airstrike](../hostiles/airStrike.sqf)

## Appendix: exact fixed class pools

Copied from the current hostiles/lists.sqf. These are configured candidates; actual availability depends on loaded addons. Legacy dynamic pools are described above.

```sqf
List_RUSSIA_LVL_1 = ["CUP_O_RU_Soldier_SL",
"CUP_O_RU_Soldier_Saiga",
"CUP_O_RU_Soldier",
"CUP_O_RU_Soldier_Medic_MSV_VSR93"];
```

```sqf
List_RUSSIA_LVL_2 = ["CUP_O_RU_Soldier_AA",
"CUP_O_RU_Soldier_TL_MSV_VSR93",
"CUP_O_RU_Soldier_AAR_MSV_VSR93",
"CUP_O_RU_Soldier_EXP_MSV_VSR93",
"CUP_O_RU_Soldier_MG_MSV_VSR93",
"CUP_O_RU_Soldier_Medic_MSV_VSR93",
"CUP_O_RU_Soldier_Lite_MSV_VSR93",
"CUP_O_RU_Soldier_AT_MSV_VSR93",
"CUP_O_RU_Soldier_SL_MSV_VSR93",
"CUP_O_RU_Soldier_GL_MSV_VSR93"];
```

```sqf
List_RUSSIA_LVL_3 = ["O_R_recon_medic_F",
"O_R_recon_JTAC_F",
"O_R_recon_M_F",
"O_R_recon_LAT_F",
"O_R_recon_GL_F",
"O_R_recon_AR_F",
"CUP_O_RU_Soldier_SL_Ratnik_Summer",
"CUP_O_RU_Soldier_TL_Ratnik_Summer",
"CUP_O_RU_Soldier_GL_Ratnik_Summer",
"CUP_O_RU_Soldier_MG_Ratnik_Summer",
"CUP_O_RU_Soldier_AHAT_Ratnik_Summer",
"CUP_O_RU_Sniper_VDV",
"CUP_O_RU_Sniper_KSVK_VDV",
"CUP_O_RU_Soldier_LAT_Ratnik_Summer",
"CUP_O_RU_Soldier_AA_Ratnik_Summer",
"CUP_O_RUS_Soldier_Marksman",
"CUP_O_RUS_Soldier_GL",
"CUP_O_RU_Soldier_Ratnik_Summer",
"CUP_O_RU_Soldier_Medic_Ratnik_Summer"];
```

```sqf
List_RUSSIA_CARS = ["CUP_O_UAZ_METIS_RU",
"CUP_O_UAZ_MG_RU",
"CUP_O_GAZ_Vodnik_KPVT_RU",
"CUP_O_GAZ_Vodnik_BPPU_RU",
"CUP_O_GAZ_Vodnik_PK_RU",
"CUP_O_GAZ_Vodnik_AGS_RU",
"CUP_O_UAZ_AA_RU",
"CUP_O_URAL_ZU23_RU",
"RHS_Ural_Open_MSV_01",
"rhs_tigr_m_3camo_msv",
"rhsgref_BRDM2_msv",
"rhs_2b14_82mm_msv",
"CUP_0_UAZ_Open_RU",
"CUP_0_UAZ_SPG9_RU",
"rhs_pts_vmf",
"rhs_gaz66_zu23_vmf",
"rhsgref_BRDM2_umf",
"rhs_tigr_sts_umv"];
```

```sqf
List_RUSSIA_ARMOR = ["CUP_O_T72_RU",
"CUP_O_T90_RU",
"CUP_O_BMP2_RU",
"CUP_O_BMP3_RU",
"CUP_O_BRDM2_RU",
"CUP_O_BTR80_CAMO_RU",
"CUP_O_BTR90_RU",
"CUP_O_2S6M_RU",
"rhs_D30_vmf",
"rhs_btr80a_msv",
"CUP_0_BTR80_GREEN_RU",
"rhs_2s3_at_tv",
"rhs_2s1_at_tv",
"rhs_t14_tv",
"rhs_t15_tv",
"rhs_t80um",
"rhs_t90sm_tv",
"rhs_bmd4_vdv",
"rhs_sprut_vdv"];
```

```sqf
LIST_RUSSIA_HELI = ["CUP_O_Mi8_RU",
"CUP_O_RU_Mi24_V_Dynamic_RU",
"CUP_O_Ka60_Grey_RU",
"CUP_O_Ka52_RU",
"CUP_O_Ka50_DL_RU",
"rhs_mi28n_vvsc"];
```

```sqf
List_SUICIDE_RUSSIA = ["CUP_O_RU_Survivor_MSV_VSR93"];
```

```sqf
List_DEFECTOR_CARS = [
  "B_MRAP_01_gmg_F",
  "B_MRAP_01_hmg_F",
  "CUP_B_nM1025_M240_NATO",
  "B_LSV_01_armed_F"
];
```

```sqf
List_DEFECTOR_ARMOR = [
  "CUP_B_M1A2SEP_NATO",
  "B_APC_Wheeled_01_cannon_F",
  "B_APC_Tracked_01_rcws_F",
  "B_MBT_01_TUSK_F",
  "CUP_B_Challenger2_NATO"
];
```

```sqf
List_DEFECTOR_HELI = [
  "B_Heli_Transport_01_F",
  "B_Heli_Transport_03_F",
  "B_Heli_Light_01_dynamicLoadout_F"
];
```

```sqf
List_DEFECTOR_INF = [
  "B_recon_TL_F",
  "B_recon_medic_F",
  "B_recon_JTAC_F",
  "B_recon_M_F",
  "B_sniper_F",
  "B_Patrol_Soldier_TL_F",
  "B_Patrol_Soldier_AR_F",
  "B_recon_Sharpshooter_F",
  "B_Patrol_Medic_F"
];
```

### Legacy helicopter candidates

- `PSZ_PL_Mi17_1W`
- `PSZ_PL20_Mi17_1W_UB32`
- `PSZ_PL20_Mi17_1W_PKT`
- `PSZ_Mi24D`
- `PSZ_Mi24V`
- `CUP_O_Ka52_GreyCamo_RU`
- `B_Heli_Light_01_armed_F`
- `CUP_O_Ka50_DL_SLA`
- `CUP_I_UH1H_armed_TK_GUE`
- `CUP_I_UH1H_slick_TK_GUE`
- `RHS_Ka52_base`
- `rhs_ka60_grey`
- `rhsgref_mi24g_CAS`
- `rhsgref_mi24g_UPK23`
- `rhsgref_mi24g_FAB`
- `rhs_mi28_base`
- `rhs_uh1h_hidf_gunship`
