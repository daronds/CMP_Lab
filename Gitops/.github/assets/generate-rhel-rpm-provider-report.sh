#!/bin/bash

# Define paths
output_yaml="/tmp/output.yaml"
rpm_path="/tmp/cloudbolt*.rpm"

# Python script to parse RPM output
python_script="
import sys
lines = sys.stdin.read().split('\n')
result = ['']
for line in lines:
    if line and not line.startswith(('=', '>=', '<=')):
        result.append(line.split()[0])
print('\n'.join(result))
"

# Function to fetch and print RPM dependencies to a YAML file
fetch_dependencies() {
    echo "Starting the process..."
    echo "Removing any existing output file..."
    rm -f $output_yaml
    echo "Dependencies:" > $output_yaml
    echo "Parsing dependencies from the RPM..."
    dependencies=$(rpm --query --package --requires $rpm_path | grep -v rpmlib | grep -v "/bin/sh" | python3 -c "$python_script" | sort -u)
    for pkg in $dependencies; do
        if [ -n "$pkg" ]; then
            echo "Checking repository for package: $pkg..."
            # Check if the package exists in the repositories
            exists=$(dnf --cacheonly repoquery --quiet "$pkg")
            if [ "$exists" != "" ]; then
                repo=$(dnf --cacheonly repoquery --qf "%{repoid}" --latest-limit 1 --whatprovides "$pkg" | tail -1)
                echo "Package $pkg found in repository: $repo"
                echo "  - package: $pkg" >> $output_yaml
                echo "    repository: $repo" >> $output_yaml
            else
                echo "Package $pkg not found in any repository."
                echo "  - package: $pkg" >> $output_yaml
                echo "    repository: cloudbolt-software-cmp" >> $output_yaml
            fi
        fi
    done
}

# Fetch the dependencies
fetch_dependencies

echo "Process completed. Check the output in $output_yaml."
