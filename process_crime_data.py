import pandas as pd
import os
import re

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

def consolidate_crime_data_efficiently(start_year, end_year, data_directory, output_filename):
    """
    Reads and combines crime data from a specific directory, automatically handling
    both .xls and .xlsx file extensions and correctly processing hierarchical data.
    
    Args:
        start_year (int): The starting year of the data files.
        end_year (int): The ending year of the data files.
        data_directory (str): The path to the folder containing the source Excel files.
        output_filename (str): The name of the output CSV file.
    """
    print(f"Starting data extraction from: {data_directory}")
    
    # --- File discovery logic remains the same ---
    try:
        files_in_dir = os.listdir(data_directory)
        excel_files = [f for f in files_in_dir if f.endswith(('.xlsx', '.xls'))]
        print(f"\nFound {len(excel_files)} Excel files in directory.")
    except Exception as e:
        print(f"Error reading directory: {e}")
        return
    
    all_data_frames = [] # A list to hold each year's cleaned data

    # Loop through each year from start_year to end_year
    for year in range(start_year, end_year + 1):
        # --- File finding logic remains the same ---
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
            
            df = pd.read_excel(full_file_path, skiprows=3, engine=engine)
            
            # --- START: MODIFIED DATA PROCESSING LOGIC ---

            # 1. Clean and Rename Columns
            df.columns = [str(col).replace('\n', ' ').strip() for col in df.columns]
            
            # The first column usually contains States and Cities, the second is the City.
            # We rename them for clarity.
            if len(df.columns) > 1:
                df.rename(columns={df.columns[0]: 'State', df.columns[1]: 'City'}, inplace=True)
            else:
                print(f"Warning: Not enough columns to process for {year}. Skipping.")
                continue

            # 2. Find the Violent Crime Column (your original logic was good)
            violent_crime_col = None
            for col in df.columns:
                if 'violent' in col.lower() and 'crime' in col.lower():
                    violent_crime_col = col
                    break
            
            if violent_crime_col is None:
                print(f"Warning: Could not find 'Violent crime' column in file for {year}. Skipping.")
                continue

            # 3. Forward-fill the State names
            # This is the key step that fixes the issue.
            df['State'].ffill(inplace=True)

            # 4. Clean and Prepare Data
            # Remove rows that are not actual cities (e.g., state totals, blank rows)
            # A common way is to drop rows where 'City' is null.
            df.dropna(subset=['City', violent_crime_col], inplace=True)
            
            # Remove any footnote numbers from city names (e.g., "Aransas Pass7" -> "Aransas Pass")
            df['City'] = df['City'].astype(str).apply(lambda x: re.sub(r'\d+$', '', x).strip())

            # Ensure the crime data is numeric, converting non-numbers to NaN
            df[violent_crime_col] = pd.to_numeric(df[violent_crime_col], errors='coerce')
            df.dropna(subset=[violent_crime_col], inplace=True) # Drop rows where conversion failed

            # 5. Extract the required data
            if 'State' in df.columns and 'City' in df.columns:
                yearly_data = df[['State', 'City', violent_crime_col]].copy()
                yearly_data.columns = ['State', 'City', 'Violent Crime'] # Standardize names
                yearly_data['Year'] = year
                all_data_frames.append(yearly_data)
            else:
                print(f"Warning: 'State' or 'City' column not found after processing for {year}. Skipping.")

            # --- END: MODIFIED DATA PROCESSING LOGIC ---
                
        except Exception as e:
            print(f"An error occurred while processing {os.path.basename(full_file_path)}: {e}")
    
    # After the loop, combine all dataframes and save once. This is more efficient.
    if all_data_frames:
        final_df = pd.concat(all_data_frames, ignore_index=True)
        final_df.to_csv(output_filename, index=False)
        print(f"\nConsolidation complete. All data has been saved to '{output_filename}'")
    else:
        print("\nNo data was processed. Check the 'Skipping' or 'Warning' messages above.")

# --- Main execution ---
if __name__ == "__main__":
    START_YEAR = 2012
    # Set end year to 2023 as per your file list
    END_YEAR = 2023
    # Since we know the script is at /Users/jaydenrivera/Documents/Documents - Jayden's MacBook Air/1. Projects/research/
    # The data should be at the same level: /Users/jaydenrivera/Documents/Documents - Jayden's MacBook Air/1. Projects/research/AEASP-Research/Data/Crime
    
    # Let's use the script's location to find the data
    script_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Script is located at: {script_dir}")
    
    # The data should be in AEASP-Research/Data/Crime relative to the script location
    data_path = os.path.join(script_dir, "AEASP-Research", "Data", "Crime")
    print(f"Looking for data at: {data_path}")
    
    if os.path.exists(data_path):
        SOURCE_DATA_DIRECTORY = data_path
        print(f"✅ Found data directory!")
    else:
        print("❌ Data directory not found at expected location")
        
        # Let's see what's actually in the script's directory
        print(f"\nContents of script directory ({script_dir}):")
        try:
            for item in os.listdir(script_dir):
                item_path = os.path.join(script_dir, item)
                if os.path.isdir(item_path):
                    print(f"  📁 {item}/")
                    # If we find AEASP-Research folder, look inside it
                    if item == "AEASP-Research":
                        aeasp_path = item_path
                        print(f"    Contents of AEASP-Research:")
                        try:
                            for subitem in os.listdir(aeasp_path):
                                subitem_path = os.path.join(aeasp_path, subitem)
                                if os.path.isdir(subitem_path):
                                    print(f"      📁 {subitem}/")
                                    if subitem == "Data":
                                        data_folder_path = subitem_path
                                        print(f"        Contents of Data:")
                                        for dataitem in os.listdir(data_folder_path):
                                            if os.path.isdir(os.path.join(data_folder_path, dataitem)):
                                                print(f"          📁 {dataitem}/")
                                            else:
                                                print(f"          📄 {dataitem}")
                                else:
                                    print(f"      📄 {subitem}")
                        except Exception as e:
                            print(f"        Error reading AEASP-Research: {e}")
                else:
                    print(f"  📄 {item}")
        except Exception as e:
            print(f"Error listing script directory: {e}")
        
        # Default to relative path
        SOURCE_DATA_DIRECTORY = "AEASP-Research/Data/Crime"
    OUTPUT_CSV_FILE = "consolidated_violent_crime_data_2012-2023.csv"
    
    consolidate_crime_data_efficiently(START_YEAR, END_YEAR, SOURCE_DATA_DIRECTORY, OUTPUT_CSV_FILE)