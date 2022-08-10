#!/usr/bin/env python3

import os
import configparser
from sqlalchemy import create_engine, text, MetaData

from generate_data import insert_books, insert_members, insert_checkouts, insert_reservations

def connect(mysql_config_file: str):
    mysqlcfg = configparser.ConfigParser()
    mysqlcfg.read(mysql_config_file)
    dburl = mysqlcfg['mysql']['url']
    eng = create_engine(dburl)
    return eng
    
def create_tables(table_file, eng):
    with eng.connect() as con:
        with open("../sql/tables.sql") as f:
            con.execute(text(f.read()))
    
def create_triggers(table_file, eng):
    with eng.connect() as con:
        with open("../sql/triggers.sql") as f:
            con.execute(text(f.read()))
            
if __name__ == '__main__':
    
    import argparse
    
    parser = argparse.ArgumentParser(description='Create library database')
    parser.add_argument('config_file', type=str, help="mysql config file")
    parser.add_argument('--table_file', default="../sql/tables.sql")
    parser.add_argument('--trigger_file', default="../sql/triggers.sql")
    parser.add_argument('--books_file', default="../data/books.csv")
    args = parser.parse_args()
    
    print("...Creating database")
    eng = connect(args.config_file)
    create_tables(args.table_file, eng)
    create_triggers(args.trigger_file, eng)
    
    print("Created database")
    
    print("...Inserting data")
    n_members = 50
    n_checkouts = 20
    n_reservations = 20
    
    insert_books(eng, args.books_file)
    insert_members(eng, n_members)
    insert_checkouts(eng, n_checkouts)
    insert_reservations(eng, n_reservations)
    
    print("Inserted data")

