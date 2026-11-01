# System fal: szczegółowy raport zbiorczy

> Domyślnie działa teraz system punktów pojazdów. Sekcje 4–6 opisują zachowany tryb zgodności. Zasady implementacji: [VEHICLE_TICKETS.md](VEHICLE_TICKETS.md); zdarzenia specjalne pozostają osobne.

Aktualizacja: 1 listopada 2026 r. Raport opisuje zwykłą rozgrywkę według aktualnych skryptów. Ustawienia domyślne: tryb frakcji RU vs PL, pojazdy od fali 5, mnożnik przeciwników 2, mnożnik zespołu 0.5. Zmiany parametrów w lobby wpływają na wyniki. Dokładne tablice klas znajdują się w aneksie.

## 1. Skład fali

Każda fala łączy zwykłą piechotę, niezależne losowania standardowych pojazdów oraz losowania zdarzeń specjalnych i modyfikatorów. Elementy te mogą występować jednocześnie. Nie ma wspólnego budżetu pojazdów. Limit aktywnych przeciwników ogranicza liczbę żołnierzy obecnych jednocześnie, a nie łączną liczbę jednostek zamówionych dla całej fali.

Wylosowanie zagrożenia nie gwarantuje jego pojawienia się. Brak dodatków, nieprawidłowe klasy, nieodpowiednie miejsce, zniszczenie transportu lub anulowanie działania mogą uniemożliwić jego utworzenie.

## 2. Obliczanie liczby zwykłej piechoty

```text
H = liczba graczy ludzkich (bez klientów headless)
T = HOSTILE_TEAM_MULTIPLIER / 100
M = HOSTILE_MULTIPLIER / 100
Współczynnik graczy = max(1, H * T)
Tylko dla fal 1–2: M = 1
Liczba piechoty = floor(numer fali * M * Współczynnik graczy)
```

| Gracze | Domyślny współczynnik graczy | Fala 2 | Fala 6 | Fala 10 |
| --- | ---: | ---: | ---: | ---: |
| 1–2 | 1 | 2 | 12 | 20 |
| 3 | 1.5 | 3 | 18 | 30 |
| 4 | 2 | 4 | 24 | 40 |
| 5 | 2.5 | 5 | 30 | 50 |
| 6 | 3 | 6 | 36 | 60 |
| 7 | 3.5 | 7 | 42 | 70 |
| 8 | 4 | 8 | 48 | 80 |
| 9 | 4.5 | 9 | 54 | 90 |

Ułamkowy współczynnik graczy jest zachowany; w dół zaokrąglana jest dopiero końcowa liczba piechoty. Domyślnie każdy gracz powyżej dwóch dodaje 0.5 do współczynnika: fala 6 daje 12/18/24/30 jednostek dla 2/3/4/5 graczy. Liczebność dla nieparzystych grup wzrasta, a dla parzystych pozostaje bez zmian. Załogi pojazdów, przewożeni żołnierze i specjalne posiłki są dodawane poza tą liczbą.

## 3. Rozwój piechoty

| Fale | Pula klas | Wybrany mnożnik punktów za zabicie piechoty |
| --- | --- | ---: |
| 1–6 | Poziom 1 | 0.75 |
| 7–10 | Poziom 1 + Poziom 2 | 1.00 |
| 11–14 | Poziom 2 | 1.00 |
| 15–18 | Poziom 2 + Poziom 3 | 1.50 |
| 19+ | Poziom 3 | 1.50 |

Jednostki są wybierane losowo z tablic klas. Połączenie tablic nie zapewnia równego podziału: większa lista wnosi więcej wpisów, a klasa obecna na obu listach otrzymuje większą wagę.

### Pule RU vs PL

| Poziom | Skonfigurowane typy przeciwników |
| --- | --- |
| Poziom 1: 4 wpisy | Dowódca drużyny CUP, żołnierz z Saigą, strzelec, sanitariusz MSV VSR-93. |
| Poziom 2: 10 wpisów | Specjalista przeciwlotniczy, dowódca zespołu, pomocnik strzelca broni automatycznej, saper/specjalista materiałów wybuchowych, kaemista, sanitariusz, lekki strzelec, specjalista przeciwpancerny, dowódca drużyny i grenadier. Głównie wyposażenie CUP MSV VSR-93. |
| Poziom 3: 19 wpisów | Rosyjskie rozpoznanie: sanitariusz, JTAC, strzelec wyborowy, lekki specjalista ppanc., grenadier i strzelec broni automatycznej; CUP Ratnik: dowódcy, strzelec, sanitariusz, grenadier, kaemista, ciężki i lekki specjalista ppanc. oraz specjalista plot.; snajper VDV i snajper z KSVK; dodatkowy rosyjski strzelec wyborowy i grenadier. |

Sanitariusz z poziomu 1 występuje też na poziomie 2, dlatego w połączonej puli ma większą wagę. Sama obecność jednostki JTAC nie uruchamia nalotu, który jest osobno losowanym zdarzeniem.

### Pule Legacy

| Poziom | Źródła w konfiguracji grup | Ogólny skład |
| --- | --- | --- |
| Poziom 1 | IND_C_F / Infantry / BanditCombatGroup | Piechota bandytów Syndikat |
| Poziom 2 | OPF_F / Infantry / OIA_InfSquad, OIA_InfTeam_AT, OIA_InfTeam_AA | Regularna piechota CSAT ze specjalistami ppanc. i plot. |
| Poziom 3 | OPF_F / SpecOps / OI_ViperTeam; Infantry / O_InfTeam_AT_Heavy, OIA_InfAssault | Siły specjalne Viper, ciężka broń ppanc. i oddziały szturmowe |

Listy są budowane z wczytanej konfiguracji gry. Piechota Legacy nie korzysta ze stałych tablic klas.

### Zastępowanie wyposażenia i umiejętności

Domyślne ograniczenie do pistoletów obejmuje fale 1–3 włącznie: broń zwykłej piechoty jest usuwana i zastępowana P07. Losowe uzbrojenie jest domyślnie wyłączone; jego włączenie zastępuje broń główną losową bronią z puli misji. Domyślne wyposażenie klasy nie zawsze jest więc faktycznym uzbrojeniem jednostki.

| Fale | Bazowa wartość umiejętności zwykłej piechoty |
| --- | ---: |
| 1–4 | 0.05 |
| 5–9 | 0.075 |
| 10–14 | 0.10 |
| 15–19 | 0.15 |
| 20–24 | 0.40 |
| 25–29 | 0.50 |
| 30+ | 1.00 |

Ta wartość jest używana przy ustawianiu poszczególnych umiejętności; nie oznacza dosłownego procentu trafień. Załogi pojazdów i przeciwnicy specjalni mogą mieć inne ustawienia.

## 4. Szanse standardowych pojazdów

S oznacza ustawioną falę początkową pojazdów, a d liczbę fal od odblokowania danej kategorii. Przed odblokowaniem szansa wynosi zero.

| Kategoria | Odblokowanie | Domyślna fala | Szansa po odblokowaniu | Maksimum |
| --- | --- | ---: | --- | ---: |
| Uzbrojone samochody | S | 5 | 20 + 4*d procent | 80% |
| Ciężarówki transportowe | S+2 | 7 | 20 + 3*d procent | 65% |
| Śmigłowce transportowe | S+3 | 8 | 15 + 3*d procent | 60% |
| Śmigłowce bojowe | S+5 | 10 | 15 + 3*d procent | 60% |
| Pojazdy pancerne | S+7 | 12 | 15 + 3*d procent | 65% |

Każda kategoria ma własne, niezależne losowanie na falę. Sukces zamawia grupę pojazdów; nie jest to osobne losowanie dla każdego pojazdu. Zmiana S przesuwa wszystkie odblokowania. Ustawienie Never (9999) wyłącza standardowe pojazdy.

| Fala | Samochody | Ciężarówki | Śmigłowce transportowe | Śmigłowce bojowe | Pancerne |
| --- | ---: | ---: | ---: | ---: | ---: |
| 5 | 20% | 0% | 0% | 0% | 0% |
| 6 | 24% | 0% | 0% | 0% | 0% |
| 7 | 28% | 20% | 0% | 0% | 0% |
| 8 | 32% | 23% | 15% | 0% | 0% |
| 10 | 40% | 29% | 21% | 15% | 0% |
| 12 | 48% | 35% | 27% | 21% | 15% |
| 20 | 80% | 59% | 51% | 45% | 39% |

W fali 7 prawdopodobieństwo jednoczesnego sukcesu samochodów i ciężarówek wynosi 0.28*0.20 = 5.6%. Szansa sukcesu przynajmniej jednej kategorii to 1-(0.72*0.80) = 42.4%. Zdarzenia specjalne są losowane dodatkowo.

## 5. Liczba pojazdów po udanym losowaniu

d nadal oznacza liczbę fal od odblokowania odpowiedniej kategorii. U(a,b) oznacza równomiernie losowaną liczbę całkowitą od a do b włącznie.

| Kategoria | Zamawiana liczba pojazdów |
| --- | --- |
| Samochody | 1 + floor(d/10) + U(0, floor(H/2)) |
| Śmigłowce bojowe | 1 + floor(d/10) + U(0, floor(H/3)) |
| Pojazdy pancerne | 1 + floor(d/20) + U(0, floor(H/4)) |
| Ciężarówki transportowe | U(1, 1 + floor(d/9)) |
| Śmigłowce transportowe | U(1, 1 + floor(d/10)) |

Przykład: czterech graczy w fali 6 ma 24% szans na grupę 1–3 samochodów. Wartość bazowa zaczyna się od jednego, ale premia za graczy obowiązuje od razu. Żołnierze w transportach zwiększają liczbę piechoty poza zwykłym limitem liczebności fali.

## 6. Pule modeli pojazdów

Po udanym losowaniu kategorii każdy model jest losowany z jej prawidłowych klas. Wszystkie prawidłowe modele są dostępne od razu po odblokowaniu kategorii; nie ma późniejszych progów dla konkretnych modeli.

### RU vs PL

| Kategoria | Dostępne typy |
| --- | --- |
| Uzbrojone samochody | UAZ Metis/MG/AA; Vodnik KPVT/BPPU/PK/AGS; Ural ZU-23; otwarty Ural; Tigr; warianty BRDM-2; moździerz 82 mm; wpisy otwartego UAZ-a i UAZ-a SPG-9; transporter amfibijny PTS; Gaz-66 ZU-23. |
| Pojazdy pancerne | T-72, T-90, BMP-2, BMP-3, BRDM-2, BTR-80/BTR-80A/BTR-90, Tunguska, D-30, 2S3, 2S1, T-14, T-15, T-80UM, T-90SM, BMD-4 i Sprut. |
| Śmigłowce bojowe | CUP Mi-8, Mi-24V z dynamicznym uzbrojeniem, Ka-60, Ka-52, Ka-50; RHS Mi-28N. |
| Ciężarówka transportowa | RHS_Ural_Open_MSV_01 |
| Śmigłowiec transportowy | RHS_Mi8mt_Cargo_vvsc |

Nazwy kategorii są etykietami skryptów. Uzbrojone samochody obejmują transporty, stacjonarny moździerz i silne uzbrojenie; pojazdy pancerne obejmują artylerię i obronę przeciwlotniczą. Pula śmigłowców bojowych zawiera zarówno modele transportowe/wielozadaniowe, jak i wyspecjalizowane śmigłowce szturmowe. Faktyczne uzbrojenie zależy od konfiguracji dodatku.

Wpisy CUP_0_UAZ_Open_RU, CUP_0_UAZ_SPG9_RU oraz CUP_0_BTR80_GREEN_RU zawierają cyfrę zero zamiast litery O. Są pomijane, jeśli dokładnie takie klasy nie istnieją. Aneks przedstawia skonfigurowane wpisy, a nie potwierdzoną dostępność podczas działania gry.

### Pojazdy Legacy

Samochody są zbierane dynamicznie z wpisów vehicleClass równych Car, z uzbrojeniem wieżyczki. Pojazdy pancerne pochodzą z wpisów Armored, z wyłączeniem O_MBT_02_arty_F. Oba skrypty budujące listy używają obecnie exitWith po znalezieniu dopasowania, więc zatrzymują się na pierwszym pasującym wpisie zamiast zebrać wszystkie. Wynik zależy od kolejności konfiguracji.

Pula śmigłowców obejmuje warianty PSZ Mi-17/Mi-24; CUP Ka-52/Ka-50/UH-1H; uzbrojony lekki śmigłowiec z podstawowej gry; wpisy RHS Ka-52/Ka-60/Mi-24/Mi-28/UH-1H. Niektóre są klasami bazowymi; samo sprawdzenie istnienia klasy nie potwierdza przydatności każdego wpisu w rozgrywce.

## 7. Losowanie głównego zdarzenia specjalnego

```text
Sukces, gdy random(100) < 35 + numer fali
Efektywna szansa = min(100, 35 + numer fali) procent
```

Przykłady: fala 5 = 40%, fala 6 = 41%, fala 10 = 45%, fala 20 = 55%, fala 30 = 65%, fala 65+ = 100%. Fale 1–4 nie mają gałęzi wyboru głównego zdarzenia, więc wynik losowania niczego nie dodaje.

Po sukcesie wybierany jest jeden dozwolony wpis, z równą wagą dla każdego pozostałego wpisu:

| Pula | Zastosowanie | Zawartość |
| --- | --- | --- |
| Początkowa | Główne zdarzenie, fale 5–6 | Cywile, mgła, burza |
| Szeroka | Główne zdarzenie, fale 7–9 | Cywile, fala samobójców, moździerz, Grad, drony rozminowujące, dezerterzy, noc, mgła, burza, artyleria, desant spadochronowy, nalot, FOB, konwój |
| Główna bojowa | Główne zdarzenie, fala 10+ | Cywile, fala samobójców, moździerz, drony rozminowujące, dezerterzy, desant spadochronowy, nalot, konwój, FOB, polowanie na oficera, operator FPV |
| Standardowe modyfikatory | Dodatkowe losowania modyfikatorów | Mgła, noc, burza, artyleria, Grad, desant spadochronowy, moździerz, nalot, konwój |
| Gwarantowany dodatek | Każda fala od 17 | Moździerz, desant spadochronowy, konwój |

Zdarzenia specjalne i modyfikatory trafiają ostatecznie na tę samą listę i uruchamiają swoje skrypty. Nazwy opisują miejsca w schemacie losowania, a nie oddzielne systemy tworzenia jednostek.

## 8. Harmonogram modyfikatorów

| Fale | Po sukcesie głównego losowania | Niezależne dodatki |
| --- | --- | --- |
| 1–4 | Nic | Nic |
| 5–9 | Jeden główny wybór | Nic |
| 10–13 | Główny wybór i 50% szans na modyfikator | Nic |
| 14–16 | Główny wybór i 75% szans na modyfikator | Nic |
| 17–20 | Główny wybór i niezależne losowania modyfikatorów 75% oraz 25% | Jedno losowanie gwarantowanego dodatku |
| 21+ | Główny wybór i losowania modyfikatorów min(100,3*wave)% oraz min(100,2*wave)% | Gwarantowany dodatek; po porażce głównego losowania osobna szansa 25% na modyfikator |

Szanse w środkowej kolumnie obowiązują pod warunkiem sukcesu głównego losowania. W fali 10 łączna szansa dodatkowego modyfikatora wynosi 45%*50% = 22.5%.

W fali 17 gwarantowany dodatek, 52% szans na główne zdarzenie i warunkowe losowania 75%/25% pozwalają uzyskać do czterech efektów, oprócz standardowych pojazdów i piechoty. Pierwsze późne losowanie modyfikatora osiąga pewność w fali 34, drugie w fali 50, a główne losowanie w fali 65.

Gwarantowany dodatek jest losowany przed głównym zdarzeniem. Pusta pula dozwolonych wpisów niczego nie dodaje, również gdy wszystkie wpisy są wyłączone ustawieniami pojazdów.

### Dostępność, odstępy i powtórzenia

- Mgła, noc i burza nie mogą powielać samych siebie. Różne efekty pogody i pory dnia mogą współistnieć.
- FOB, polowanie na oficera i operator FPV wykluczają się wzajemnie; sprawdzany jest też stan aktywności i przygotowania.
- FOB jest dostępny od fali 7. Domyślny odstęp dwóch pełnych fal oznacza, że po sukcesie w fali 7 kolejny jest możliwy od fali 10.
- Oficer i FPV są dostępni od fali 10, z domyślnymi odstępami dwóch pełnych fal. FPV wymaga też dostępnego dodatku i włączenia odpowiedniej opcji.
- Inne efekty bojowe mogą się powtarzać: kolejne wybory konwoju, moździerza, desantu lub ostrzału mogą zwiększać presję.
- Filtrowanie następuje przed losowaniem; pusta pula nie daje efektu.

### Ustawienia lobby i debugowanie

Wyłączenie Special Waves usuwa zwykłą listę zdarzeń i modyfikatorów, łącznie z gwarantowanymi dodatkami. Nie wyłącza standardowych pojazdów.

Przed ustawioną falą początkową pojazdów lub przy ustawieniu Never wykluczone są konwój, desant spadochronowy, nalot, moździerz i drony rozminowujące; FPV również wymaga dostępności pojazdów. Zdarzenia specjalne korzystają z ogólnego ustawienia początku pojazdów, a nie z rozłożonych w czasie odblokowań poszczególnych kategorii. FOB pozostaje celem piechoty.

Zdarzenie wymuszone w trybie debugowania zastępuje normalny wybór i wyłącza standardowe losowania pojazdów. Prawdopodobieństwa w raporcie dotyczą zwykłej rozgrywki.

## 9. Dodatkowi przeciwnicy, pojazdy specjalne i zagrożenia

| Efekt | Zamawiana zawartość lub obliczenie |
| --- | --- |
| Konwój | max(1, floor(wave/3)) otwartych ciężarówek Ural na jeden wybór |
| Standardowa ciężarówka | Otwarty Ural z załogą i zamówioną dziesięcioosobową drużyną RHS VDV, zmniejszaną do pojemności transportowej |
| Standardowy śmigłowiec transportowy | Śmigłowiec cargo RHS Mi-8 ze skryptem dostarczania żołnierzy |
| Desant spadochronowy | Samolot transportujący RHS_TU95MS_vvs_tambov; zamawiane ceil((1 + random(wave/4))*5) żołnierzy VDV |
| Nalot | CUP_O_Su25_Dyn_RU; zamawiane 1 + floor(random(wave/5)) lotów uderzeniowych |
| Moździerz | O_Mortar_01_F, moździerz CSAT Mk6 82 mm z załogą |
| Cywile | Do 20 cywilów z publicznych klas postaci cywilnych, w dostępnych pozycjach budynków |
| Fala samobójców | Zwykła piechota zastąpiona pulą samobójców, broń usunięta. Klasa RU: CUP_O_RU_Survivor_MSV_VSR93; Legacy używa bandytów. |
| FOB | Piechota poziomu 3 lub piechota dezerterów, jeśli dotyczy |
| Polowanie na oficera | Piechota poziomu 2/dezerterzy i osobno skonfigurowany oficer |
| Operator FPV | Piechota poziomu 2/dezerterzy i drony FPV z dodatku |
| Dezerterzy | Zastępcze pule piechoty i pojazdów bojowych, opisane poniżej |
| Mgła/noc/burza | Efekty widoczności, czasu i pogody; burza obejmuje też uderzenia w ziemię |
| Artyleria/Grad | Skryptowe źródła ostrzału |
| Fala dronów rozminowujących | Skrypty zagrożenia dronami i dodatkowe drony podczas tworzenia piechoty |

Żołnierze w ciężarówce obejmują sierżanta, sanitariusza, strzelca broni automatycznej, strzelców i lekki zespół ppanc. Pula desantu obejmuje sierżanta, sanitariusza, strzelca broni automatycznej, strzelca z RPK, strzelca i lekkiego specjalistę ppanc.

Specjalny konwój w fali 7 zamawia dwie ciężarówki i może wystąpić równocześnie ze standardowymi losowaniami samochodów i ciężarówek. Specjalny desant może pojawić się przed odblokowaniem standardowych śmigłowców transportowych. FOB dostępny od fali 7 może wprowadzić piechotę poziomu 3 wcześniej niż zwykłe fale.

## 10. Pule dezerterów

W trybie RU vs PL flaga dezerterów zastępuje listy zwykłej piechoty oraz standardowych samochodów, pojazdów pancernych i śmigłowców, zmieniając ich stronę na resistance:

| Kategoria | Typy zastępcze |
| --- | --- |
| Piechota | Dowódca zespołu rozpoznawczego NATO, sanitariusz, JTAC, strzelec wyborowy, snajper, dowódca patrolu, strzelec broni automatycznej patrolu, strzelec precyzyjny rozpoznania, sanitariusz patrolu |
| Samochody | Hunter GMG, Hunter HMG, CUP M1025 M240, uzbrojony Prowler |
| Pojazdy pancerne | CUP M1A2 SEP, Marshall, gąsienicowy transporter NATO, Slammer UP, CUP Challenger 2 |
| Śmigłowce | Ghost Hawk, Huron, lekki śmigłowiec NATO z dynamicznym uzbrojeniem |

Zastępuje to zwykły poziom piechoty. Transporty i desanty o stałych klasach nie zmieniają automatycznie frakcji wraz ze standardowymi pojazdami. Dezerterzy Legacy korzystają z dynamicznie budowanej puli piechoty NATO, list samochodów i pojazdów pancernych Legacy oraz skonfigurowanej listy śmigłowców dezerterów.

## 11. Limit przeciwników obecnych jednocześnie

```text
Pełny limit = min(120, 30 + 4*H)
Limit dopuszczania zwykłej piechoty = floor(0.8 * Pełny limit)
```

| Gracze | Pełny limit | Limit dopuszczania zwykłej piechoty |
| --- | ---: | ---: |
| 1 | 34 | 27 |
| 4 | 46 | 36 |
| 8 | 62 | 49 |
| 16 | 94 | 75 |

Mechanizm tworzenia jednostek liczy żywe jednostki east/resistance oraz zarezerwowane miejsca. Pojazdy rezerwują miejsca na załogę, a grupy na swoich członków. Żądania zwykle czekają na wolne miejsca, z uwzględnieniem anulowania i limitów czasu.

Nie jest to limit całej fali ani budżet pojazdów. Można wylosować kilka kategorii, nawet jeśli nie wszystkie mogą pojawić się od razu. Cywile i pociski nie są wliczani do limitu wrogich żołnierzy.

## 12. Pozostałe skoki trudności

- Fala 3: domyślny mnożnik przeciwników zmienia się z 1 na 2.
- Fala 4: kończy się domyślne ograniczenie do pistoletów.
- Fala 5: wzrost umiejętności, odblokowanie samochodów i początkowych zdarzeń specjalnych.
- Fala 7: wejście poziomu 2, szerokiej puli zdarzeń i ciężarówek; FOB może wprowadzić poziom 3.
- Fale 8/10/12: kolejne kategorie standardowych pojazdów.
- Fala 10: warunkowe modyfikatory oraz możliwość oficera i FPV.
- Fale 15/19: poziom 3 dołącza do puli, a następnie przejmuje całą zwykłą piechotę.
- Fala 17: początek gwarantowanego dodatku bojowego; do czterech wybranych efektów.
- Fale 20/30: znaczne wzrosty umiejętności zwykłej piechoty.

Rozłożenie odblokowań ogranicza wcześniejsze nagromadzenie zagrożeń około fali 6. Pełne pule modeli, niezależne losowania, premie za graczy i specjalne posiłki nadal pozwalają na duże różnice między kolejnymi falami.

## 13. Odnośniki do źródeł

- [Wybór fali](../bulwark/functions/fn_startWave.sqf)
- [Liczebność piechoty i obliczenia standardowych pojazdów](../hostiles/createWave.sqf)
- [Przypisania frakcji](../editMe.sqf) i [domyślne ustawienia lobby](../description.ext)
- [Pule klas](../hostiles/lists.sqf)
- [Wyposażenie i umiejętności piechoty](../hostiles/spawnSquad.sqf)
- [Mechanizm limitu jednostek](../bulwark/functions/fn_spawnLimited.sqf)
- [Ciężarówka](../hostiles/spawnUaz.sqf), [śmigłowiec transportowy](../hostiles/KillTeam.sqf), [desant](../hostiles/ParaDropNew.sqf), [nalot](../hostiles/airStrike.sqf)

## Aneks: dokładne stałe pule klas

Skopiowane z aktualnego hostiles/lists.sqf. Są to skonfigurowane wpisy; faktyczna dostępność zależy od wczytanych dodatków. Dynamiczne pule Legacy opisano powyżej.

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

### Skonfigurowane śmigłowce Legacy

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
