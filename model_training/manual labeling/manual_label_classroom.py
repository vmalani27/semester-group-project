import pandas as pd

# Load your classroom data
classroom_data = pd.read_csv('filtered_dataset.csv')

# Create empty DataFrames for labeled data
target_batch_data = pd.DataFrame(columns=classroom_data.columns)
unlabeled_data = pd.DataFrame(columns=classroom_data.columns)

# Define the target columns for multi-label classification (batches, classes, year)
columns = ['Batch1', 'Batch2', 'Batch3', 'Batch4', 'ClassA', 'ClassB', 'Year']
for col in columns:
    classroom_data[col] = 0  # Initialize all to 0

# Open the error log to capture any problematic entries
with open('error_log.txt', 'w', encoding='utf-8') as error_log:
    # Loop through classroom data
    for index, row in classroom_data.iterrows():
        try:
            print(f"\nEntry {index + 1}")
            print("Course Name:", row['Course Name'])
            print("Task Label:", row['task label'])  # Assignment or Announcement
            print("Title:", row['Title'])  # Limit display for readability

            # Ask the user which batches/classes the task applies to
            for col in columns:
                user_input = input(f"Does this task apply to {col}? (y/n): ").lower()
                if user_input == 'y':
                    classroom_data.at[index, col] = 1  # Set the corresponding batch/class to 1

            print("Labels updated for this entry.")
            target_batch_data = pd.concat([target_batch_data, pd.DataFrame([row])], ignore_index=True)
        
        except Exception as e:
            print(f"Error processing entry {index + 1}: {e}")
            # Log the problematic entry for further investigation
            error_log.write(f"Error with entry {index + 1}:\nCourse Name: {row['Course Name']}\nTitle: {row['Title']}\nError: {e}\n\n")
            
            # Add the problematic entry to the separate DataFrame
            unlabeled_data = pd.concat([unlabeled_data, pd.DataFrame([row])], ignore_index=True)

# Save the updated data
classroom_data.to_csv('labeled_classroom_data.csv', index=False)
target_batch_data.to_csv('labeled_batch_data.csv', index=False)
unlabeled_data.to_csv('problematic_entries.csv', index=False)
