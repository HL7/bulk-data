#!/bin/bash

# requires validator_cli.jar in root directory
# https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar

for file in $(ls -d ./input/resources/*);
do
	java -jar validator_cli.jar $file -version 4.0
done