# flip-cloud.sh
#!/bin/bash

CLOUD="$1"
if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 [aws|azure|gcp]"
  exit 1
fi

# Remove cloud-specific files from the current directory (not subdirectories)
find . -maxdepth 1 -type f \( -name "*aws*" -o -name "*azure*" -o -name "*gcp*" \) -exec rm -f {} +

# Copy common files (if not already present)
cp -n common/* .

# Copy selected cloud's files into the current directory
cp $CLOUD/* .

echo "Switched to $CLOUD."
