# SKAI Deterministic Mode - Validation Checklist

Use this checklist to verify the deterministic mode implementation.

## Pre-Deployment Checks

### Database Schema
- [ ] Run ALTER TABLE to add `deterministic` and `seed` columns
- [ ] Verify columns exist: `SHOW COLUMNS FROM skai_run_logs LIKE 'deterministic'`
- [ ] Verify columns exist: `SHOW COLUMNS FROM skai_run_logs LIKE 'seed'`
- [ ] Verify index exists: `SHOW INDEX FROM skai_run_logs WHERE Key_name = 'idx_deterministic_seed'`

### Code Deployment
- [ ] Backup existing `SKAI 02 06 26 .txt` file
- [ ] Deploy new version with deterministic mode
- [ ] Clear application cache
- [ ] Verify no PHP errors in logs

## Functional Testing

### Basic Functionality (Non-Deterministic)
- [ ] Open SKAI application
- [ ] Verify "Custom Settings (Advanced)" section exists
- [ ] Leave deterministic checkbox UNCHECKED
- [ ] Run prediction
- [ ] Run prediction again
- [ ] Verify picks are DIFFERENT (random as before)

### Deterministic Mode (Auto-Seed)
- [ ] Open Custom Settings (Advanced)
- [ ] Check "Enable reproducible predictions" checkbox
- [ ] Verify seed input field appears
- [ ] Leave seed field EMPTY (auto-generate)
- [ ] Run prediction #1
- [ ] Note the seed value from console log
- [ ] Note top 20 picks
- [ ] Refresh page
- [ ] Check deterministic checkbox again
- [ ] Enter the SAME seed from run #1
- [ ] Run prediction #2
- [ ] Verify top 20 picks are IDENTICAL to run #1

### Deterministic Mode (Manual Seed)
- [ ] Open Custom Settings (Advanced)
- [ ] Check "Enable reproducible predictions"
- [ ] Enter seed: 12345
- [ ] Run prediction #1
- [ ] Note top 20 picks
- [ ] Refresh page
- [ ] Check deterministic checkbox
- [ ] Enter seed: 12345 (same as before)
- [ ] Run prediction #2
- [ ] Verify top 20 picks MATCH prediction #1
- [ ] Change seed to: 54321
- [ ] Run prediction #3
- [ ] Verify top 20 picks are DIFFERENT from predictions #1 and #2

### Database Storage
- [ ] Run prediction with deterministic=true, seed=99999
- [ ] Query database: `SELECT * FROM skai_run_logs ORDER BY id DESC LIMIT 1`
- [ ] Verify `deterministic` = 1
- [ ] Verify `seed` = 99999
- [ ] Verify `params_json` contains deterministic settings

### UI Controls
- [ ] Verify checkbox toggles seed input visibility
- [ ] Verify unchecking checkbox hides seed input
- [ ] Verify "Reset to defaults" button unchecks deterministic
- [ ] Verify "Reset to defaults" button clears seed value
- [ ] Verify live announcements work (screen reader)

### JavaScript Console Tests
- [ ] Open browser console (F12)
- [ ] Enable deterministic mode in UI
- [ ] Run: `window.SKAI_testReproducibility()`
- [ ] Verify output shows "PASSED ✓"
- [ ] Verify samples arrays are identical
- [ ] Disable deterministic mode
- [ ] Run test again
- [ ] Verify output shows "FAILED: Deterministic mode is not enabled"

### Thompson Sampling Reproducibility
- [ ] Enable deterministic with seed=11111
- [ ] Open console and log: `window.skaiSampleBeta(5, 5)`
- [ ] Note the value (e.g., 0.534125)
- [ ] Refresh page
- [ ] Enable deterministic with seed=11111 again
- [ ] Run: `window.skaiSampleBeta(5, 5)`
- [ ] Verify value is IDENTICAL to first run

### Extra Ball Reproducibility
- [ ] For lottery with extra balls (e.g., Powerball)
- [ ] Enable deterministic with seed=22222
- [ ] Run prediction
- [ ] Note main picks AND extra ball picks
- [ ] Refresh and repeat with same seed
- [ ] Verify BOTH main and extra picks are identical

## Edge Cases

### Empty Seed (Auto-Generate)
- [ ] Enable deterministic with no seed
- [ ] Run prediction
- [ ] Check console for auto-generated seed
- [ ] Verify seed is a valid integer

### Invalid Seed
- [ ] Try entering negative seed: -123
- [ ] Verify system handles it (should convert to absolute value or reject)
- [ ] Try entering zero: 0
- [ ] Verify system handles it appropriately

### Large Seed
- [ ] Enter maximum seed: 2147483647
- [ ] Run prediction
- [ ] Verify it works correctly

### Seed Persistence
- [ ] Enable deterministic with seed=33333
- [ ] Run prediction
- [ ] Query database for latest run
- [ ] Verify seed is stored as 33333
- [ ] Retrieve that run later
- [ ] Use stored seed to reproduce
- [ ] Verify picks match original

## Performance Testing

### Speed Comparison
- [ ] Run 10 predictions with deterministic=false
- [ ] Time average duration
- [ ] Run 10 predictions with deterministic=true
- [ ] Time average duration
- [ ] Verify deterministic is <0.2% slower

### Memory Usage
- [ ] Check memory before running predictions
- [ ] Run 5 deterministic predictions
- [ ] Check memory after
- [ ] Verify no memory leak

## Regression Testing

### Backward Compatibility
- [ ] Verify existing saved predictions still work
- [ ] Verify old runs (without deterministic) display correctly
- [ ] Verify non-deterministic mode produces varied results
- [ ] Verify all existing features still work

### UI Stability
- [ ] Verify page layout unchanged
- [ ] Verify all existing buttons work
- [ ] Verify collapsible sections work
- [ ] Verify mobile responsiveness unchanged

## Browser Compatibility

Test in each browser:
- [ ] Chrome: Deterministic mode works
- [ ] Firefox: Deterministic mode works
- [ ] Safari: Deterministic mode works
- [ ] Edge: Deterministic mode works
- [ ] Mobile Chrome: UI controls accessible
- [ ] Mobile Safari: UI controls accessible

## Documentation Review

- [ ] README exists and is complete
- [ ] Implementation summary exists
- [ ] Examples are clear and accurate
- [ ] Troubleshooting guide is helpful
- [ ] API documentation is accurate

## Final Checks

### Code Quality
- [ ] No console errors
- [ ] No PHP errors in logs
- [ ] No JavaScript warnings
- [ ] Code follows existing style
- [ ] Comments are clear

### Security
- [ ] Seeds not used for authentication
- [ ] Seeds not encrypted (documented limitation)
- [ ] No sensitive data in seeds
- [ ] SQL injection protected

### Deployment Readiness
- [ ] All tests passed
- [ ] Documentation complete
- [ ] Backup created
- [ ] Rollback plan ready
- [ ] Team trained on new feature

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | _____________ | ______ | _________ |
| QA Tester | _____________ | ______ | _________ |
| Tech Lead | _____________ | ______ | _________ |
| Product Owner | __________ | ______ | _________ |

## Notes

_Use this space for any additional observations or issues found during testing_

---
---
---

**Version**: 1.0  
**Date**: 2026-02-06  
**Status**: Ready for Testing
