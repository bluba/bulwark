# FPV Drone Operator — plan implementacji

Status: propozycja, 2026-10-30. Dokument nie oznacza implementacji ani akceptacji w Arma. Nie zmienia kodu rozgrywki i nie wymaga budowania PBO misji.

## Cel i proponowany zakres MVP

Ukryte stanowisko z operatorem i 2–3 strażnikami okresowo wysyła drony kamikadze. Gracze mogą strącać drony, korzystać z osłon oraz przerwać ataki przez zabicie operatora ALBO zniszczenie urządzenia sterującego na stanowisku. Oba warunki są niezależne i wystarczające. Animacja, przydział grupy i rzeczywiste połączenie UAV nie sterują aktywnością stanowiska.

Proponowane wartości początkowe, do strojenia w grze:

| Parametr | Wartość |
| --- | --- |
| Pierwsza fala | 10 |
| Odstęp między udanymi wystąpieniami | 2 pełne fale |
| Liczba stanowisk | 1, także podczas przygotowywania |
| Strażnicy | 2, opcjonalnie 3 |
| Odległość stanowiska | 300–700 m od uchwyconej pozycji Bulwarka |
| Pierwszy start | 30 s po komunikacie |
| Odstęp między startami | losowo 35–50 s; bez nadrabiania pominiętych startów |
| Aktywne drony | maksymalnie 2; dla samotnego gracza 1 |
| Limit wszystkich startów | 10 na stanowisko |
| Czas działania stanowiska | maksymalnie 8 minut |
| Czas życia drona | maksymalnie 90 s |
| Rozłożenie ataków | maksymalnie 1 przydzielony dron na gracza |

Na początek wykluczyć jednoczesny FOB i Officer Hunt, z wzajemnymi filtrami selekcji. Ten modyfikator podlega Specials Off i ustawieniu pojazdów Never/start-wave. Nie dodawać go do obowiązkowego losowania po fali 15; umieścić w późniejszej puli głównej. Bez dodatkowej nagrody pieniężnej w MVP; zwykłe punkty za przeciwników zgodnie z istniejącym systemem.

## Etap 0 — rozpoznanie moda i próba techniczna

Lokalnie potwierdzono katalog Workshop `F:/SteamLibrary/steamapps/workshop/content/107410/3475006113`, pliki metadanych, `addons/fpv_ua.pbo`, podpis oraz klucz. Nie ustalono jeszcze klas pojazdów, amunicji, wymaganych addonów ani skryptów detonacji. Nie wpisywać zgadywanych nazw klas do misji.

Przed kodowaniem odczytać konfigurację i skrypty dodatku, zachowując oryginały. Zapisać klasy UAV, crew, uzbrojenia, ładunku, requiredAddons, event handlery i sposób inicjalizacji. W edytorze sprawdzić: spawn bez interfejsu operatora, sterowanie ruchem na serwerze, kolizje, podatność na ostrzał, dźwięk, usuwanie oraz zachowanie ładunku przy zniszczeniu.

Warunek kontynuacji: da się zastosować dokładnie jedną ścieżkę detonacji. Jeśli mod automatycznie detonuje przy zniszczeniu, adapter wykorzystuje ten mechanizm albo wyłącza go udokumentowanym sposobem. Nie nakładać dodatkowej eksplozji na natywny ładunek. Jeśli nie można bezpiecznie anulować drona lub sterować nim bez pilota gracza, zatrzymać integrację tego modelu i opisać ograniczenie.

Brak moda lub niepoprawna konfiguracja oznacza pominięcie modyfikatora przed losowaniem i jeden czytelny wpis RPT. Serwer i klienci muszą mieć wymagany dodatek. Nie dodawać obowiązkowej zależności do mission.sqm, dopóki modyfikator ma pozostać opcjonalny.

## Etap 1 — stanowiska i wykrywalność

Utworzyć osobną listę sprawdzonych punktów Altis: pozycja operatora, urządzenia, strażników, startu i początkowego korytarza lotu. Nie używać przypadkowych pozycji z całej mapy. Punkty trzeba sprawdzić pieszo w edytorze; test geometrii nie dowodzi dostępności terenu.

Przy aktywacji filtrować listę według aktualnej uchwyconej pozycji Bulwarka, odległości 300–700 m, lądu, dostępnej przestrzeni i braku bezpośredniego widoku żywych graczy na operatora/start. Sprawdzać skończoną pulę. Brak kandydata kończy próbę bez cooldownu, jednostek i rezerwacji. Ruch Bulwarka o co najmniej 150 m od uchwyconego położenia zamyka stanowisko; nie teleportować go za graczami.

Komunikat zapowiada operatora FPV, a mapa pokazuje przybliżony obszar poszukiwań, np. koło 150 m zawierające stanowisko. Nie ujawniać dokładnego punktu ani aktualnych pozycji graczy. Dźwięk dronów i zauważalne powtarzalne kierunki nalotu stanowią dodatkowe wskazówki. Zachować słyszalny etap podejścia przed szybkim atakiem.

## Etap 2 — stan serwera i cykl życia

Serwer jest jedynym właścicielem decyzji o spawnie, celu i detonacji. Rekord `BW_FPV_OPERATOR` przechowuje ID instancji, originatingWave, fazę, operatora, urządzenie, grupy, obiekty, worker, drony, terminy, licznik startów i rezerwacje celów. Oddzielnie przechowywać ostatnią udaną falę i atomową rezerwację przygotowania. Cooldown zatwierdzać dopiero po utworzeniu kompletnego aktywnego stanowiska; częściową porażkę wycofać.

Operator i strażnicy powstają przez `spawnLimited` jako specjalni przeciwnicy, z ograniczonym terminem oczekiwania. Wykorzystać dostępny szósty argument gatewaya; po zwrocie ponownie sprawdzić oba elementy stanowiska, wave ID i termin. Chronić grupę przed ogólnym kontrolerem przez `bw_scriptedMovement`; strażnicy bronią lokalnie, operator nie rusza w szturm.

Producent stanowiska jest rejestrowany przez `queueHostiles` i blokuje zakończenie fali tylko do rozstrzygnięcia stanowiska oraz zakończenia oczekujących zadań. Koniec następuje przy śmierci/usunięciu operatora, zniszczeniu/usunięciu urządzenia, wyczerpaniu 10 startów, upływie 8 minut, relokacji albo anulowaniu fali. Unikać cyklu: worker czeka na koniec fali, a fala czeka na worker.

Po rozstrzygnięciu w walce natychmiast zatrzymać starty i bez eksplozji usunąć istniejące drony. Żywych członków obsady zwolnić do szturmu: wyczyścić obie blokady stationary/NonCQB i grupową blokadę ruchu, uruchomić istniejący kontroler na właścicielu grupy. Producent kończy się po opróżnieniu dzieci i rezerwacji. Sceneria może pozostać do przygotowania; jej sprzątanie nie blokuje fali.

Ekstrakcja, zakończenie misji i zmiana fali usuwają wszystkie własne jednostki, drony, urządzenia, markery oraz zadania. Jedna idempotentna funkcja zakończenia sprawdza ID instancji i nie może wyczyścić nowego stanowiska. Najpierw unieważnić rekord, następnie sprzątać. Każdy opóźniony callback sprawdza ID i originatingWave.

## Etap 3 — maszyna stanów drona

| Stan | Zachowanie i warunek wyjścia |
| --- | --- |
| Spawn | Sprawdzenie aktywności stanowiska, slotu i ukrytego punktu startu; krótki limit oczekiwania na capacity; brak miejsca pomija ten start. |
| Search | Ocena celów co 2 s; brak celu przez 10 s oznacza Cleanup. |
| Approach | Lot do punktu podejścia, okresowa korekta celu i kontrola przeszkód; bez przenikania przez geometrię. |
| Attack | Krótki szybki nalot po potwierdzeniu widoczności; utrata drogi ataku wraca do Search lub kończy drona po limicie prób. |
| Detonation | Jednorazowa, serwerowa decyzja o eksplozji z blokadą ponownego wywołania. |
| Cleanup | Zwolnienie celu i slotu oraz usunięcie obiektu, crew i własnych handlerów. |

Nie projektować pełnego omijania budynków. Adapter moda realizuje prosty lot odcinkami i sprawdzenie krótkiego korytarza przed dronem. Przeszkoda wymusza ograniczoną próbę zmiany wysokości/kierunku, potem powrót do Search albo Cleanup. Bez teleportacji przez budynki, śledzenia gracza przez ściany i nieskończonych pętli ratowania drona. Sposób sterowania i częstotliwość ustalić w próbie technicznej; startowo jeden wspólny tick ruchu 0,1 s dla maksymalnie dwóch dronów, bez pętli eachFrame na klientach.

Celami są żywi, przytomni ludzie WEST, bez headless clients i spectatorów. Punktacja łączy znormalizowaną odległość, widoczność i dostępny korytarz; nakłada karę za pojazd, aktywny przydział oraz niedawny atak. Losować spośród najlepszych kandydatów, zamiast zawsze wybierać minimum odległości. Historię i cooldown przypinać do UID, przydział do konkretnej jednostki; zmiana ciała, śmierć, disconnect i zwolnienie drona czyszczą przydział. Dla solo cooldown oznacza przerwę, nie ignorowanie ograniczenia. W MVP odrzucać cele w opancerzonych pojazdach; dron nie otrzymuje zdolności przeciwpancernej bez osobnego balansu.

Bezpośrednio przed atakiem ponownie sprawdzić cel i widoczność. Warunek trafienia: rzeczywista kolizja potwierdzona przez mod albo mały dystans, np. 2 m, oraz nieprzesłonięty odcinek do celu. Osłona musi zatrzymywać atak; sama odległość przez ścianę nie wystarcza. Eksplozję wykonuje tylko zweryfikowany adapter moda. Cleanup przy anulowaniu nigdy nie używa `setDamage 1`, jeśli uruchamia to ładunek.

## Etap 4 — limity, multiplayer i UI

Drony oraz stanowisko mają osobne, atomowo rezerwowane limity. Jeżeli model wymaga crew EAST/RESISTANCE, tworzyć go przez gateway i uwzględniać crew w capacity. Jeżeli działa jako obiekt bez crew, nie podszywać go pod jednostkę capacity: stosować własny limit dwóch obiektów. Wykluczyć drony z ogólnego AI, anti-stuck i przejęcia przez graczy. Wybrana ścieżka zależy od etapu 0.

Nie uruchamiać klientowskich kopii logiki. Przed ruchem sprawdzać lokalność; w MVP utrzymać drony na serwerze i odrzucić/bezpiecznie zamknąć instancję po nieoczekiwanej zmianie właściciela. Obsada korzysta z istniejącej obsługi owner-local. Replikować jedynie niezbędny snapshot: ID, faza, obszar poszukiwań, aktywność i termin. JIP odtwarza UI, nie ponawia startów ani eksplozji. Dodać polskie i angielskie komunikaty oraz licznik aktywnych stanowisk w osobnym snapshotcie, bez zmiany znaczenia istniejącego licznika FOB.

## Plan zmian w plikach

- `editMe.sqf`: przełącznik, klasy potwierdzone w modzie, limity i czasy.
- `locationLists.sqf` lub nowy plik danych: sprawdzone punkty stanowisk Altis.
- `bulwark/functions/`: dostępność, start/watch/end stanowiska, adapter moda, selekcja celu i tick dronów; rejestracja w `Functions.hpp`.
- `fn_startWave.sqf`: filtrowanie, singleton, późniejsza pula i dispatch. Predykaty FOB/Officer Hunt: wzajemne wykluczenie.
- `missionLoop.sqf` i `fn_endWave.sqf`: inicjalizacja i jawne anulowanie; istniejące warunki zakończenia zachować.
- Taktyczne UI i `stringtable.xml`: przybliżony obszar, stan oraz komunikaty PL/EN.
- `tests/fpvOperator.sqf`, `docs/FPV_OPERATOR.md`, aktualizacje przewodników i handoff po wdrożeniu.

## Kolejność dostarczenia i kryteria akceptacji

1. Rozpoznać mod i sprawdzić pojedynczy dron w pustej misji. Dostarczyć listę klas, zależności i potwierdzony kontrakt detonacji/cleanup.
2. Przygotować punkty i wdrożyć samo stanowisko z przełącznikiem wyłączonym domyślnie. Sprawdzić singleton, cooldown, porażki setupu i skończony czas producenta.
3. Dodać jeden dron, stany, ograniczenia celu i wszystkie ścieżki anulowania. Potem zwiększyć limit do dwóch i podłączyć selektor fal/UI.
4. Wykonać kontrolę składni leksykalnej, rejestracji i odwołań; parsowanie XML i zgodność placeholderów. Nie nazywać tych kontroli kompilacją SQF.
5. Uruchomić harness w osobnej bezczynnej misji: brak moda/punktów, Specials Off, Never/start-wave, równoczesne starty, pełna capacity, śmierć operatora i zniszczenie urządzenia przed/w trakcie/po tworzeniu drona, timeouty, limity i ponowne sprzątanie starego ID. Potwierdzić brak jednostek przy [0,0,0], ukrytych dronów i pozostawionych rezerwacji.
6. Hosted i dedicated z dwoma klientami: strącenie, kolizja, osłona za ścianą, brak podwójnych eksplozji, respawn/disconnect celu, solo, pojazdy, JIP, HC, ekstrakcja i koniec fali w każdym stanie. Zweryfikować komunikaty oraz utrzymanie głośności/dystansu ostrzeżenia w nocy i deszczu.
7. Sprawdzić obciążenie w późnej fali i stos z innymi dozwolonymi modyfikatorami. Akceptacja wymaga skończonej liczby obiektów/zadań, odzyskania FPS po cleanup, braku błędów RPT i braku eksplozji po anulowaniu. Dopiero wtedy włączyć modyfikator domyślnie.

Decyzje do zatwierdzenia przed implementacją: proponowane liczby balansu, przybliżony marker od początku, natychmiastowe neutralizowanie istniejących dronów po utracie stanowiska oraz wykluczenie FOB/Officer Hunt. Pozostałe kroki techniczne wynikają z obecnej architektury; nie są dowodem zgodności moda z tą architekturą.
