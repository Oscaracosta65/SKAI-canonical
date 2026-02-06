# Miss-Driven Weight Tuning - On-The-Fly Implementation

## Overview

SKAI now supports **on-the-fly miss-driven weight tuning** with **ZERO server storage**. Component weights (frequency, skip, recency, cooccur) are automatically tuned based on historical miss patterns, computed fresh for each request without any database persistence.

## Key Features

✅ **Zero Storage** - No database tables, no inserts, no saved weights  
✅ **On-The-Fly Computation** - Weights computed from draw history per request  
✅ **Walk-Forward Validation** - No data leakage, proper temporal splits  
✅ **Gradient-Based Tuning** - Learns from miss deficits across components  
✅ **Acceptance Gating** - Only accepts weights if metric improves >= 0.002  
✅ **Request-Level Caching** - Computed once, reused within same request  

## Algorithm

### 1. Walk-Forward Validation

```
For each validation draw D in rolling window:
  ├─ Train: Use draws before D only (no leakage)
  ├─ Score: Rank all candidates with current weights
  ├─ Top K: Get top 20 predictions
  ├─ Misses: Identify winning numbers NOT in top 20
  └─ Deficits: Compare miss components to median of top 20
```

### 2. Deficit Aggregation

For each miss, compute component deficits:
- **Frequency deficit** = max(0, median_freq - miss_freq)
- **Skip deficit** = max(0, median_skip - miss_skip)
- **Recency deficit** = max(0, median_recency - miss_recency)
- **Cooccur deficit** = max(0, median_cooccur - miss_cooccur)

Average deficits across all misses in validation window.

### 3. Weight Update

```
1. Compute deltas: Δ_i = η × (deficit_i / Σ deficits)
2. Update weights: w_i = w_old_i + Δ_i
3. Clamp: w_i ∈ [0.05, 0.85]
4. Normalize: w_i = w_i / Σ w_i  (sum = 1)
5. Smooth: w_final = (1-α)×w_old + α×w_new
6. Re-normalize: w_final = w_final / Σ w_final
```

Where:
- **η** (learning rate) = 0.05 (default)
- **α** (smoothing factor) = 0.2 (default)

### 4. Acceptance Test

```php
metric_before = evaluate(w_old, validation_window)
metric_after = evaluate(w_new, validation_window)

if (metric_after - metric_before >= 0.002) {
    return w_new;  // Accept tuned weights
} else {
    return w_old;  // Reject, keep original
}
```

Metric is a proxy based on inverse weighted deficit (higher = better alignment).

## API Reference

### Main Function

```php
function SKAI_computeTunedWeights(
    string $gameId,         // Game identifier
    array $baseWeights,     // Starting weights {frequency, skip, recency, cooccur}
    array $drawHistory,     // Full draw history [{date, numbers}, ...]
    int $windowSize = 60,   // Validation window (# of recent draws)
    float $lr = 0.05,       // Learning rate
    float $smooth = 0.2     // Smoothing factor
): array                    // Returns tuned weights or original
```

**Parameters:**
- `$gameId` - Game identifier (used for logging/caching)
- `$baseWeights` - Starting weights, typically:
  ```php
  [
      'frequency' => 0.25,
      'skip' => 0.25,
      'recency' => 0.25,
      'cooccur' => 0.25
  ]
  ```
- `$drawHistory` - Array of historical draws:
  ```php
  [
      ['date' => '2024-01-01', 'numbers' => [1, 5, 12, 23, 45, 67]],
      ['date' => '2024-01-08', 'numbers' => [3, 11, 22, 34, 56, 69]],
      // ... more draws
  ]
  ```
- `$windowSize` - Number of recent draws to use for validation (default: 60)
- `$lr` - Learning rate for gradient update (default: 0.05)
- `$smooth` - Smoothing factor, higher = more conservative (default: 0.2)

**Returns:**
- Tuned weights if improvement >= 0.002
- Original weights if no improvement

### Helper Functions

```php
// Get default component weights
function SKAI_getDefaultComponentWeights(): array

// Simplified scoring for tuning (fast, no ML)
function SKAI_scoreDrawSimplified(array $history, array $weights): array

// Compute median score parts across candidates
function SKAI_computeMedianScoreParts(array $candidates): array

// Compute weight deltas from deficit signals
function SKAI_computeWeightDeltas(array $deficitSignals, float $lr): array

// Apply smoothed weight update with clamping
function SKAI_applyWeightUpdate(array $oldWeights, array $deltas, float $smooth): array

// Evaluate weights using deficit-based proxy metric
function SKAI_evaluateWeightsSimplified(array $weights, array $deficits): float
```

## Usage Example

### Basic Usage

```php
<?php

// 1. Get draw history (from database or cache)
$drawHistory = SKAI_getDrawHistory($gameId);

// 2. Get base weights (default or user-specified)
$baseWeights = SKAI_getDefaultComponentWeights();
// Or custom:
// $baseWeights = [
//     'frequency' => 0.3,
//     'skip' => 0.2,
//     'recency' => 0.3,
//     'cooccur' => 0.2
// ];

// 3. Compute tuned weights on-the-fly
$tunedWeights = SKAI_computeTunedWeights(
    $gameId,
    $baseWeights,
    $drawHistory,
    $windowSize = 60    // Use last 60 draws for tuning
);

// 4. Use tuned weights downstream
echo "Using weights: " . json_encode($tunedWeights) . "\n";
// Output: {"frequency":0.28,"skip":0.22,"recency":0.31,"cooccur":0.19}
```

### Integration in Prediction Pipeline

```php
<?php

function SKAI_generatePrediction($gameId, $userSettings = []) {
    // Get draw history
    $drawHistory = SKAI_getDrawHistory($gameId);
    
    // Determine base weights
    if (isset($userSettings['weights'])) {
        // User explicitly specified weights - use as-is
        $weights = $userSettings['weights'];
    } else {
        // Auto-tune weights from draw history
        $baseWeights = SKAI_getDefaultComponentWeights();
        $weights = SKAI_computeTunedWeights(
            $gameId,
            $baseWeights,
            $drawHistory,
            $windowSize = 60
        );
        
        error_log("[SKAI] Auto-tuned weights: " . json_encode($weights));
    }
    
    // Use weights in scoring
    $candidates = SKAI_scoreWithWeights($drawHistory, $weights);
    
    // Rank and return top predictions
    usort($candidates, fn($a, $b) => $b['score'] <=> $a['score']);
    return array_slice($candidates, 0, 20);
}
```

### Advanced: Custom Window Size

```php
<?php

// For games with frequent draws (daily): use smaller window
$dailyGameWeights = SKAI_computeTunedWeights(
    $gameId,
    $baseWeights,
    $drawHistory,
    $windowSize = 30    // Last 30 days
);

// For games with infrequent draws (weekly): use larger window
$weeklyGameWeights = SKAI_computeTunedWeights(
    $gameId,
    $baseWeights,
    $drawHistory,
    $windowSize = 100   // Last ~2 years
);
```

## Performance Considerations

### Caching Strategy

The function uses **request-level caching** to avoid recomputation:

```php
// Internal cache - computed once per request
static $cache = [];
$cacheKey = $gameId . '_' . count($drawHistory) . '_' . $windowSize;

if (isset($cache[$cacheKey])) {
    return $cache[$cacheKey];  // Return cached result
}
```

### Computational Complexity

- **Time**: O(W × N) where W = window size, N = domain size (~70)
- **Space**: O(N) for candidate arrays
- **Typical runtime**: 50-200ms for windowSize=60, domain=70

### Performance Tips

1. **Limit window size**: Use 30-60 draws for best speed/accuracy tradeoff
2. **Cache draw history**: Fetch once per request, reuse
3. **Skip for small games**: Only tune when history > windowSize + 10
4. **Application-level cache**: Consider Redis/Memcache for production

```php
// Example: Application-level caching (optional)
$cacheKey = "skai_weights_{$gameId}_" . md5(serialize($drawHistory));
$weights = $redis->get($cacheKey);

if (!$weights) {
    $weights = SKAI_computeTunedWeights($gameId, $baseWeights, $drawHistory);
    $redis->setex($cacheKey, 3600, serialize($weights));  // Cache 1 hour
}
```

## Configuration

### Tuning Parameters

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| `windowSize` | 60 | 30-100 | Larger = more stable, slower |
| `lr` | 0.05 | 0.01-0.1 | Higher = faster learning, less stable |
| `smooth` | 0.2 | 0.1-0.5 | Higher = more conservative updates |
| `threshold` | 0.002 | 0.001-0.01 | Higher = stricter acceptance |

### Recommended Settings by Game Type

**High-frequency draws (daily):**
```php
$windowSize = 30;    // ~1 month
$lr = 0.08;          // Higher learning rate
$smooth = 0.15;      // Less smoothing
```

**Low-frequency draws (weekly):**
```php
$windowSize = 80;    // ~1.5 years
$lr = 0.03;          // Lower learning rate
$smooth = 0.3;       // More smoothing
```

**High-variance games:**
```php
$windowSize = 100;   // More data
$lr = 0.03;          // Conservative
$smooth = 0.4;       // Heavy smoothing
```

## Logging

The function logs key events for debugging:

```
[SKAI] Starting on-the-fly weight tuning: game=powerball, window=60, draws=60
[SKAI] Analyzed 45 misses, avg deficits: {"frequency":0.12,"skip":0.08,"recency":0.15,"cooccur":0.10}
[SKAI] Candidate weights: {"frequency":0.28,"skip":0.22,"recency":0.31,"cooccur":0.19}
[SKAI] Metrics: before=0.6234, after=0.6456, improvement=0.0222
[SKAI] Accepting tuned weights (improvement: 0.0222)
[SKAI] Weight tuning completed in 0.156s
```

Or if rejected:
```
[SKAI] Metrics: before=0.6234, after=0.6245, improvement=0.0011
[SKAI] Rejecting tuned weights (insufficient improvement: 0.0011)
```

## Testing

### Unit Test Example

```php
<?php

function testWeightTuning() {
    // Mock draw history
    $drawHistory = [
        ['date' => '2024-01-01', 'numbers' => [1, 5, 12, 23, 45, 67]],
        ['date' => '2024-01-08', 'numbers' => [3, 11, 22, 34, 56, 69]],
        // ... 60 more draws
    ];
    
    $baseWeights = SKAI_getDefaultComponentWeights();
    
    // Should return valid weights
    $tunedWeights = SKAI_computeTunedWeights(
        'test_game',
        $baseWeights,
        $drawHistory,
        10  // Small window for testing
    );
    
    // Assertions
    assert(is_array($tunedWeights), "Should return array");
    assert(count($tunedWeights) === 4, "Should have 4 components");
    assert(array_sum($tunedWeights) > 0.99 && array_sum($tunedWeights) < 1.01, "Should sum to 1");
    assert(min($tunedWeights) >= 0.05, "All weights >= 0.05");
    assert(max($tunedWeights) <= 0.85, "All weights <= 0.85");
    
    echo "✓ Weight tuning tests passed\n";
}
```

## Troubleshooting

### Issue: Weights unchanged after tuning

**Cause:** Improvement below 0.002 threshold  
**Solution:** Lower threshold or increase window size for more signal

### Issue: Slow performance

**Cause:** Large window size or domain  
**Solution:** Reduce window to 30-40 draws, optimize scoring function

### Issue: Weights too aggressive

**Cause:** High learning rate, low smoothing  
**Solution:** Reduce `lr` to 0.03 or increase `smooth` to 0.3-0.4

### Issue: Insufficient draw history

**Cause:** Game has < windowSize + 10 draws  
**Solution:** Function returns base weights automatically, no action needed

## Comparison: Old vs New Approach

| Feature | Old (Database) | New (On-The-Fly) |
|---------|---------------|------------------|
| Storage | Database table | None |
| Persistence | Saved weights | Computed per request |
| Stale data | Risk of outdated weights | Always fresh |
| Maintenance | DB cleanup needed | Zero maintenance |
| Scalability | DB queries bottleneck | Pure computation |
| Flexibility | Fixed at save time | Adapts to params |

## Future Enhancements (Optional)

- [ ] Parallel walk-forward validation (multi-threading)
- [ ] Bayesian optimization for hyperparameters
- [ ] Component importance analysis (sensitivity)
- [ ] Multi-objective tuning (recall + NDCG)
- [ ] Adaptive window sizing based on game variance

---

**Version**: 1.0  
**Last Updated**: 2026-02-06  
**Author**: SKAI Development Team  
**License**: Proprietary
