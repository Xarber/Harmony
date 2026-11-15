# UADS requirements for Harmony

The local baseline `sections-01-52` refers to the supplied UADS sections 1–52. The standard remains authoritative. [The machine-readable registry](../Config/uads-requirements.json) maps all source sections to project checks. It groups related checks where evidence overlaps and can be refined into more granular IDs without reusing an existing ID. [The manifest](../uads.json) records applicability and verification separately. The existing capitalized `Config/` directory is used consistently across case-sensitive and case-insensitive systems.

A passing structural validator establishes schema validity and internal consistency. Operational evidence must identify the exercised runtime and commit. Mark unexecuted manual and CI checks pending, document the reason for conditional or inapplicable entries, and record only explicitly approved exceptions.
