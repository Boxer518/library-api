import requests, json, sys
from tabulate import tabulate

BASE = "http://127.0.0.1:8000"

def pretty(res):
    if res.ok:
        if res.text:
            try:
                data = res.json()
                if isinstance(data, list):
                    print(tabulate(data, headers="keys"))
                else:
                    print(json.dumps(data, indent=2, ensure_ascii=False))
            except ValueError:
                print(res.text)
    else:
        print(f"❌ {res.status_code}: {res.text}")

def menu():
    print("""
1  Создать таблицы         2  Удалить таблицы
3  Категории CRUD          4  Товары CRUD
5  Клиенты CRUD            0  Выход
""")

def crud(entity):
    plural = entity + "s"
    while True:
        print(f"\n{entity.capitalize()} — меню:")
        print("1  Create   2  Read all   3  Read one   4  Update   5  Delete  0  Back")
        choice = input("> ")
        if choice == "1":
            payload = json.loads(input("JSON payload: "))
            pretty(requests.post(f"{BASE}/{plural}", json=payload))
        elif choice == "2":
            pretty(requests.get(f"{BASE}/{plural}"))
        elif choice == "3":
            _id = input("ID: ")
            pretty(requests.get(f"{BASE}/{plural}/{_id}"))
        elif choice == "4":
            _id = input("ID: ")
            payload = json.loads(input("JSON payload: "))
            pretty(requests.put(f"{BASE}/{plural}/{_id}", json=payload))
        elif choice == "5":
            _id = input("ID: ")
            pretty(requests.delete(f"{BASE}/{plural}/{_id}"))
        else:
            break

if __name__ == "__main__":
    while True:
        menu()
        cmd = input("Выберите пункт: ")
        if cmd == "1":
            pretty(requests.post(f"{BASE}/init-db"))
        elif cmd == "2":
            pretty(requests.delete(f"{BASE}/drop-db"))
        elif cmd == "3":
            crud("category")
        elif cmd == "4":
            crud("product")
        elif cmd == "5":
            crud("customer")
        elif cmd == "0":
            sys.exit()
        else:
            print("Неизвестная команда")

