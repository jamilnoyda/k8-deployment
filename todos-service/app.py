# todos-service/app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
import uuid
import requests
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get users service URL from environment
USERS_SERVICE_URL = os.environ.get('USERS_SERVICE_URL', 'http://users-service:80')

# In-memory storage (use database in production)
todos = {}

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "todos"}), 200

@app.route('/todos', methods=['GET'])
def get_todos():
    user_id = request.args.get('user_id')
    if user_id:
        user_todos = [todo for todo in todos.values() if todo['user_id'] == user_id]
        return jsonify(user_todos), 200
    
    return jsonify(list(todos.values())), 200

@app.route('/todos', methods=['POST'])
def create_todo():
    data = request.get_json()
    
    if not data or 'title' not in data or 'user_id' not in data:
        return jsonify({"error": "Title and user_id are required"}), 400
    
    # Verify user exists
    try:
        response = requests.get(f"{USERS_SERVICE_URL}/users/{data['user_id']}", timeout=5)
        if response.status_code == 404:
            return jsonify({"error": "User not found"}), 404
    except requests.RequestException:
        logger.warning("Could not verify user existence - proceeding anyway")
    
    todo_id = str(uuid.uuid4())
    todo = {
        "id": todo_id,
        "title": data['title'],
        "description": data.get('description', ''),
        "completed": False,
        "user_id": data['user_id'],
        "created_at": datetime.utcnow().isoformat()
    }
    
    todos[todo_id] = todo
    logger.info(f"Created todo: {todo_id} for user: {data['user_id']}")
    return jsonify(todo), 201

@app.route('/todos/<todo_id>', methods=['GET'])
def get_todo(todo_id):
    if todo_id not in todos:
        return jsonify({"error": "Todo not found"}), 404
    
    return jsonify(todos[todo_id]), 200

@app.route('/todos/<todo_id>', methods=['PUT'])
def update_todo(todo_id):
    if todo_id not in todos:
        return jsonify({"error": "Todo not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    todo = todos[todo_id]
    allowed_fields = ['title', 'description', 'completed']
    todo.update({k: v for k, v in data.items() if k in allowed_fields})
    todo['updated_at'] = datetime.utcnow().isoformat()
    
    logger.info(f"Updated todo: {todo_id}")
    return jsonify(todo), 200

@app.route('/todos/<todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    if todo_id not in todos:
        return jsonify({"error": "Todo not found"}), 404
    
    del todos[todo_id]
    logger.info(f"Deleted todo: {todo_id}")
    return jsonify({"message": "Todo deleted"}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)