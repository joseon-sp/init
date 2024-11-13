import json
import os

from supabase import create_client

# Load Supabase configuration from config.json
config_path = "config.json"
if not os.path.exists(config_path):
    print("Configuration file not found.")
    exit(1)

with open(config_path, 'r') as config_file:
    config = json.load(config_file)

url = config.get("SUPABASE_URL")
key = config.get("SUPABASE_KEY")

if not url or not key:
    print("Supabase URL or Key not found in config.json.")
    exit(1)

supabase = create_client(url, key)