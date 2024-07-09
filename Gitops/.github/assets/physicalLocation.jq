select(.type == "match").data | 
{
  (.submatches[0].match.text | ascii_downcase) : {
    artifactLocation: { 
      uri: .path.text
    },
    region: { 
      startLine: (if .line_number > 0 then .line_number else 1 end), 
      startColumn: (if .submatches[0].start > 0 then .submatches[0].start else 1 end), 
      endLine: (if .line_number > 0 then .line_number else 1 end),
      endColumn: (if .submatches[0].end > 0 then .submatches[0].end else 1 end)
    }
  }
}
