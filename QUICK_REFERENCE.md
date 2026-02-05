# Quick Reference: Position Display Fields

## Field Reference

| Field Name | HTML ID | Purpose | Value Source |
|------------|---------|---------|--------------|
| `skai_mode_primary` | `skai-ai-mode-primary` | Primary mode selection | `profileVal` (user's risk profile) |
| `skai_mode_method` | `skai-ai-mode-method` | Strategy/method selection | `strategyVal` (user's strategy) |
| `skai_mode_risk` | `skai-ai-mode-risk` | Risk level | `profileVal` (mirrors primary) |

## Possible Values

### Risk Profile / Primary Mode / Risk Level
- `conservative` - Conservative approach
- `balanced` - Balanced approach (default)
- `aggressive` - Aggressive approach

### Strategy / Method
- `skip_heavy` - Skip-Heavy strategy
- `hybrid` - Hybrid strategy (default)
- `ai_heavy` - AI-Heavy strategy

## File Locations

### HTML Form Definition
**File:** SKAI 02 05 26.txt  
**Lines:** 11930-11932
```html
<input type="hidden" name="skai_mode_primary" id="skai-ai-mode-primary" value="" />
<input type="hidden" name="skai_mode_method" id="skai-ai-mode-method" value="" />
<input type="hidden" name="skai_mode_risk" id="skai-ai-mode-risk" value="" />
```

### JavaScript Population
**File:** SKAI 02 05 26.txt  
**Lines:** 21969-21974
```javascript
var fldModePrimary = document.getElementById('skai-ai-mode-primary');
var fldModeMethod = document.getElementById('skai-ai-mode-method');
var fldModeRisk = document.getElementById('skai-ai-mode-risk');
if (fldModePrimary) fldModePrimary.value = profileVal;
if (fldModeMethod) fldModeMethod.value = strategyVal;
if (fldModeRisk) fldModeRisk.value = profileVal;
```

## Usage Examples

### Example 1: Conservative + Skip-Heavy
```
skai_mode_primary: "conservative"
skai_mode_method: "skip_heavy"
skai_mode_risk: "conservative"
```

### Example 2: Balanced + Hybrid (Default)
```
skai_mode_primary: "balanced"
skai_mode_method: "hybrid"
skai_mode_risk: "balanced"
```

### Example 3: Aggressive + AI-Heavy
```
skai_mode_primary: "aggressive"
skai_mode_method: "ai_heavy"
skai_mode_risk: "aggressive"
```

## Dashboard Integration

### Database Schema (Suggested)
```sql
ALTER TABLE saved_predictions ADD COLUMN skai_mode_primary VARCHAR(50);
ALTER TABLE saved_predictions ADD COLUMN skai_mode_method VARCHAR(50);
ALTER TABLE saved_predictions ADD COLUMN skai_mode_risk VARCHAR(50);
```

### PHP Backend (Receiving Data)
```php
$modePrimary = $input->getString('skai_mode_primary', '');
$modeMethod = $input->getString('skai_mode_method', '');
$modeRisk = $input->getString('skai_mode_risk', '');
```

### Dashboard Display (PHP)
```php
<?php if (!empty($prediction->skai_mode_primary)): ?>
<div class="prediction-mode">
    <strong>Mode:</strong> 
    <?php echo ucfirst($prediction->skai_mode_primary); ?> - 
    <?php echo ucfirst(str_replace('_', ' ', $prediction->skai_mode_method)); ?>
</div>
<div class="prediction-risk">
    <strong>Risk Level:</strong> 
    <?php echo ucfirst($prediction->skai_mode_risk); ?>
</div>
<?php endif; ?>
```

## Quick Verification

### Check if fields exist in HTML
```bash
grep -n "skai-ai-mode-" "SKAI 02 05 26.txt"
```

### Check if fields are populated in JS
```bash
grep -n "fldModePrimary\|fldModeMethod\|fldModeRisk" "SKAI 02 05 26.txt"
```

### Run full verification
```bash
./verify_position_fields.sh
```

## Testing

### Manual Test in Browser Console
```javascript
// Check if fields exist
document.getElementById('skai-ai-mode-primary');
document.getElementById('skai-ai-mode-method');
document.getElementById('skai-ai-mode-risk');

// Populate and check values
const form = document.getElementById('skai-ai-save-form');
const formData = new FormData(form);
console.log('skai_mode_primary:', formData.get('skai_mode_primary'));
console.log('skai_mode_method:', formData.get('skai_mode_method'));
console.log('skai_mode_risk:', formData.get('skai_mode_risk'));
```

### Interactive Test Page
Open `test_position_fields.html` in a browser for interactive testing.

## Troubleshooting

### Fields not populated?
1. Ensure user has selected risk profile and strategy
2. Check that `window.skaiPrepareAiSave()` is called after selection
3. Verify `profileVal` and `strategyVal` variables are defined

### Dashboard not receiving values?
1. Check form submission is sending POST data
2. Verify CSRF token is valid
3. Check server-side input handling accepts these field names
4. Verify database has columns for these fields (if storing)

### Values showing as empty?
1. Run SKAI AI analysis first
2. Make selections for risk profile and strategy
3. Wait for field population before submitting
4. Check browser console for JavaScript errors

## Support Files

- `COMPATIBILITY_VERIFICATION.md` - Full technical documentation
- `IMPLEMENTATION_SUMMARY.md` - High-level summary and findings
- `verify_position_fields.sh` - Automated verification script
- `test_position_fields.html` - Interactive test page
- `QUICK_REFERENCE.md` - This file

## Status
✅ **VERIFIED AND READY FOR PRODUCTION**

Last Updated: February 5, 2026
