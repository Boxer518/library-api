from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, constr, PositiveFloat, EmailStr
from typing import List
from sqlalchemy import Column, Integer, String, Float, ForeignKey, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, relationship, Session
from pydantic import BaseModel, PositiveFloat, EmailStr, constr

DB_URL = "sqlite:///store.db"
engine = create_engine(DB_URL, echo=False, future=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False, future=True)
Base = declarative_base()

# ─────────────────────────── БД модели ────────────────────────────
class Category(Base):
    __tablename__ = "categories"  # Исправлено: было tablename -> __tablename__
    id   = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    products = relationship("Product", back_populates="category", cascade="all,delete")

class Product(Base):
    __tablename__ = "products"  # Исправлено: было tablename -> __tablename__
    id          = Column(Integer, primary_key=True, index=True)
    name        = Column(String, nullable=False)
    price       = Column(Float, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"))
    category    = relationship("Category", back_populates="products")

class Customer(Base):
    __tablename__ = "customers"  # Исправлено: было tablename -> __tablename__
    id    = Column(Integer, primary_key=True, index=True)
    name  = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)

# ─────────────────────────── Pydantic схемы ───────────────────────

class CategoryIn(BaseModel):
    name: constr(min_length=1, max_length=100)  # Добавлено ограничение максимальной длины
    
class CategoryOut(CategoryIn):
    id: int
    
    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": 1,
                "name": "Electronics"
            }
        }

class ProductIn(BaseModel):
    name: constr(min_length=1, max_length=100)
    price: PositiveFloat
    category_id: int
    
class ProductOut(ProductIn):
    id: int
    
    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": 1,
                "name": "Smartphone",
                "price": 599.99,
                "category_id": 1
            }
        }

class CustomerIn(BaseModel):
    name: constr(min_length=1, max_length=50)
    email: EmailStr
    
class CustomerOut(CustomerIn):
    id: int
    
    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": 1,
                "name": "John Doe",
                "email": "john.doe@example.com"
            }
        }
app = FastAPI(title="Продуктовый магазин API")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---------- служебные энд-пойнты ----------
@app.post("/init-db", tags=["admin"])
def init_db():
    Base.metadata.create_all(engine)
    return {"status": "tables created"}

@app.delete("/drop-db", tags=["admin"])
def drop_db():
    Base.metadata.drop_all(engine)
    return {"status": "tables dropped"}

# ---------- Category ----------
@app.post("/categories", response_model=CategoryOut)
def add_category(data: CategoryIn, db: Session = Depends(get_db)):  # Исправлено: next(get_db()) -> Depends(get_db)
    cat = Category(**data.model_dump())  # Исправлено: data.dict() -> data.model_dump() для Pydantic v2
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat

@app.get("/categories", response_model=List[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return db.query(Category).all()

@app.get("/categories/{cid}", response_model=CategoryOut)
def get_category(cid: int, db: Session = Depends(get_db)):
    cat = db.get(Category, cid)
    if not cat:
        raise HTTPException(status_code=404)  # Исправлено: добавлен status_code
    return cat

@app.put("/categories/{cid}", response_model=CategoryOut)
def update_category(cid: int, data: CategoryIn, db: Session = Depends(get_db)):
    cat = db.get(Category, cid)
    if not cat:
        raise HTTPException(status_code=404)
    for k, v in data.model_dump().items():
        setattr(cat, k, v)
    db.commit()
    db.refresh(cat)
    return cat

@app.delete("/categories/{cid}")
def delete_category(cid: int, db: Session = Depends(get_db)):
    cat = db.get(Category, cid)
    if not cat:
        raise HTTPException(status_code=404)
    db.delete(cat)
    db.commit()
    return {"deleted": cid}

# ---------- Product ----------
@app.post("/products", response_model=ProductOut)
def add_product(data: ProductIn, db: Session = Depends(get_db)):
    if not db.get(Category, data.category_id):
        raise HTTPException(status_code=400, detail="category_id not found")  # Исправлено: добавлен detail
    prod = Product(**data.model_dump())
    db.add(prod)
    db.commit()
    db.refresh(prod)
    return prod

@app.get("/products", response_model=List[ProductOut])
def list_products(db: Session = Depends(get_db)):
    return db.query(Product).all()

@app.get("/products/{pid}", response_model=ProductOut)
def get_product(pid: int, db: Session = Depends(get_db)):
    prod = db.get(Product, pid)
    if not prod:
        raise HTTPException(status_code=404)
    return prod

@app.put("/products/{pid}", response_model=ProductOut)
def update_product(pid: int, data: ProductIn, db: Session = Depends(get_db)):
    prod = db.get(Product, pid)
    if not prod:
        raise HTTPException(status_code=404)
    for k, v in data.model_dump().items():
        setattr(prod, k, v)
    db.commit()
    db.refresh(prod)
    return prod

@app.delete("/products/{pid}")
def delete_product(pid: int, db: Session = Depends(get_db)):
    prod = db.get(Product, pid)
    if not prod:
        raise HTTPException(status_code=404)
    db.delete(prod)
    db.commit()
    return {"deleted": pid}

# ---------- Customer ----------
@app.post("/customers", response_model=CustomerOut)
def add_customer(data: CustomerIn, db: Session = Depends(get_db)):
    cust = Customer(**data.model_dump())
    db.add(cust)
    db.commit()
    db.refresh(cust)
    return cust

@app.get("/customers", response_model=List[CustomerOut])
def list_customers(db: Session = Depends(get_db)):
    return db.query(Customer).all()

@app.get("/customers/{cid}", response_model=CustomerOut)
def get_customer(cid: int, db: Session = Depends(get_db)):
    cust = db.get(Customer, cid)
    if not cust:
        raise HTTPException(status_code=404)
    return cust

@app.put("/customers/{cid}", response_model=CustomerOut)
def update_customer(cid: int, data: CustomerIn, db: Session = Depends(get_db)):
    cust = db.get(Customer, cid)
    if not cust:
        raise HTTPException(status_code=404)
    for k, v in data.model_dump().items():
        setattr(cust, k, v)
    db.commit()
    db.refresh(cust)
    return cust

@app.delete("/customers/{cid}")
def delete_customer(cid: int, db: Session = Depends(get_db)):
    cust = db.get(Customer, cid)
    if not cust:
        raise HTTPException(status_code=404)
    db.delete(cust)
    db.commit()
    return {"deleted": cid}