# Harmony active tasks

Order follows the request to check builds, fix any defects and apply the new UADS.

| ID | Priority | Task | State | Evidence and next action |
| --- | --- | --- | --- | --- |
| H-01 | High | Check existing Apple and web builds and repair failures | Verified | Run 43592619392 at `c0d570f`. All five jobs passed. Native checksums and Mach-O platforms were verified. Simulator and physical-device launch checks remain separate. |
| H-02 | High | Integrate UADS governance, validation and CI | In Progress | Manifest and registry created. Implement and run the validator and source-quality workflow. |
| H-03 | High | Reconcile applicable product gaps | Queued | Prioritize onboarding, current screenshots, isolated sample data and landing install controls. Native distribution remains authorization-gated. |
