# SHAFT VIBRATION DATA SUMMARY

## File Information
- **File**: 01 - m1_half_shaft_speed_no_mechanical_load.csv
- **Sampling Rate**: 0.00 Hz
- **Estimated Samples**: 19999
- **Duration**: 37040624.00 seconds

## Acceleration Channels
1. **AccX**: Horizontal acceleration (X-axis)
2. **AccY**: Horizontal acceleration (Y-axis)
3. **AccZ**: Vertical acceleration (includes gravity)

## Statistical Summary (first 20k samples)
| Channel | Mean | Std Dev | Min | Max | RMS |
|---------|------|---------|-----|-----|-----|
| AccX | 302.3055 | 1776.6249 | -5456.0000 | 6232.0000 | 1802.1174 |
| AccY | -185.7749 | 603.3475 | -2884.0000 | 1764.0000 | 631.2863 |
| AccZ | 16184.8074 | 2459.2622 | 7340.1900 | 24878.1900 | 16370.5730 |

## Next Steps for Model 1
1. **Feature Extraction**: 12 features × 3 channels = 36 features
2. **Window Size**: 10,000 samples (~18521238.1 seconds at 0 Hz)
3. **Parameter Mapping**: Estimate spring, damper, inertia from filenames
