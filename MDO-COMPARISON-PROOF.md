# MDO URL extraction: controlled A/B proof

**Test date:** September 25, 2026 PDT

## Purpose

This document demonstrates the measured value of using MDO as the primary
HTTP/HTTPS extractor while retaining repository-aware validation and fallback.

The comparison used the same synthetic repository files for both variants:

- **Without MDO:** existing repository URL parsing.
- **With MDO:** MDO primary extraction plus validation and fallback.

Only the scanner implementation changed. The fixture inputs and expected URL
labels remained identical.

## Test repository

The corpus contains three files and 11 manually labeled concrete URLs:

| Fixture | Cases covered |
|---|---|
| `fixtures/mdo-primary.md` | Markdown badge, code span, balanced parentheses |
| `fixtures/html-and-fallback.html` | HTML attributes, entity decoding, element boundaries |
| `fixtures/source-placeholders.js` | `${port}`, `$()`, `$HOST`, and `{userId}` templates |

## Results

| Metric | Without MDO | With MDO |
|---|---:|---:|
| Expected concrete URLs | 11 | 11 |
| Expected URLs represented correctly | 7 | **11** |
| Malformed or unresolved candidates | 6 | **0** |
| Total candidates returned | 13 | **11** |
| Precision on this corpus | 53.8% | **100%** |
| Recall on this corpus | 63.6% | **100%** |

### Observed differences

| Input case | Without MDO | With MDO |
|---|---|---|
| Markdown badge | Returned one malformed combined candidate | Returned the image and destination URLs separately |
| URL inside Markdown code span | Missed the complete URL | Returned the complete URL |
| HTML `&amp;` entity | Kept the encoded entity | Returned the decoded `&` URL |
| `http://localhost:${port}` | Returned truncated `http://localhost` | Rejected the unresolved template |
| URL containing `$()` | Returned a dynamic candidate | Rejected |
| URL containing `$HOST` | Returned a dynamic candidate | Rejected |
| URL containing `{userId}` | Returned a dynamic candidate | Rejected |

## With-MDO provenance

The 11 accepted URLs were attributed as follows:

| Extraction path | Accepted URLs |
|---|---:|
| MDO primary | 8 |
| Repository-aware fallback | 3 |
| Other | 0 |

This shows that MDO is the primary extractor without replacing useful fallback
behavior.

## End-to-end confirmation

The same fixture archive was processed through complete local test stacks for
both variants, including request submission, bundle materialization, scanning,
artifact creation, and completion reporting.

| Metric | Without MDO | With MDO |
|---|---:|---:|
| Terminal status | Completed | Completed |
| Files scanned | 3 | 3 |
| URL matches | 13 | **11 validated** |
| MDO matches | Not available | 8 |
| Fallback matches | Not available | 3 |
| Enrichment artifact produced | Yes | Yes |

The end-to-end counts match the direct scanner comparison: the baseline
retained 13 candidates, including six known parsing problems, while the
integrated scanner retained exactly the 11 labeled concrete URLs.

## Validation

- Focused integration tests: **40 passed**.
- Full URL pipeline suite: **213 passed, 1 skipped**.
- Production scanner projects built successfully.
- Independent review completed with no open findings.

## Reproduce

Run both scanner variants against the same fixture directory:

```powershell
.\compare.ps1 `
  -BaselineScannerProject <path-to-baseline-scanner.csproj> `
  -IntegratedScannerProject <path-to-integrated-scanner.csproj>
```

The script fails unless it reproduces:

- 13 baseline candidates;
- six known baseline parsing problems;
- 11 integrated URLs;
- eight MDO results; and
- three fallback results.

## Conclusion

For this controlled corpus, the MDO integration improved correct URL
representation from **7/11 to 11/11** and reduced malformed or unresolved
candidates from **six to zero**.

This is evidence for the specific Markdown, HTML, punctuation, and template
defects represented here. It is not a claim of universal accuracy across every
repository, language, or URL format.
