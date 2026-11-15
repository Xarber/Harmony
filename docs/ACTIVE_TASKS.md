# Harmony active tasks

Order follows the request to check builds, fix any defects and apply the new UADS.

| ID | Priority | Task | State | Evidence and next action |
| --- | --- | --- | --- | --- |
| H-01 | High | Check existing Apple and web builds and repair failures | Verified | Run 43592619392 at `c0d570f`. All five jobs passed. Native checksums and Mach-O platforms were verified. Simulator and physical-device launch checks remain separate. |
| H-02 | High | Integrate UADS governance, validation and CI | Implemented | Manifest validates and local source checks passed. Confirm the remote quality run after workflow registration. |
| H-03 | High | Reconcile applicable product gaps | Queued | Prioritize onboarding, current screenshots, isolated sample data and landing install controls. Native distribution remains authorization-gated. |
| H-04 | High | Recheck X-Center production reachability | Blocked | HTTPS did not connect and the appliance SSH path timed out on 15 November. Verify ingress and appliance reachability before attempting recovery. |
