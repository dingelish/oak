import re
import sys
import csv

def load_line_counts(csv_file: str) -> dict[str, int]:
    """
    Loads directory-line count pairs from a CSV file.

    Args:
        csv_file: Path to the CSV file.

    Returns:
        A dictionary mapping directory paths (str) to line counts (int).
        Returns an empty dictionary if the file is not found or if there's
        an error parsing the CSV.
    """
    line_counts = {}
    try:
        with open(csv_file, 'r', newline='') as f:
            reader = csv.reader(f)
            for row in reader:
                try:
                    directory = row[0].strip()  # Remove potential whitespace
                    line_count_str = row[1].strip()

                    if line_count_str.isdigit():
                         line_count = int(line_count_str)
                         line_counts[directory] = line_count
                    elif line_count_str.upper() == "N/A":
                        line_counts[directory] = -1 # Use -1 for N/A
                    # else ignore the line, maybe log it.

                except (IndexError, ValueError):
                    # Handle malformed rows (e.g., missing columns, non-integer line count)
                    print(f"Warning: Skipping malformed row: {row}", file=sys.stderr)
    except FileNotFoundError:
        print(f"Error: CSV file not found: {csv_file}", file=sys.stderr)
    return line_counts


def process_file(input_file: str, output_file: str, line_counts: dict[str, int]):
    """
    Processes the input file, replacing directory names with their line counts
    (looked up from the provided dictionary).
    """
    try:
        with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
            for line in infile:
                match = re.match(r'^(.*?)\s*=\s*"([^"]*)"(.*)$', line)
                if match:
                    label, directory, rest_of_line = match.groups()
                    directory = directory.strip() # remove potential whitespaces
                    line_count = line_counts.get(directory)

                    if line_count is not None:
                        if line_count == -1:
                           new_line = f'{label} = "{directory}, N/A"{rest_of_line}\n'
                        else:
                            new_line = f'{label} = "{directory}, {line_count}"{rest_of_line}\n'

                    else:
                        new_line = f'{label} = "{directory}, Not Found"{rest_of_line}\n' # count not found
                    outfile.write(new_line)
                else:
                    outfile.write(line)  # Write lines that don't match as-is

    except FileNotFoundError:
        print(f"Error: Input file not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    except IOError as e:
        print(f"Error reading/writing files: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) != 4:
        print("Usage: python script.py <input_file> <output_file> <csv_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    csv_file = sys.argv[3]

    line_counts = load_line_counts(csv_file)
    if not line_counts:  # Check for empty dictionary (file not found or error)
        sys.exit(1)  # Exit if loading failed

    process_file(input_file, output_file, line_counts)


if __name__ == "__main__":
    main()
