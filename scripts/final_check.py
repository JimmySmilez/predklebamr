import pandas as pd
import os
import shutil

# Paths
base_path = os.path.expanduser('~/KP_Project')
seq_dir = os.path.join(base_path, 'sequences')
metadata_path = os.path.join(base_path, 'master_metadata_balanced.csv')
metrics_path = os.path.join(base_path, 'assembly_metrics.tsv')

# Load Metadata and remove duplicates
df = pd.read_csv(metadata_path)
df = df.drop_duplicates(subset=['genome_id']) 
print(f"Unique IDs in metadata: {len(df)}")

# Load Assembly Metrics and Apply QC Filters
df_metrics = pd.read_csv(metrics_path, sep='\t')
df_metrics.columns = df_metrics.columns.str.lower()

# Apply the thresholds defined in the workflow 
qc_pass = df_metrics[
    (df_metrics['n50'] > 50000) & 
    (df_metrics['number'] < 500) &
    (df_metrics['total_length'] >= 5000000) &
    (df_metrics['total_length'] <= 6500000)
].copy()

# Ensure the 'genome_id' is clean for matching
qc_pass['genome_id'] = qc_pass['filename'].apply(lambda x: os.path.basename(x).replace('.fasta', ''))
print(f"Genomes passing Quality Control: {len(qc_pass)}")

# Filter metadata to only include QC-passed and physically present files
actual_files = {f.replace('.fasta', '') for f in os.listdir(seq_dir) if f.endswith('.fasta')}
df_final_pool = df[
    (df['genome_id'].astype(str).isin(actual_files)) & 
    (df['genome_id'].astype(str).isin(qc_pass['genome_id'].astype(str)))
].copy()

# Sample exactly 3000 vs 3000 for the final dataset 
res = df_final_pool[df_final_pool['resistant_phenotype'] == 'Resistant']
sus = df_final_pool[df_final_pool['resistant_phenotype'] == 'Susceptible']

limit = min(len(res), len(sus), 3000)

df_final = pd.concat([
    res.sample(n=limit, random_state=42),
    sus.sample(n=limit, random_state=42)
])

# Move non-selected files to extra or trash
extra_dir = os.path.join(base_path, 'sequences_extra')
trash_dir = os.path.join(base_path, 'sequences_trash')
os.makedirs(extra_dir, exist_ok=True)
os.makedirs(trash_dir, exist_ok=True)

keep_ids = set(df_final['genome_id'].astype(str))
qc_pass_ids = set(qc_pass['genome_id'].astype(str))

for f in os.listdir(seq_dir):
    if not f.endswith('.fasta'): continue
    gid = f.replace('.fasta', '')
    src = os.path.join(seq_dir, f)
    
    if gid in keep_ids:
        continue # Stays in /sequences/
    elif gid in qc_pass_ids:
        shutil.move(src, os.path.join(extra_dir, f)) # High quality but surplus
    else:
        shutil.move(src, os.path.join(trash_dir, f)) # Failed QC

# Save final Metadata
df_final.to_csv(os.path.join(base_path, 'metadata_final_6000.csv'), index=False)
print(f"✅ FINAL DATASET READY: {len(df_final)} genomes ({limit} vs {limit})")