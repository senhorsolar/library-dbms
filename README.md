# Library Database Management System
DBMS for a fictional public library.

## Directory Structure
* __scripts__: Various python scripts
    - generate_data.py: Generates random data to populate database
    - create_db.py Creates database and populates with data
* __data__: contains intermediate data such as csv files for populating database
    - books.csv: Contains books that will be used to populate database.
* __sql__: Contans all things sql related such as schemas
    - tables.sql: Contains table definitions
    - triggers.sql: Contains triggers and scheduled events
    - queries.sql: Contains example queries
* __fig__: diagrams and such
    - er-diagram.png: Entity relationship (ER) diagram of database
    
## Example

```
cd scripts
python3 create_db.py <mysql.cfg>
```

Where `mysql.cfg` is a file that looks like
```
[mysql]
user=...
passwd=...
url=mysql://<...>
```