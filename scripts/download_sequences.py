import pandas as pd
import subprocess
import os
import time

# Configuration
metadata_file = os.path.expanduser('~/KP_Project/master_metadata_balanced.csv')
seq_dir = os.path.expanduser('~/KP_Project/sequences')
os.makedirs(seq_dir, exist_ok=True)

# Load balanced metadata
df = pd.read_csv(metadata_file)
id_col = 'Genome ID' if 'Genome ID' in df.columns else 'genome_id'

print(f"🚀 Starting download of {len(df)} genomes...")

for i, gid in enumerate(df[id_col]):
    path = f"{seq_dir}/{gid}.fasta"
    
    # Check if we already have this file to save time
    if not os.path.exists(path):
        with open(path, "w") as f:
            # Using the absolute path to the tool
            result = subprocess.run(
                ["/usr/share/bvbrc-cli/deployment/bin/p3-genome-fasta", str(gid)],
                stdout=f, stderr=subprocess.PIPE, text=True
            )
        
        # Check if the file is empty (server error)
        if os.path.getsize(path) == 0:
            os.remove(path)
            print(f"⚠️ Failed to download {gid}, will retry next time.")
        
        # Status update every 50 files
        if (i+1) % 50 == 0:
            print(f"Status: {i+1}/{len(df)} sequences processed...")
            # Slight sleep to reduce workload on the server
            time.sleep(1)

print("\n🎉 ALL DONE! Your sequence library is ready in ~/KP_Project/sequences/")
