<!-- Order groups strictly by dependency (apply runs them top to bottom).
     Optional: append [batch: <id>] to groups safe to run concurrently — same
     id ONLY for groups touching disjoint files with no dependency edge. -->

## 1. <!-- Task Group Name -->

- [ ] 1.1 <!-- Task description -->
- [ ] 1.2 <!-- Task description -->
- [ ] 1.3 Verify: <!-- command/check that proves this group's work -->

## 2. <!-- Task Group Name --> <!-- [batch: A] only if disjoint + independent -->

- [ ] 2.1 <!-- Task description -->
- [ ] 2.2 <!-- Task description -->
- [ ] 2.3 Verify: <!-- command/check that proves this group's work -->

## 3. Final Validation <!-- always the last group -->

- [ ] 3.1 <!-- Run the full test suite and build -->
- [ ] 3.2 <!-- Verify each spec scenario end-to-end -->
