from names import get_full_name
from random_address import real_random_address
import pandas as pd

def load_books(filename):
    return pd.read_csv(filename)
    
def address_to_str(addr: dict):
    s = addr['address1']
    if addr['address2']:
        s += f"\n{addr['address2']}"
    s += f"\n{addr['state']}"
    s += f", {addr['postalCode']}"
    return s

def get_random_address():
    return address_to_str(real_random_address())

def get_random_id(eng, table: str) -> int:
    with eng.connect() as con:
        id_ = con.execute("SELECT id FROM {table} ORDER BY RAND() LIMIT 1;")
        if len(id_) > 0:
            id_ = id_[0]
            if len(id_) > 0:
                return id_[0]
        print(f"No rows in {table}")
        return None

def insert_books(eng, filename):
    
    books = load_books(filename)

    with eng.connect() as con:
        for _, book in books.iterrows():
            isbn = str(book['isbn'])
            title = book['original_title']
            author = book['authors']
            year = int(book['original_publication_year'])
            try:
                con.execute("INSERT INTO Book(isbn, title, author, year) VALUES(%s, %s, %s, %s);", isbn, title, author, year)
            except Exception as e:
                print(f"Failed to insert row : ({isbn},{title},{author},{year})")
            
def insert_members(eng, n_members):
    
    with eng.connect() as con:

        for _ in range(n_members):

            name = get_full_name()
            addr = get_random_address()

            try:
                con.execute(f"INSERT INTO Member(name, address) VALUES({name}, {addr})")
            except:
                pass

def insert_checkouts(eng, n_checkouts):
    
    with eng.connect() as con:
                        
        inv_ids = con.execute(f"SELECT id FROM Inventory ORDER BY RAND() LIMIT {n_checkouts}")

        for (inv_id,) in inv_ids:
            try:

                member_id, = con.execute(f"SELECT id FROM Member ORDER BY RAND () LIMIT 1")
                member_id = member_id[0]

                con.execute(f"INSERT INTO Checkout(memberId, inventoryId) VALUES({member_id}, {inv_id}")
            except:
                pass
        
def insert_reservations(eng, n_reservations):
    
    with eng.connect() as con:
        
        inv_ids = con.execute(f"SELECT id FROM Inventory ORDER BY RAND() LIMIT {n_reservations}")

        for (inv_id,) in inv_ids:
            try:

                member_id, = con.execute(f"SELECT id FROM Member ORDER BY RAND () LIMIT 1")
                member_id = member_id[0]

                con.execute(f"INSERT INTO Reservation(memberId, inventoryId) VALUES({member_id}, {inv_id}")
            except:
                pass