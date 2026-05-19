!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:memory_citation)
!(import! &self codex:protocol)

(= (memory-citation-first-thread-id)
   "018f4d4a-0000-7000-8000-000000000001")

(= (memory-citation-second-thread-id)
   "018f4d4a-0000-7000-8000-000000000002")

(= (memory-citation-entries-fixture)
   (format-args
     "<citation_entries>\nMEMORY.md:1-2|note=[summary]\nrollout_summaries/foo.md:10-12|note=[details]\n</citation_entries>\n<rollout_ids>\n{}\n{}\n{}\n</rollout_ids>"
     ((memory-citation-first-thread-id)
      (memory-citation-second-thread-id)
      (memory-citation-first-thread-id))))

!(assertEqual
  (json-stringify
    (codex:memory-citation-json
      (codex:parse-memory-citation
        ((memory-citation-entries-fixture)))))
  (format-args
    "{\"entries\":[{\"path\":\"MEMORY.md\",\"lineStart\":1,\"lineEnd\":2,\"note\":\"summary\"},{\"path\":\"rollout_summaries/foo.md\",\"lineStart\":10,\"lineEnd\":12,\"note\":\"details\"}],\"rolloutIds\":[\"{}\",\"{}\"]}"
    ((memory-citation-first-thread-id)
     (memory-citation-second-thread-id))))

!(assertEqual
  (codex:thread-ids-from-memory-citation
    (codex:parse-memory-citation
      ((format-args
         "<memory_citation>\n<citation_entries>\nMEMORY.md:1-2|note=[x]\n</citation_entries>\n<thread_ids>\n{}\nnot-a-uuid\n{}\n</thread_ids>\n</memory_citation>"
         ((memory-citation-first-thread-id)
          (memory-citation-second-thread-id))))))
  ((memory-citation-first-thread-id)
   (memory-citation-second-thread-id)))

!(assertEqual
  (codex:thread-ids-from-memory-citation
    (codex:parse-memory-citation
      ((format-args
         "<memory_citation>\n<rollout_ids>\n{}\n</rollout_ids>\n</memory_citation>"
         ((memory-citation-first-thread-id))))))
  ((memory-citation-first-thread-id)))

!(assertEqual
  (codex:parse-memory-citation
    ("no citation block here"))
  CodexAbsent)

!(assertEqualToResult
  (json-stringify
    (codex:memory-citation-json
      (codex:parse-memory-citation
        ("<citation_entries>\nignored\nsrc:file.rs:3-4|note=[keeps:last:colon]\nBAD:one-two|note=[bad]\n</citation_entries>"))))
  ("{\"entries\":[{\"path\":\"src:file.rs\",\"lineStart\":3,\"lineEnd\":4,\"note\":\"keeps:last:colon\"}],\"rolloutIds\":[]}"))
