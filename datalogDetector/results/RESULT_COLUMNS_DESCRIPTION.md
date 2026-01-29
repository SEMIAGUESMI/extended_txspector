# Detection Result Columns Description

## SimplifiedCrossFunctionReentrancy.csv

This file contains the simplified cross-function reentrancy detection results (without function selectors).

### Column Descriptions

| Column Name | Description | Example |
|------------|-------------|---------|
| **FunctionA_CallNumber** | Sequential call number of Function A (the outer function that reads state and makes external call) | `0` |
| **FunctionA_CallDepth** | Call depth (nesting level) of Function A. Depth 0 is the initial transaction, depth 1 is the first contract call, etc. | `1` |
| **FunctionB_CallNumber** | Sequential call number of Function B (the re-entered function that modifies state) | `2` |
| **FunctionB_CallDepth** | Call depth of Function B. Must be greater than Function A's depth (indicating reentrancy) | `3` |
| **StorageAddress** | The storage slot address (in hex) that both functions access. Function A reads from this address, Function B writes to it. | `0x1` |
| **SLOAD_Location** | Program counter (PC) location where Function A reads the storage via `SLOAD` opcode | `103` |
| **SSTORE_Location** | Program counter (PC) location where Function B writes to the storage via `SSTORE` opcode | `2280` |
| **CALL_Location** | Program counter (PC) location where Function A makes the external call (via `CALL`, `DELEGATECALL`, `CALLCODE`, or `STATICCALL`) | `179` |

### Interpretation

Each row represents a detected cross-function reentrancy vulnerability where:
- Function A reads state at `SLOAD_Location` before making an external call at `CALL_Location`
- Function B modifies the same state at `SSTORE_Location` during reentrancy (after the external call)
- The temporal ordering is: `SLOAD_Location < CALL_Location < SSTORE_Location`

---

## CrossFunctionReentrancy.csv

This file contains the enhanced cross-function reentrancy detection results (with function selectors).

### Column Descriptions

| Column Name | Description | Example |
|------------|-------------|---------|
| **FunctionA_CallNumber** | Sequential call number of Function A | `0` |
| **FunctionA_CallDepth** | Call depth of Function A | `1` |
| **FunctionA_Selector** | Function selector variable of Function A (extracted from `CALLDATALOAD(0)`) | `V1` |
| **FunctionB_CallNumber** | Sequential call number of Function B | `2` |
| **FunctionB_CallDepth** | Call depth of Function B | `3` |
| **FunctionB_Selector** | Function selector variable of Function B (extracted from `CALLDATALOAD(0)`) | `V67` |
| **StorageAddress** | The storage slot address that both functions access | `0x1` |
| **SLOAD_Location** | PC location where Function A reads storage | `103` |
| **SSTORE_Location** | PC location where Function B writes storage | `2280` |
| **JUMPI_Location** | PC location where Function A uses a conditional jump (`JUMPI`) that depends on the loaded value | `111` |
| **CALL_Location** | PC location where Function A makes external call | `179` |

### Interpretation

Each row represents a detected cross-function reentrancy vulnerability where:
- Function A (identified by `FunctionA_Selector`) reads state, uses it in a conditional jump, then makes an external call
- Function B (identified by `FunctionB_Selector`, different from Function A) modifies the same state during reentrancy
- The temporal ordering is: `SLOAD_Location < JUMPI_Location < CALL_Location < SSTORE_Location`

---

## Example Detection Result

### SimplifiedCrossFunctionReentrancy.csv
```
FunctionA_CallNumber	FunctionA_CallDepth	FunctionB_CallNumber	FunctionB_CallDepth	StorageAddress	SLOAD_Location	SSTORE_Location	CALL_Location
0	1	2	3	0x1	103	2280	179
```

**Interpretation:**
- Function A (call #0, depth 1) reads storage slot `0x1` at PC 103
- Function A makes external call at PC 179
- Function B (call #2, depth 3) writes to storage slot `0x1` at PC 2280
- This indicates a cross-function reentrancy vulnerability where Function B modifies state that Function A read before the external call

---

## Notes

- **Call Number (CN)**: Sequential identifier for each contract call within a transaction. Higher numbers indicate later calls.
- **Call Depth**: The nesting level of contract calls. Depth 0 = transaction entry, depth 1 = first call, depth 2 = call within a call, etc.
- **Storage Address**: Hex representation of the storage slot (e.g., `0x0`, `0x1`, `0x2`). In Solidity, this corresponds to state variable storage slots.
- **Program Counter (PC) Location**: The bytecode offset where the operation occurs. Used to establish temporal ordering of operations.
- **Function Selector**: The first 4 bytes of function calldata, used to identify which function is being called. Only available in `CrossFunctionReentrancy.csv`.

