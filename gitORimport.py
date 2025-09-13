import requests
import os

# URLs for the raw files on GitHub
files = {
    "IREC_2025_M6000ST-0.ork": "https://raw.githubusercontent.com/RIT-Launch-Initiative/irec-2025-analysis/main/IREC_2025_M6000ST-0.ork",
    "IREC_2025_ROCKET.ork": "https://raw.githubusercontent.com/RIT-Launch-Initiative/irec-2025-analysis/main/IREC_2025_ROCKET.ork",
}

# Create a folder to store the files
output_folder = "irec_files"
os.makedirs(output_folder, exist_ok=True)

# Download each file
for name, url in files.items():
    response = requests.get(url)
    if response.status_code == 200:
        file_path = os.path.join(output_folder, name)
        with open(file_path, "wb") as f:
            f.write(response.content)
        print(f"✅ Downloaded {name} → {file_path}")
    else:
        print(f"❌ Failed to download {name} (status code {response.status_code})")
