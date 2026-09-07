# Memory metadata schema

Required for ordinary memories:

- `id`: unique ID. Recommended `MEM-YYYYMMDD-HHMMSS`.
- `type`: `rule`, `lesson`, `incident`, or `project`.
- `scope`: `global` or `project`.
- `status`: `active`, `candidate`, `deprecated`, or `archived`.
- `confidence`: `low`, `medium`, or `high`.
- `created`: ISO date.
- `updated`: ISO date.
- `tags`: concise searchable keywords.

Recommended:

- `project`
- `domain`
- `last_seen`
- `occurrences`
- `source_agent`
