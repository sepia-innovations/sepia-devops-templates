import json
import sys


def read_repo_and_service(repo_name, branch_name, json_file):
    """
    Reads repo and service information from a JSON file.

    Args:
        repo_name: The name of the service to query.
        branch_name: The branch name to query.
        json_file: Path to the JSON file containing the mapping data.

    Returns:
        A comma-separated string containing the list of repos and services,
        or None if no data is found.
    """
    service_data = []
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: JSON file {json_file} not found.")
        service_data = [repo_name]

    try:
        service_data = data["repoAndServiceMappingOverwrite"][repo_name][branch_name]
    except KeyError:
        service_data = [repo_name]

    return ",".join(service_data)


if __name__ == "__main__":
    # Check if correct number of arguments are provided
    if len(sys.argv) != 4:
        print("Usage: python script_name.py <repo_name> <branch_name> <json_file>")
        sys.exit(1)

    i_repo_name = sys.argv[1]
    i_branch_name = sys.argv[2]
    i_json_file = sys.argv[3]

    REPO_AND_SERVICE = read_repo_and_service(i_repo_name, i_branch_name, i_json_file)
    if REPO_AND_SERVICE:
        REPO_AND_SERVICE=str(REPO_AND_SERVICE)
        print(REPO_AND_SERVICE.replace(" ", ""))
    else:
        print("")
