
import os

def delete_large_files(directory=".", size_limit_gb=3):
    size_limit_bytes = size_limit_gb * 1024 * 1024 * 1024  # Convert GB to bytes
    
    print(f"Searching for files larger than {size_limit_gb}GB in '{os.path.abspath(directory)}' (recursively)...")

    found_files = []
    for root, _, files in os.walk(directory):
        for filename in files:
            filepath = os.path.join(root, filename)
            try:
                if os.path.isfile(filepath):
                    file_size = os.path.getsize(filepath)
                    if file_size > size_limit_bytes:
                        found_files.append((filepath, file_size))
            except OSError as e:
                print(f"Error accessing {filepath}: {e}")
    
    if not found_files:
        print("No files larger than specified limit found.")
        return

    print("\nFound the following large files:")
    for filepath, file_size in found_files:
        print(f"- {filepath} ({file_size / (1024*1024*1024):.2f} GB)")

    confirmation = input("\nDo you want to delete these files? (yes/no): ")
    if confirmation.lower() == 'yes':
        for filepath, _ in found_files:
            try:
                os.remove(filepath)
                print(f"Deleted: {filepath}")
            except OSError as e:
                print(f"Error deleting {filepath}: {e}")
    else:
        print("File deletion cancelled.")

if __name__ == "__main__":
    delete_large_files()

