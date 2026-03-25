akshay9826@testvm:~$ cat fetch_secret_v2.sh
#!/bin/bash

KV_NAME=$1
SECRET_NAME=$2
CLIENT_ID="f79a95f8-d1cc-4759-9f88-2fabca408e61"

# Step 1: Get token from IMDS
TOKEN=$(curl -s -H "Metadata: true" \
"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net&client_id=${CLIENT_ID}" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

# Step 2: Validate token
if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to get token" >&2
  exit 1
fi

# Step 3: Fetch secret
SECRET=$(curl -s -H "Authorization: Bearer $TOKEN" \
"https://${KV_NAME}.vault.azure.net/secrets/${SECRET_NAME}?api-version=7.3" \
| python3 -c "import sys, json; print(json.load(sys.stdin).get('value',''))" 2>/dev/null)

# Step 4: Validate secret
if [ -z "$SECRET" ]; then
  echo "ERROR: Failed to fetch secret" >&2
  exit 1
fi

# Output secret
echo $SECRET
akshay9826@testvm:~$ cat get_kv_secret.sh
#!/bin/bash

KV_NAME=$1
SECRET_NAME=$2

# Fetch secret value using managed identity
az keyvault secret show \
  --vault-name "$KV_NAME" \
  --name "$SECRET_NAME" \
  --query value -o tsv
akshay9826@testvm:~$ cat test.sh
DB_PASS=$(./fetch_secret_v2.sh testkvajain test)

if [ ! -z "$DB_PASS" ]; then
  echo "WORKED"
  TEST_VAR="Secret fetched successfully"
  echo $DB_PASS
else
  echo "NOT WORKED"
fi
akshay9826@testvm:~$ ./test.sh
WORKED
1234
akshay9826@testvm:~$
