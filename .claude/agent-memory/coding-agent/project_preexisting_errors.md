---
name: project_preexisting_errors
description: Pre-existing compile error in HealthKitMirror.swift — HeartRateReader.readRestingHeartRate does not exist on the class
metadata:
  type: project
---

`HealthKitMirror.swift` line 9 calls `HeartRateReader.readRestingHeartRate(for: date)` as a static method, but `HeartRateReader` only has an instance method `fetchLast90Days()`. This was present before the improve_readability branch and is unrelated to structural refactoring.

**Why:** `HeartRateReader` was added as an instance-based class; the mirror was written expecting a static API that was never implemented.

**How to apply:** Do not treat this as a regression when verifying builds. Flag it if the user asks about HealthKit heart rate data being missing from snapshots.
