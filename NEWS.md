# khtools (development version)

Konfigurasjon og options

- Ny infrastruktur for lasting og validering av options fra YAML-konfigurasjon i backend-repositoryet.
- Lagt til get_config_options() for å lese én eller flere configfiler fra GitHub med eksplisitte option-prefix. Dersom flere configfiler definerer samme option, vil senere filer overskrive tidligere verdier. Dette støtter gradvis flytting av felles options fra pakkespesifikke configfiler uten å bryte eksisterende pakker.
- get_config_options() støtter dynamiske options som genereres på nytt ved innlesing.
- Felles filstier kan nå defineres hierarkisk under paths i arkitekturconfig. Stiene bygges til komplette filstier og settes som individuelle options, for eksempel kh.paths.filgruppe.ny og kh.paths.database.khelsa.
- Utvidet load_package_options() med støtte for KH-arkitekturen. For KH-pakker leses felles arkitektur først, før eventuelle pakke-spesifikke configfiler bestemmes fra kh.package_opts.
- Pakkespesifikke configfiler er valgfrie. En pakke kan dermed bruke den felles KH-arkitekturen uten å ha egne configfiler.
- Felles kh.*-options behandles som arkitektur og lastes fra config-arkitektur.yml, mens options som skal kunne overstyres per pakke fortsatt bruker pakke-prefix, for eksempel khfunctions.profileyear og qualcontrol.profileyear.
- Lagt til package_options_are_default() for KH-pakker. Funksjonen genererer en fersk fasit fra GitHub, Access og eventuelle dynamiske options og kontrollerer om aktive session-options er identiske med denne.
- khtools leser nå bare egne options fra config-khtools.yml. KH-spesifikke options som filstier og dimensjonsdefinisjoner flyttes ut av khtools.* og inn i den felles KH-arkitekturen.
- khtools-options overskrives alltid med gjeldende defaults når pakken lastes. Dette sikrer blant annet at khtools.silent alltid resettes ved ny lasting av pakken.

# khtools 1.0.0 (2026-11-25)

Første stabile versjon av `khtools`.

`khtools` samler generell funksjonalitet som brukes på tvers av KH-produksjonsapparatet, blant annet databasehåndtering, DuckDB-operasjoner, konfigurasjon, SQL-hjelpefunksjoner, filkonvertering og konsollmeldinger.

## DuckDB

### Oppretting og tilkobling

* `duckdb_init()` oppretter en tom lokal arbeidsdatabase med konfigurerbar grense for minnebruk og separat område for midlertidige filer.
* `duckdb_init()` kan brukes både innenfor og utenfor KH-produksjonsapparatet. Databasenavn, lagringsområde og minnegrense kan angis eksplisitt.
* Standard lagringsområde og minnegrense kan konfigureres per maskin gjennom `khtools.duckdbopts`.
* Lagt til `duckdb_connect()` for å koble til en eksisterende arbeidsdatabase uten å slette eksisterende tabeller.
* Lagt til `duckdb_disconnect()` for å lukke en databaseforbindelse uten å slette databasefilen.
* `duckdb_shutdown()` lukker forbindelsen og sletter arbeidsdatabasen, WAL-filen og tilhørende tempområde.
* `duckdb_clean()` kjører `CHECKPOINT` og `VACUUM` for å rydde databasen etter større operasjoner.
* DuckDB-funksjonaliteten krever `duckdb >= 1.5.5`.

### Inspeksjon og lesing

* `duckdb_table_exists()` sjekker om en tabell finnes.
* `duckdb_get_tables()` returnerer tabellene i databasen.
* `duckdb_get_columns()` returnerer kolonnenavn for en tabell.
* `duckdb_get_column_types()` returnerer DuckDB-datatypene for kolonnene i en tabell.
* `duckdb_fetch_table()` leser en DuckDB-tabell til `data.table`, med mulighet for å begrense antall rader.

### Oppretting og skriving av tabeller

* `duckdb_write_table()` skriver `data.frame`/`data.table` til DuckDB og støtter både permanente og midlertidige tabeller.
* `duckdb_create_new_table()` oppretter en ny tabell fra et SQL-uttrykk og stopper dersom måltabellen allerede finnes.
* `duckdb_drop_tables()` sletter én eller flere tabeller dersom de finnes.
* `duckdb_ensure_columns()` sikrer at angitte kolonner finnes og oppretter manglende kolonner med spesifisert DuckDB-type.

### Oppdatering og kombinasjon av tabeller

* `duckdb_replace_table()` erstatter en eksisterende tabell atomisk med en annen tabell.
* `duckdb_replace_existing_table()` erstatter innholdet i en eksisterende tabell med resultatet av et SQL-uttrykk via en midlertidig tabell. Dette gjør det mulig å transformere en tabell uten å lese fra og skrive direkte til samme tabell.
* `duckdb_write_and_replace_table_from_R()` skriver et R-datasett til en midlertidig tabell og erstatter deretter måltabellen.
* `duckdb_merge_tables()` legger nye kolonner fra én DuckDB-tabell til en annen basert på eksplisitt angitte join-kolonner.
* `duckdb_append_table()` legger rader fra én DuckDB-tabell til en annen etter kolonnenavn. Manglende kolonner opprettes automatisk med riktig datatype, tilsvarende prinsippet i `data.table::rbindlist(use.names = TRUE, fill = TRUE)`.

### Eksport fra DuckDB

* `duckdb_save_file()` eksporterer tabeller eller SQL-resultater direkte fra DuckDB.
* Parquet eksporteres med ZSTD-komprimering.
* CSV eksporteres med header og semikolon som skilletegn.

## Parquet og filkonvertering

* Lagt til `read_pq()` som en enkel wrapper rundt `arrow::read_parquet()` og returnerer resultatet som `data.table`.
* Lagt til `convert_spss_to_parquet()` for å lese SPSS-filer og lagre dem som Parquet.
* Parquet-støtten gir en felles inngang for effektiv lagring og innlesing av større datasett.

## SQL-hjelpefunksjoner

* `sql_quote_I()` gir en enkel wrapper rundt `DBI::dbQuoteIdentifier()` for sikker quoting av tabell- og kolonnenavn.
* `sql_quote_S()` gir en enkel wrapper rundt `DBI::dbQuoteString()` for sikker quoting av tekstverdier og filstier i SQL.
* DuckDB-funksjonene bruker quoting av dynamiske tabellnavn, kolonnenavn og strenger der dette er nødvendig.

## Konfigurasjon og options

* `khtools` leser global og pakkespesifikk konfigurasjon fra YAML-filer.
* Globale verdier kombineres med pakkespesifikk konfigurasjon, der pakkespesifikke verdier overstyrer globale defaults.
* Konfigurasjonen eksponeres som pakkespesifikke R-options, eksempelvis `khtools.*` og `khfunctions.*`.
* `khtools` setter ved lasting en dynamisk liste over gyldige dimensjonsnavn basert på aktive `TAB1`, `TAB2` og `TAB3` i KHelsa-databasen.
* Det finnes intern støtte for å kontrollere om aktive options fortsatt samsvarer med konfigurasjonsfilene.
* Det finnes intern støtte for å kontrollere om en nyere pakkeversjon er tilgjengelig på GitHub.

## Databasetilkobling

* Felles logikk for tilkobling til Microsoft Access-databaser er samlet i `khtools`.
* Interne tilkoblingsfunksjoner brukes for blant annet KHelsa- og geokodedatabasene.
* Databasestier styres gjennom options fremfor å hardkodes i funksjonene.

## Logging

* `msg()` skriver meldinger til konsollen og flusher output slik at framdriftsmeldinger vises fortløpende.
* `header()` gir standardiserte overskrifter i konsolloutput.
* Konsolloutput kan deaktiveres gjennom `khtools.silent`, blant annet for testing.

## Kvalitet og testing

* Etablert automatiske tester for sentral database-, DuckDB-, konfigurasjons- og hjelpefunksjonalitet.
* DuckDB-testene kjøres mot isolerte midlertidige arbeidsdatabaser.
* `duckdb_init()` er testet for å alltid starte med en tom arbeidsdatabase.
* `duckdb_connect()` og `duckdb_disconnect()` er testet for å bevare eksisterende database og tabeller mellom funksjonskall.
* Eksplisitte innstillinger for lagringsområde og minnegrense kan overstyre konfigurerte defaults.
* Pakken passerer `R CMD check` uten errors, warnings eller notes.
