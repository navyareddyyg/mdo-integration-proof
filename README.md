# MDO URL extraction integration proof

This synthetic repository demonstrates the value of combining an MDO URL
extractor with repository-aware validation and fallback.

The fixtures cover three common source-repository parsing problems:

- Markdown links, badges, code spans, and balanced parentheses;
- HTML URL attributes, entities, and element boundaries;
- unresolved source-code templates that are not real destinations.

No external repository source code or production scan data is included.

## Expected result

| Metric | Baseline | Integrated |
|---|---:|---:|
| Expected concrete URLs | 11 | 11 |
| Expected URLs represented correctly | 7 | 11 |
| Malformed or unresolved candidates | 6 | 0 |
| Total candidates | 13 | 11 |

For the integrated result, eight URLs come from MDO primary extraction and
three come from the repository-aware fallback.

## Fixture map

| File | Demonstrates |
|---|---|
| `fixtures/mdo-primary.md` | Markdown badge splitting, code-span punctuation, and balanced parentheses |
| `fixtures/html-and-fallback.html` | HTML attributes, entity decoding, and element boundaries |
| `fixtures/source-placeholders.js` | Rejection of unresolved source-code templates |

## Run the comparison

The scripts expect compatible .NET scanner CLI projects that accept:

```text
<fixture-directory> --output <json-path> --quiet
```

Run the same fixture set against the baseline and integrated implementations:

```powershell
.\compare.ps1 `
  -BaselineScannerProject <path-to-baseline-scanner.csproj> `
  -IntegratedScannerProject <path-to-integrated-scanner.csproj>
```

Verify only the integrated implementation:

```powershell
.\verify.ps1 -ScannerProject <path-to-integrated-scanner.csproj>
```

Generated reports are written under `proof/` and are ignored by Git.

See the shareable [`MDO-COMPARISON-PROOF.md`](MDO-COMPARISON-PROOF.md) for the
complete controlled A/B evidence. [`RESULTS.md`](RESULTS.md) contains the
shorter result summary.
