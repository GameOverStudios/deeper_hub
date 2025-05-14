import os
import json
import time
import requests
from flask import Flask, request, Response, jsonify

app = Flask(__name__)

# --- Configuration ---
# !!! SECURITY WARNING !!!
# HARDCODING API KEYS DIRECTLY IN CODE IS EXTREMELY DANGEROUS AND HIGHLY DISCOURAGED.
# If this file is ever shared or exposed, your API keys will be compromised.
# FOR PRODUCTION OR ANY SENSITIVE USE, ALWAYS READ KEYS FROM ENVIRONMENT VARIABLES OR A SECRETS MANAGER.
# You provided keys directly in the code, so we will use them here, but please be aware of the risk.
# http://127.0.0.1:5000/

API_KEYS = [
    "AIzaSyBTfQcCsyPBxBCCQ89VK7jdycayeWxoo24",
    "AIzaSyCuMZ0IrtjGh5yzStXcoR0rXelbFdmw_go",
    "AIzaSyCuqyVApI3-e-mursGZYQL3y-MA1DTDcpQ",
    "AIzaSyC_i3gPWJHg5MZPlIxyhHiO2zDPmUIi7nY",
    "AIzaSyCUDY7bSGgmpGYeb17NjHgFf1WE4FaSxTg",
    "AIzaSyDi9LZXegWhsDVt-ICi5GpwtpWf2Z9hfmk",
    "AIzaSyBgSfEcRafE6VyzaTHez7mFNzXCmebOpWk",
    "AIzaSyB2tniqRUWEJoCHs812evjMp3nbjfi-n8g",
    "AIzaSyD8bd4o7sbcur8zwvcjOsPFpXasRrwCMOE",
    "AIzaSyAcjptSZoUsGfcQpTmC5PKRXOjaF6Gl3gU",
    "AIzaSyDtRmHcRDtawT2qv5KoTSBVzZ4aSEQHVyY"
]

# Base URL for the Google Gemini API (adjust if needed)
DEFAULT_BASE = "https://generativelanguage.googleapis.com/"
API_BASE_URL = os.environ.get("GEMINI_API_BASE_URL", DEFAULT_BASE)

# Optional: protect the server with a required header token
ACCESS_TOKEN = os.environ.get("ACCESS_TOKEN")

# Rotation state (simple in-memory state)
current_key_index = 0
# Store exhaustion time for each key (key_index -> timestamp)
key_states = {i: {"exhausted_until": 0} for i in range(len(API_KEYS))}

# Utility: get next active key index (skips keys marked exhausted)
def get_next_key_index():
    # >>> ESTA LINHA GLOBAL DEVE VIR PRIMEIRO <<<
    global current_key_index # Need global to modify the outer variable
    # ... o resto da função get_next_key_index ...
    if not API_KEYS:
        return None # No keys available

    now = time.time()
    for i in range(len(API_KEYS)):
        # Esta linha usa current_key_index, a declaração global deve estar ANTES.
        idx_to_check = (current_key_index + i) % len(API_KEYS)

        state = key_states.get(idx_to_check, {"exhausted_until": 0})

        if not state.get("exhausted_until", 0) or state["exhausted_until"] < now:
            current_key_index = (idx_to_check + 1) % len(API_KEYS)
            return idx_to_check

    return None # all keys exhausted currently

# Define a route to handle incoming requests for*
@app.route('/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
def proxy_request(subpath):
    print(f"Received request for /{subpath}")
    try:
        # Optionally enforce access token
        if ACCESS_TOKEN:
            provided_token = request.headers.get("X-Access-Token")
            if provided_token != ACCESS_TOKEN:
                print("Unauthorized access attempt")
                return Response("Unauthorized", status=401)

        target_url = f"{API_BASE_URL}/{subpath}"

        attempt_count = 0
        # Limit attempts to the number of available keys
        while attempt_count < len(API_KEYS):
            key_index = get_next_key_index()

            if key_index is None:
                 print("All API keys are exhausted – cannot fulfill request")
                 # (Optional: trigger alert/logging here)
                 return Response("All API keys exhausted (quota exceeded).", status=429)

            api_key = API_KEYS[key_index]
            
            # Add the API key to query parameters
            params = request.args.to_dict()
            params['key'] = api_key

            # Prepare headers for forwarding (copy all except hop-by-hop and restricted headers)
            forward_headers = {}
            for h, v in request.headers.items():
                lower_h = h.lower()
                # Filter out sensitive headers and the access token header used by the proxy itself
                if lower_h not in ["host", "cookie", "authorization", "x-access-token"]: 
                     forward_headers[h] = v
            
            # Get request body (handle potential empty body)
            request_body = request.get_data() if request.method in ['POST', 'PUT', 'PATCH'] else None

            print(f"Attempting with key index {key_index}...")

            # Forward the request using the requests library
            response = requests.request(
                method=request.method,
                url=target_url,
                params=params,
                headers=forward_headers,
                data=request_body,
                stream=True # Important for potentially large responses
            )

            # Check response status
            if response.status_code in [401, 403, 429]:
                print(f"Key {key_index} returned status {response.status_code}. Marking exhausted and retrying...")
                # Mark current key as exhausted (cooldown: e.g. 1 hour from now = 3600 seconds)
                key_states[key_index] = {"exhausted_until": time.time() + 3600} 
                attempt_count += 1
                # Close the failed response to release connection resources
                response.close()
                # Continue the while loop to try the next key
                continue 
            else:
                # Success or non-quota error, return this response
                print(f"Request successful or non-quota error with key {key_index}, status: {response.status_code}")
                
                # Prepare response headers for the client
                res_headers = {}
                for h, v in response.headers.items():
                    # Optional: Allow CORS if needed for web clients
                    # This needs to be set on the response from the proxy, not forwarded from client
                    if h.lower() != "access-control-allow-origin": # Avoid duplicating if already present
                         res_headers[h] = v
                res_headers["Access-Control-Allow-Origin"] = "*"


                # Use Flask's Response object with the response's raw data stream
                # ensure the response stream is consumed and returned correctly
                # Note: iter_content yields bytes, so need to return it directly or decode if necessary, 
                # but streaming bytes is usually what you want for proxying binary or large data.
                return Response(response.iter_content(chunk_size=8192), status=response.status_code, headers=res_headers)

        # If the loop finishes, it means all keys were attempted and failed with quota issues
        print("All API keys exhausted or invalid after retries. Returning error to client.")
        # Ensure to return a Flask Response object
        return Response("Error: All API keys exhausted or invalid after retries.", status=429)

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        # Return an internal server error
        return Response("Internal error in key rotator proxy.", status=500)

# Run the Flask app
if __name__ == '__main__':
    # Use host='0.0.0.0' to be accessible from other machines on the network
    # Use host='127.0.0.1' or 'localhost' to be accessible only locally
    # Choose a port, e.g., 5000
    
    # Note: The check 'if not API_KEYS' is now less relevant since they are hardcoded,
    # but could still catch an empty hardcoded list.
    if not API_KEYS:
         print("Proxy cannot start without API keys in the hardcoded list.")
    else:
        print(f"Starting Gemini Key Rotator Proxy on http://127.0.0.1:5000")
        if ACCESS_TOKEN:
            print(f"Access token required via X-Access-Token header: {ACCESS_TOKEN}") # Optional: print token value for setup ease
        # Set debug=True during development to see errors immediately
        # Set debug=False for production use
        app.run(host='127.0.0.1', port=5000, debug=True)