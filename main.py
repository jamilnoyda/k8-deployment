from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI()

# Pydantic model for the TODO item
class TodoItem(BaseModel):
    id: int
    title: str
    description: str
    completed: bool = False

# In-memory storage
todo_db: List[TodoItem] = []

@app.get("/todos", response_model=List[TodoItem])
def get_todos():
    return todo_db

@app.get("/todos/{todo_id}", response_model=TodoItem)
def get_todo(todo_id: int):
    for todo in todo_db:
        if todo.id == todo_id:
            return todo
    raise HTTPException(status_code=404, detail="Todo not found")

@app.post("/todos", response_model=TodoItem)
def create_todo(todo: TodoItem):
    todo_db.append(todo)
    return todo

@app.put("/todos/{todo_id}", response_model=TodoItem)
def update_todo(todo_id: int, updated_todo: TodoItem):
    for index, todo in enumerate(todo_db):
        if todo.id == todo_id:
            todo_db[index] = updated_todo
            return updated_todo
    raise HTTPException(status_code=404, detail="Todo not found")

@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    for index, todo in enumerate(todo_db):
        if todo.id == todo_id:
            del todo_db[index]
            return {"message": "Todo deleted"}
    raise HTTPException(status_code=404, detail="Todo not found")
