#!/usr/bin/env python3

import json
import requests
import re
import sys

# Read the JSON input from stdin
input_data = json.load(sys.stdin)

# Access the variables
sr_url = input_data.get("sr_url")
api_key = input_data.get("api_key")
api_secret = input_data.get("api_secret")

# Make a request to your API
response = requests.get((sr_url)+"/dek-registry/v1/policy",auth=(api_key, api_secret))
data = response.json()

policy = data.get("policy", "")
issuer = None

# Extract the value after '--issuer ' and before the next space or backslash
match = re.search(r'--issuer\s+([^\s\\]+)', policy)
if match:
    issuer = match.group(1)

print(json.dumps({
    "issuer": issuer
}))
