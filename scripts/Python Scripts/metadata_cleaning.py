import pandas as pd
import os

input_path = os.path.expanduser('~/KP_Project/master_metadata.csv')
output_path = os.path.expanduser('~/KP_Project/master_metadata_balanced.csv')

# Load and handle quotes/spacing
df = pd.read_csv(input_path, quotechar='"', skipinitialspace=True)

# Filter for only the clear labels
res = df[df['resistant_phenotype'] == 'Resistant']
sus = df[df['resistant_phenotype'] == 'Susceptible']

# Take all 4,058 Resistant isolates
# Take a random 4,058 Susceptible isolates to match
sus_sampled = sus.sample(n=len(res), random_state=42)

# Combine and save
final_df = pd.concat([res, sus_sampled])
final_df.to_csv(output_path, index=False)

print(f"--- Final Balanced Dataset ---")
print(final_df['resistant_phenotype'].value_counts())
print(f"\n✅ Created: {output_path}")
