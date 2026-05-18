!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-list-tools-response-event () () () ()))
  ("mcp_list_tools_response"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-list-tools-response-event () () () ())))
  ("{\"type\":\"mcp_list_tools_response\",\"tools\":{},\"resources\":{},\"resource_templates\":{},\"auth_statuses\":{}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-list-tools-response-event
        ((codex:mcp-map-entry
           "memory/read_graph"
           (codex:mcp-tool
             "read_graph"
             "Read graph"
             "Read entities and relations."
             (JsonObject
               ((JsonPair "type" (JsonString "object"))))
             (JsonObject
               ((JsonPair "type" (JsonString "object"))))
             CodexAbsent
             CodexAbsent
             CodexAbsent)))
        ((codex:mcp-map-entry
           "memory"
           ((codex:mcp-resource
              CodexAbsent
              "Graph snapshot"
              "application/json"
              "graph"
              42
              "Graph"
              "memory://graph"
              CodexAbsent
              CodexAbsent))))
        ((codex:mcp-map-entry
           "files"
           ((codex:mcp-resource-template
              CodexAbsent
              "file:///{path}"
              "file"
              "File"
              CodexAbsent
              "text/plain"))))
        ((codex:mcp-map-entry "memory" (codex:mcp-auth-status-oauth))
         (codex:mcp-map-entry "files" (codex:mcp-auth-status-not-logged-in))))))
  ("{\"type\":\"mcp_list_tools_response\",\"tools\":{\"memory/read_graph\":{\"name\":\"read_graph\",\"title\":\"Read graph\",\"description\":\"Read entities and relations.\",\"inputSchema\":{\"type\":\"object\"},\"outputSchema\":{\"type\":\"object\"}}},\"resources\":{\"memory\":[{\"description\":\"Graph snapshot\",\"mimeType\":\"application/json\",\"name\":\"graph\",\"size\":42,\"title\":\"Graph\",\"uri\":\"memory://graph\"}]},\"resource_templates\":{\"files\":[{\"uriTemplate\":\"file:///{path}\",\"name\":\"file\",\"title\":\"File\",\"mimeType\":\"text/plain\"}]},\"auth_statuses\":{\"memory\":\"oauth\",\"files\":\"not_logged_in\"}}"))
