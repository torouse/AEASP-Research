import pandas as pd
import os
import re
from crime_data_logger import create_logger

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
    Reads and combines crime data from a specific directory, automatically handling
    both .xls and .xlsx file extensions and correctly processing hierarchical data.
    
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
    
    try:
        files_in_dir = os.listdir(data_directory)
        excel_files = [f for f in files_in_dir if f.endswith(('.xlsx', '.xls'))]
        print(f"\nFound {len(excel_files)} Excel files in directory.")
    except Exception as e:
        print(f"Error reading directory: {e}")
        return
    
    all_data_frames = [] 

    for year in range(start_year, end_year + 1):
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
            df = df_original.copy()  # Keep original for logging purposes
            
            initial_row_count = len(df)
            logger.update_processing_stats(year, "Initial Load", initial_row_count, initial_row_count)
            
            # 1. Clean and Rename Columns
            df.columns = [str(col).replace('\n', ' ').strip() for col in df.columns]
            if len(df.columns) > 1:
                df.rename(columns={df.columns[0]: 'State', df.columns[1]: 'City'}, inplace=True)
            else:
                print(f"Warning: Not enough columns to process for {year}. Skipping.")
                continue

            # 2. Find the Main Violent Crime Column
            violent_crime_col = None
            for col in df.columns:
                if 'violent' in col.lower() and 'crime' in col.lower():
                    violent_crime_col = col
                    break
            
            if violent_crime_col is None:
                print(f"Warning: Could not find 'Violent crime' column in file for {year}. Skipping reconstruction.")
                continue
            
            # Reconstruct Missing Violent Crime Data
            def find_col_by_keywords(keywords, all_columns):
                for col in all_columns:
                    if all(kw in col.lower() for kw in keywords):
                        return col
                return None

            murder_col = find_col_by_keywords(['murder'], df.columns)
            rape_col = find_col_by_keywords(['rape'], df.columns)
            robbery_col = find_col_by_keywords(['robbery'], df.columns)
            assault_col = find_col_by_keywords(['aggravated', 'assault'], df.columns)
            component_cols = [col for col in [murder_col, rape_col, robbery_col, assault_col] if col]

            if violent_crime_col and len(component_cols) == 4:
                print("    Found component columns. Checking for missing violent crime totals.")
                df[violent_crime_col] = pd.to_numeric(df[violent_crime_col], errors='coerce')
                for col in component_cols:
                    df[col] = pd.to_numeric(df[col], errors='coerce')
                component_sum = df[component_cols].fillna(0).sum(axis=1)
                missing_violent_crime_mask = (df[violent_crime_col].isna()) | (df[violent_crime_col] == 0)
                update_mask = missing_violent_crime_mask & (component_sum > 0)
                if update_mask.any():
                    df.loc[update_mask, violent_crime_col] = component_sum[update_mask]
                    print(f"    Reconstructed violent crime total for {update_mask.sum()} rows.")
                else:
                    print("    No rows required violent crime reconstruction.")
            else:
                print("    Warning: Could not find all necessary crime columns. Skipping reconstruction for this file.")

            # 3. Clean State Names and Forward-Fill
            def clean_state_name(state):
                if pd.isna(state): return state
                return re.sub(r'[^A-Za-z\s]+$', '', str(state)).strip()
            df['State'] = df['State'].apply(clean_state_name)
            df['State'].ffill(inplace=True)

            # 4. Clean and Prepare Data - WITH LOGGING
            
            # Step 4a: Remove rows with missing City or violent crime data
            pre_missing_count = len(df)
            missing_mask = df[['City', violent_crime_col]].isna().any(axis=1)
            if missing_mask.any():
                dropped_missing = df[missing_mask].copy()
                logger.log_batch_dropped(year, dropped_missing, "Missing City or Violent Crime data", "Missing Data Filter")
            
            df.dropna(subset=['City', violent_crime_col], inplace=True)
            post_missing_count = len(df)
            logger.update_processing_stats(year, "Missing Data Filter", pre_missing_count, post_missing_count)
            
            # Step 4b: Clean city names
            df['City'] = df['City'].astype(str).apply(lambda x: re.sub(r'\d+$', '', x).strip())
            
            # Step 4c: Convert violent crime to numeric and log conversion failures
            pre_numeric_count = len(df)
            df[violent_crime_col] = pd.to_numeric(df[violent_crime_col], errors='coerce')
            
            # Identify rows that failed numeric conversion
            numeric_fail_mask = df[violent_crime_col].isna()
            if numeric_fail_mask.any():
                dropped_numeric = df[numeric_fail_mask].copy()
                logger.log_batch_dropped(year, dropped_numeric, "Violent Crime value could not be converted to numeric", "Numeric Conversion")
            
            df.dropna(subset=[violent_crime_col], inplace=True)
            post_numeric_count = len(df)
            logger.update_processing_stats(year, "Numeric Conversion", pre_numeric_count, post_numeric_count)
            
            # Step 4d: Optional - Remove zero violent crime entries (log but don't drop by default)
            zero_crime_mask = df[violent_crime_col] == 0
            if zero_crime_mask.any():
                zero_crime_cities = df[zero_crime_mask].copy()
                for _, row in zero_crime_cities.iterrows():
                    logger.log_dropped_city(year, row['State'], row['City'], 
                                          "Zero violent crime reported (kept in data)", 
                                          row[violent_crime_col], "Zero Crime Check")
            
            # Step 4e: Remove negative violent crime values
            pre_negative_count = len(df)
            negative_mask = df[violent_crime_col] < 0
            if negative_mask.any():
                dropped_negative = df[negative_mask].copy()
                logger.log_batch_dropped(year, dropped_negative, "Negative violent crime value", "Negative Values Filter")
                df = df[~negative_mask]
            
            post_negative_count = len(df)
            if pre_negative_count != post_negative_count:
                logger.update_processing_stats(year, "Negative Values Filter", pre_negative_count, post_negative_count)

            # 5. Extract the required data
            if 'State' in df.columns and 'City' in df.columns:
                yearly_data = df[['State', 'City', violent_crime_col]].copy()
                yearly_data.columns = ['State', 'City', 'Violent Crime']
                yearly_data['Year'] = year
                all_data_frames.append(yearly_data)
                
                final_count = len(yearly_data)
                logger.update_processing_stats(year, "Final Output", final_count, final_count)
                
                # Print processing summary for this year
                logger.print_processing_summary(year)
                
            else:
                print(f"Warning: 'State' or 'City' column not found after processing for {year}. Skipping.")
                
        except Exception as e:
            print(f"An error occurred while processing {os.path.basename(full_file_path)}: {e}")
            # Log the error
            logger.log_dropped_city(year, "ERROR", f"File: {os.path.basename(full_file_path)}", 
                                  f"Processing error: {str(e)}", None, "File Processing Error")
    
    # Final consolidation and output
    if all_data_frames:
        final_df = pd.concat(all_data_frames, ignore_index=True)
        final_df.to_csv(output_filename, index=False)
        print(f"\nConsolidation complete. All data has been saved to '{output_filename}'")
        
        # Generate final summary and save logs
        logger.print_final_summary()
        logger.save_log(output_directory)
        logger.create_summary_report(output_directory)
        
        # Print final dataset stats
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
    
    # --- Path Configuration (Robust Method) ---
    # Get the absolute path to the directory where the script is located.
    # This makes the script independent of the current working directory.
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        # Fallback for interactive environments like Jupyter
        script_dir = os.path.abspath('.')

    # Construct absolute paths for source and output directories
    # The data is in a subfolder relative to the script's location.
    SOURCE_DATA_DIRECTORY = os.path.join(script_dir, "Data", "Crime")
    OUTPUT_DIRECTORY = os.path.join(script_dir, "Data")
    
    OUTPUT_FILENAME = "consolidated_violent_crime_data_2012-2023_reconstructed.csv"
    FULL_OUTPUT_PATH = os.path.join(OUTPUT_DIRECTORY, OUTPUT_FILENAME)
    
    # --- Pre-run Checks ---
    # Check if the source data directory exists using the new absolute path
    if not os.path.exists(SOURCE_DATA_DIRECTORY):
         print(f"❌ Error: Source data directory not found at the expected path.")
         print(f"   Checked for: {SOURCE_DATA_DIRECTORY}")
    else:
        # Ensure the output directory exists. If not, create it.
        try:
            os.makedirs(OUTPUT_DIRECTORY, exist_ok=True)
            print(f"✅ Input data found at: {SOURCE_DATA_DIRECTORY}")
            print(f"✅ Output will be saved to: {FULL_OUTPUT_PATH}")
            # Call the main function with the output directory for logging
            consolidate_crime_data_efficiently(START_YEAR, END_YEAR, SOURCE_DATA_DIRECTORY, FULL_OUTPUT_PATH, OUTPUT_DIRECTORY)
        except OSError as e:
            print(f"❌ Error creating output directory '{OUTPUT_DIRECTORY}'. Please check permissions.")
            print(f"   System error: {e}")