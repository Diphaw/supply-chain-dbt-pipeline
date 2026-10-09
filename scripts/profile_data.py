import pandas as pd

file_path = 'raw_data/DataCoSupplyChainDataset.csv'
df = pd.read_csv(file_path, encoding='latin1', nrows=5)

print(f'Total Kolom: {len(df.columns)}')
print('\nPreview Semua Kolom:')
for i, col in enumerate(df.columns, start=1):
    print(f'{i}. {col}')
