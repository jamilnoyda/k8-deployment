# users-service/app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
import uuid
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# In-memory storage (use database in production)
users = {}

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "users"}), 200

@app.route('/users', methods=['GET'])
def get_users():
    return jsonify(list(users.values())), 200

@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json()
    
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({"error": "Name and email are required"}), 400
    
    user_id = str(uuid.uuid4())
    user = {
        "id": user_id,
        "name": data['name'],
        "email": data['email'],
        "created_at": datetime.utcnow().isoformat()
    }
    
    users[user_id] = user
    logger.info(f"Created user: {user_id}")
    return jsonify(user), 201

@app.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    if user_id not in users:
        return jsonify({"error": "User not found"}), 404
    
    return jsonify(users[user_id]), 200

@app.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    if user_id not in users:
        return jsonify({"error": "User not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    user = users[user_id]
    user.update({k: v for k, v in data.items() if k in ['name', 'email']})
    user['updated_at'] = datetime.utcnow().isoformat()
    
    logger.info(f"Updated user: {user_id}")
    return jsonify(user), 200

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in users:
        return jsonify({"error": "User not found"}), 404
    
    del users[user_id]
    logger.info(f"Deleted user: {user_id}")
    return jsonify({"message": "User deleted"}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)