# Create the directory structure
New-Item -ItemType Directory -Force -Path bcrypt_layer\python

# Install bcrypt into the python directory
pip install -r bcrypt_layer\requirements.txt -t bcrypt_layer\python

Write-Output "bcrypt layer has been installed successfully."