import pandas as pd
import os
import re
from crime_data_logger import create_logger
from crime_data_schema import get_crime_schema

# Try to import Excel reading dependencies with helpful error messages
try:
    import openpyxl  # For .xlsx files
except ImportError:
    print("Warning: openpyxl not installed. Install with: pip install openpyxl")
    print("This is needed to read .xlsx files")

try:
    import xlrd  # For .xls files
except ImportError:
    print("Warning: xlrd not installed. Install with: pip install xlrd")
    print("This is needed to read .xls files")

def consolidate_crime_data_efficiently(start_year, end_year, data_directory, output_filename, output_directory):
    """
    Reads and combines crime data from a specific directory, using a schema to identify
    columns and handling whitespace differences.
    
    Args:
        start_year (int): The starting year of the data files.
        end_year (int): The ending year of the data files.
        data_directory (str): The path to the folder containing the source Excel files.
        output_filename (str): The full path for the output CSV file.
        output_directory (str): The directory for saving log files.
    """
    print(f"Starting data extraction from: {data_directory}")
    
    # Initialize logger
    logger = create_logger("crime_data_processing_log.csv")
    
    # Load the crime data schema
    crime_schema = get_crime_schema()
    
    try:
        files_in_dir = os.listdir(data_directory)
        excel_files = [f for f in files_in_dir if f.endswith(('.xlsx', '.xls'))]
        print(f"\nFound {len(excel_files)} Excel files in directory.")
    except Exception as e:
        print(f"Error reading directory: {e}")
        return
    
    all_data_frames = [] 

    for year in range(start_year, end_year + 1):
        year_schema = crime_schema.get(year)
        if not year_schema:
            print(f"Warning: No schema definition found for year {year}. Skipping.")
            continue
            
        possible_patterns = [
            f"Table_8_Offenses_Known_to_Law_Enforcement_by_State_by_City_{year}",
            f"table_8_offenses_known_to_law_enforcement_by_state_by_city_{year}",
            f"Table8_Offenses_Known_to_Law_Enforcement_by_State_by_City_{year}",
            f"Table_08_Offenses_Known_to_Law_Enforcement_by_State_by_City_{year}",
            f"table08offensesknowntolawenforcementbystateandcity{year}",
            f"table8offensesknowntolawenforcementbystateandcity{year}",
        ]
        
        full_file_path = None
        for pattern in possible_patterns:
            for ext in ['.xlsx', '.xls']:
                file_path = os.path.join(data_directory, f"{pattern}{ext}")
                if os.path.exists(file_path):
                    full_file_path = file_path
                    break
            if full_file_path:
                break
        
        if full_file_path is None:
            for file in excel_files:
                if str(year) in file and 'table' in file.lower() and 'city' in file.lower():
                    full_file_path = os.path.join(data_directory, file)
                    break
        
        if full_file_path is None:
            print(f"Skipping: Cannot find file for year {year}")
            continue
        
        try:
            print(f"Processing: {os.path.basename(full_file_path)}")
            
            engine = 'openpyxl' if full_file_path.endswith('.xlsx') else 'xlrd'
            df_original = pd.read_excel(full_file_path, skiprows=3, engine=engine)
            df = df_original.copy()
            
            initial_row_count = len(df)
            logger.update_processing_stats(year, "Initial Load", initial_row_count, initial_row_count)
            
            # 1. Clean Column Names and Create a Normalized Mapping
            df.columns = [str(col).replace('\n', ' ').strip() for col in df.columns]
            
            def normalize_col_name(name):
                """Converts to lowercase and collapses all whitespace to single spaces."""
                return ' '.join(str(name).lower().split())

            normalized_to_original_cols = {normalize_col_name(col): col for col in df.columns}

            if len(df.columns) > 1:
                df.rename(columns={df.columns[0]: 'State', df.columns[1]: 'City'}, inplace=True)
            else:
                print(f"Warning: Not enough columns to process for {year}. Skipping.")
                continue

            # 2. Find Columns Using the Schema
            violent_crime_schema_name = normalize_col_name(year_schema["Violent Crime"])
            violent_crime_col = normalized_to_original_cols.get(violent_crime_schema_name)
            
            component_cols = []
            for component_name_from_schema in year_schema["Components"]:
                normalized_component = normalize_col_name(component_name_from_schema)
                actual_col = normalized_to_original_cols.get(normalized_component)
                if actual_col:
                    component_cols.append(actual_col)
                else:
                    print(f"    Info: Schema component '{component_name_from_schema}' not found in file for year {year}.")

            print(f"    Schema mapping for {year}:")
            if violent_crime_col:
                print(f"      - Violent Crime: '{year_schema['Violent Crime']}' -> '{violent_crime_col}'")
            print(f"      - Components found: {len(component_cols)}/{len(year_schema['Components'])}")

            # 3. Pre-clean all potential numeric columns
            numeric_cols = [col for col in [violent_crime_col] + component_cols if col and col in df.columns]
            if numeric_cols:
                for col in numeric_cols:
                    df[col] = pd.to_numeric(df[col].astype(str).str.replace(',', '', regex=False).str.extract(r'(\d+)', expand=False), errors='coerce')
                print("    Cleaned numeric columns, removing potential footnotes or text artifacts.")

            # 4. Reconstruct Missing Violent Crime Data (Robust Method)
            if violent_crime_col and component_cols:
                print("    Reconstructing violent crime totals using schema components...")
                component_sum = df[component_cols].fillna(0).sum(axis=1)

                # Step 1: Fill any rows where 'Violent Crime' is NaN.
                # This is the primary fix for the Albany issue.
                nan_mask = df[violent_crime_col].isna()
                if nan_mask.any():
                    df.loc[nan_mask, violent_crime_col] = component_sum[nan_mask]
                    print(f"    Filled {nan_mask.sum()} missing violent crime totals (NaNs) with component sum.")

                # Step 2: Correct any rows where 'Violent Crime' is 0 but components sum > 0.
                zero_mask = (df[violent_crime_col] == 0) & (component_sum > 0)
                if zero_mask.any():
                    df.loc[zero_mask, violent_crime_col] = component_sum[zero_mask]
                    print(f"    Corrected {zero_mask.sum()} zero-value violent crime totals with component sum.")

            elif violent_crime_col is None:
                print(f"Warning: Could not find schema-defined 'Violent crime' column in file for {year}. Skipping.")
                continue
            else:
                print("    Warning: Not all component crime columns were found via schema. Skipping reconstruction.")

            # 5. Clean State Names and Forward-Fill
            def clean_state_name(state):
                if pd.isna(state): return state
                return re.sub(r'[^A-Za-z\s]+$', '', str(state)).strip()
            df['State'] = df['State'].apply(clean_state_name)
            df['State'].ffill(inplace=True)

            # 6. Clean and Prepare Data - WITH LOGGING
            pre_missing_count = len(df)
            missing_mask = df[['City', violent_crime_col]].isna().any(axis=1)
            if missing_mask.any():
                dropped_missing = df[missing_mask].copy()
                logger.log_batch_dropped(year, dropped_missing, "Missing City or Violent Crime data", "Missing Data Filter")
            
            df.dropna(subset=['City', violent_crime_col], inplace=True)
            post_missing_count = len(df)
            logger.update_processing_stats(year, "Missing Data Filter", pre_missing_count, post_missing_count)
            
            df['City'] = df['City'].astype(str).apply(lambda x: re.sub(r'\d+$', '', x).strip())
            
            pre_numeric_count = len(df)
            numeric_fail_mask = df[violent_crime_col].isna()
            if numeric_fail_mask.any():
                dropped_numeric = df[numeric_fail_mask].copy()
                logger.log_batch_dropped(year, dropped_numeric, "Violent Crime value could not be converted to numeric", "Numeric Conversion")
            
            df.dropna(subset=[violent_crime_col], inplace=True)
            post_numeric_count = len(df)
            logger.update_processing_stats(year, "Numeric Conversion", pre_numeric_count, post_numeric_count)
            
            zero_crime_mask = df[violent_crime_col] == 0
            if zero_crime_mask.any():
                zero_crime_cities = df[zero_crime_mask].copy()
                for _, row in zero_crime_cities.iterrows():
                    logger.log_dropped_city(year, row['State'], row['City'], 
                                          "Zero violent crime reported (kept in data)", 
                                          row[violent_crime_col], "Zero Crime Check")
            
            pre_negative_count = len(df)
            negative_mask = df[violent_crime_col] < 0
            if negative_mask.any():
                dropped_negative = df[negative_mask].copy()
                logger.log_batch_dropped(year, dropped_negative, "Negative violent crime value", "Negative Values Filter")
                df = df[~negative_mask]
            
            post_negative_count = len(df)
            if pre_negative_count != post_negative_count:
                logger.update_processing_stats(year, "Negative Values Filter", pre_negative_count, post_negative_count)

            # 7. Extract the required data
            if 'State' in df.columns and 'City' in df.columns and violent_crime_col in df.columns:
                yearly_data = df[['State', 'City', violent_crime_col]].copy()
                yearly_data.columns = ['State', 'City', 'Violent Crime']
                yearly_data['Year'] = year
                all_data_frames.append(yearly_data)
                
                final_count = len(yearly_data)
                logger.update_processing_stats(year, "Final Output", final_count, final_count)
                
                logger.print_processing_summary(year)
                
            else:
                print(f"Warning: 'State', 'City', or '{violent_crime_col}' column not found after processing for {year}. Skipping.")
                
        except Exception as e:
            print(f"An error occurred while processing {os.path.basename(full_file_path)}: {e}")
            logger.log_dropped_city(year, "ERROR", f"File: {os.path.basename(full_file_path)}", 
                                  f"Processing error: {str(e)}", None, "File Processing Error")
    
    # Final consolidation and output
    if all_data_frames:
        final_df = pd.concat(all_data_frames, ignore_index=True)
        final_df.to_csv(output_filename, index=False)
        print(f"\nConsolidation complete. All data has been saved to '{output_filename}'")
        
        logger.print_final_summary()
        logger.save_log(output_directory)
        logger.create_summary_report(output_directory)
        
        print(f"\n📊 FINAL DATASET STATISTICS:")
        print(f"   Total cities: {len(final_df):,}")
        print(f"   Years covered: {final_df['Year'].min()}-{final_df['Year'].max()}")
        print(f"   States represented: {final_df['State'].nunique()}")
        print(f"   Average cities per year: {len(final_df) / final_df['Year'].nunique():.1f}")
        
    else:
        print("\nNo data was processed. Check the 'Skipping' or 'Warning' messages above.")
        logger.save_log(output_directory)
        logger.create_summary_report(output_directory)

# --- Main execution ---
if __name__ == "__main__":
    START_YEAR = 2012
    END_YEAR = 2023
    
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        script_dir = os.path.abspath('.')

    SOURCE_DATA_DIRECTORY = os.path.join(script_dir, "Data", "Crime")
    OUTPUT_DIRECTORY = os.path.join(script_dir, "Data")
    
    OUTPUT_FILENAME = "consolidated_violent_crime_data_2012-2023_reconstructed.csv"
    FULL_OUTPUT_PATH = os.path.join(OUTPUT_DIRECTORY, OUTPUT_FILENAME)
    
    if not os.path.exists(SOURCE_DATA_DIRECTORY):
         print(f"❌ Error: Source data directory not found at the expected path.")
         print(f"   Checked for: {SOURCE_DATA_DIRECTORY}")
    else:
        try:
            os.makedirs(OUTPUT_DIRECTORY, exist_ok=True)
            print(f"✅ Input data found at: {SOURCE_DATA_DIRECTORY}")
            print(f"✅ Output will be saved to: {FULL_OUTPUT_PATH}")
            consolidate_crime_data_efficiently(START_YEAR, END_YEAR, SOURCE_DATA_DIRECTORY, FULL_OUTPUT_PATH, OUTPUT_DIRECTORY)
        except OSError as e:
            print(f"❌ Error creating output directory '{OUTPUT_DIRECTORY}'. Please check permissions.")
            print(f"   System error: {e}")
