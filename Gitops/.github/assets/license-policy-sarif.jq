{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Grype",
          "rules": [ .[] |
            {
              "id": .license,
              "name": (.license),
              "shortDescription": { 
                "text": ("The license " + .license + " is not allowed by CloudBolt's license policy.")
              },
              "fullDescription": { 
                "text": ("The license " + .license + " is not allowed by CloudBolt's license policy.")
                },
              "help": { 
                "text": ("The license " + .license + " is not allowed by CloudBolt's license policy. Please either remove this package or contact legal and update CloudBoltSoftware/policy-as-code repo to allow this license in this case.")
              },
              "properties" : {
                 "tags" : [
                   "license", 
                   .license
                 ],
                 "id" : .name,
                 "kind" : "license violation",
                 "name" : .name,
                 "problem.severity" : "high",
                 "precision": "high",
                 "security-severity" : 7, 
              }
            }
          ] | unique_by(.id)
        }
      },
      "results": [ .[] |
      {
        "ruleId": .name,
        "message": {
          "text": ("The license " + .license + " is not allowed by CloudBolt's license policy.")
        },
        "locations": [
          {
            "physicalLocation": {
              "artifactLocation":  {
                # Fix location to be correct
                "uri": "./cloudbolt_installer/01-all-yum-pkgs/yumrequirements.txt"
              },
              "region": {
                "startLine": 1,
                "startColumn": 1, 
                "endLine": 1,
                "endColumn": 1
              }
            }  
          }
        ],
      }
      ]
    }
  ]
} 
