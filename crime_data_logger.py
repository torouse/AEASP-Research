import pandas as pd
import os
from datetime import datetime

class CrimeDataLogger:
    """
    A logging utility for tracking dropped cities during crime data processing.
    Provides detailed logs and summary statistics for data quality assessment.
    """
    
    def __init__(self, log_filename=None):
        """
        Initialize the logger.
        
        Args:
            log_filename (str, optional): Custom filename for the log file.
                                        If None, auto-generates with timestamp.
        """
        if log_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_filename = f"crime_data_processing_log_{timestamp}.csv"
        
        self.log_filename = log_filename
        self.dropped_cities = []
        self.processing_stats = {}
        
    def log_dropped_city(self, year, state, city, reason, original_value=None, step=None):
        """
        Log a dropped city with details.
        
        Args:
            year (int): Year of the data
            state (str): State name
            city (str): City name
            reason (str): Reason for dropping
            original_value (str, optional): The problematic original value
            step (str, optional): Which processing step caused the drop
        """
        self.dropped_cities.append({
            'Year': year,
            'State': state if pd.notna(state) else 'UNKNOWN',
            'City': city if pd.notna(city) else 'UNKNOWN',
            'Reason': reason,
            'Original_Value': str(original_value) if original_value is not None else '',
            'Processing_Step': step if step else 'Unknown',
            'Timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    
    def log_batch_dropped(self, year, dropped_df, reason, step=None):
        """
        Log multiple dropped cities from a DataFrame.
        
        Args:
            year (int): Year of the data
            dropped_df (pd.DataFrame): DataFrame containing dropped cities
            reason (str): Reason for dropping
            step (str, optional): Which processing step caused the drop
        """
        for _, row in dropped_df.iterrows():
            state = row.get('State', 'UNKNOWN')
            city = row.get('City', 'UNKNOWN')
            # Try to get the problematic value from the row
            original_value = None
            if 'Violent Crime' in row:
                original_value = row['Violent Crime']
            elif len(row) > 2:
                original_value = row.iloc[2]  # First data column after State/City
                
            self.log_dropped_city(year, state, city, reason, original_value, step)
    
    def update_processing_stats(self, year, step, total_before, total_after):
        """
        Update processing statistics for a given step.
        
        Args:
            year (int): Year of the data
            step (str): Processing step name
            total_before (int): Count before processing
            total_after (int): Count after processing
        """
        if year not in self.processing_stats:
            self.processing_stats[year] = {}
        
        self.processing_stats[year][step] = {
            'before': total_before,
            'after': total_after,
            'dropped': total_before - total_after,
            'retention_rate': (total_after / total_before * 100) if total_before > 0 else 0
        }
    
    def print_processing_summary(self, year):
        """Print a summary of processing statistics for a given year."""
        if year not in self.processing_stats:
            print(f"    No processing stats available for {year}")
            return
        
        print(f"    Processing Summary for {year}:")
        total_original = None
        total_final = None
        
        for step, stats in self.processing_stats[year].items():
            if total_original is None:
                total_original = stats['before']
            total_final = stats['after']
            
            print(f"      {step}: {stats['before']} → {stats['after']} "
                 f"(-{stats['dropped']}, {stats['retention_rate']:.1f}% retained)")
        
        if total_original and total_final:
            overall_retention = (total_final / total_original * 100)
            print(f"    Overall: {total_original} → {total_final} "
                 f"({overall_retention:.1f}% overall retention)")
    
    def get_summary_statistics(self):
        """Generate summary statistics about dropped cities."""
        if not self.dropped_cities:
            return "No cities were dropped during processing."
        
        df = pd.DataFrame(self.dropped_cities)
        
        summary = {
            'total_dropped': len(df),
            'by_year': df['Year'].value_counts().to_dict(),
            'by_reason': df['Reason'].value_counts().to_dict(),
            'by_step': df['Processing_Step'].value_counts().to_dict(),
            'by_state': df['State'].value_counts().head(10).to_dict(),
            'most_common_reasons': df['Reason'].value_counts().head(5).to_dict()
        }
        
        return summary
    
    def print_final_summary(self):
        """Print a comprehensive summary of all processing."""
        print("\n" + "="*60)
        print("FINAL PROCESSING SUMMARY")
        print("="*60)
        
        if not self.dropped_cities:
            print("✅ No cities were dropped during processing!")
            return
        
        summary = self.get_summary_statistics()
        
        print(f"📊 Total cities dropped: {summary['total_dropped']}")
        
        print(f"\n📅 Drops by year:")
        for year, count in sorted(summary['by_year'].items()):
            print(f"    {year}: {count} cities")
        
        print(f"\n❌ Most common reasons for dropping:")
        for reason, count in summary['most_common_reasons'].items():
            print(f"    {reason}: {count} cities")
        
        print(f"\n🏛️ States with most drops:")
        for state, count in summary['by_state'].items():
            print(f"    {state}: {count} cities")
        
        print(f"\n📋 Log saved to: {self.log_filename}")
    
    def save_log(self, output_directory="."):
        """
        Save the detailed log to a CSV file.
        
        Args:
            output_directory (str): Directory to save the log file
        """
        if not self.dropped_cities:
            print("No dropped cities to log.")
            return
        
        log_path = os.path.join(output_directory, self.log_filename)
        df = pd.DataFrame(self.dropped_cities)
        df.to_csv(log_path, index=False)
        print(f"Detailed log saved to: {log_path}")
    
    def create_summary_report(self, output_directory="."):
        """
        Create a summary report of processing statistics.
        
        Args:
            output_directory (str): Directory to save the report
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f"crime_data_processing_summary_{timestamp}.txt"
        report_path = os.path.join(output_directory, report_filename)
        
        with open(report_path, 'w') as f:
            f.write("CRIME DATA PROCESSING SUMMARY REPORT\n")
            f.write("=" * 50 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            if self.processing_stats:
                f.write("PROCESSING STATISTICS BY YEAR:\n")
                f.write("-" * 30 + "\n")
                for year in sorted(self.processing_stats.keys()):
                    f.write(f"\nYear {year}:\n")
                    for step, stats in self.processing_stats[year].items():
                        f.write(f"  {step}: {stats['before']} → {stats['after']} "
                               f"({stats['retention_rate']:.1f}% retained)\n")
            
            if self.dropped_cities:
                summary = self.get_summary_statistics()
                f.write(f"\nDROPPED CITIES SUMMARY:\n")
                f.write("-" * 30 + "\n")
                f.write(f"Total dropped: {summary['total_dropped']}\n\n")
                
                f.write("By Reason:\n")
                for reason, count in summary['by_reason'].items():
                    f.write(f"  {reason}: {count}\n")
                
                f.write(f"\nBy Year:\n")
                for year, count in sorted(summary['by_year'].items()):
                    f.write(f"  {year}: {count}\n")
        
        print(f"Summary report saved to: {report_path}")

# Helper function for easy integration
def create_logger(log_filename=None):
    """
    Factory function to create a CrimeDataLogger instance.
    
    Args:
        log_filename (str, optional): Custom filename for the log
    
    Returns:
        CrimeDataLogger: Configured logger instance
    """
    return CrimeDataLogger(log_filename)