{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Grype",
          "rules": [ .matches[] | select(.vulnerability.cvss[0].metrics.baseScore >= 7) |
            {
              "id": .vulnerability.id,
              "name": ("" + .vulnerability.namespace + "/" + .vulnerability.id),
              "shortDescription": { 
                "text": ("" + .vulnerability.namespace + "/" + .vulnerability.id)
              },
              "fullDescription": { "text": .vulnerability.description },
              "help": { 
                "text": ("Upgrade to " + .vulnerability.fix.versions[0] + " to fix this vulnerability."),
                "markdown": ("Upgrade to " + .vulnerability.fix.versions[0] + " to fix this vulnerability.") 
              },
              "properties" : {
                 "tags" : [
                   "security", 
                   .vulnerability.namespace
                 ],
                 "id" : .vulnerability.id,
                 "kind" : .matchDetails[0].matcher,
                 "name" : .artifact.name,
                 "problem.severity" : "warning",
                 "precision": "medium",
                 "security-severity" : (.vulnerability.cvss[0].metrics.baseScore | tostring),
              }
            }
          ] | unique_by(.id)
        }
      },
      "results": [ .matches[] | select(.vulnerability.cvss[0].metrics.baseScore >= 7) |
      {
        "ruleId": .vulnerability.id,
        "message": {
          "text": (.vulnerability.id + " " + .artifact.name + ": " + .vulnerability.description)
        },
        "locations": [
          {
            "physicalLocation": (
            if $pL[.artifact.name | ascii_downcase] 
            then $pL[.artifact.name | ascii_downcase] 
            else {
              "artifactLocation":  {
                "uri": "./cloudbolt_installer/01-all-yum-pkgs/yumrequirements.txt"
              },
              "region": {
                "startLine": 1,
                "startColumn": 1, 
                "endLine": 1,
                "endColumn": 1
              }
            } end )
          }
        ],
      }
      ]
    }
  ]
} 
