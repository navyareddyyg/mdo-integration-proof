# Controlled A/B results

The same three-file synthetic repository was scanned by a baseline URL parser
and by an implementation using MDO primary extraction with repository-aware
validation and fallback.

## URL comparison

| Metric | Baseline | Integrated |
|---|---:|---:|
| Expected concrete URLs | 11 | 11 |
| Expected URLs represented correctly | 7 | 11 |
| Malformed or unresolved candidates | 6 | 0 |
| Total candidates | 13 | 11 |
| Fixture precision | 53.8% | 100% |
| Fixture recall | 63.6% | 100% |

The integration:

- split a malformed Markdown badge candidate into two correct URLs;
- retained a complete URL inside a Markdown code span;
- decoded `&amp;` in an HTML URL attribute;
- rejected `${port}`, `$()`, `$HOST`, and `{userId}` templates.

## End-to-end confirmation

The same fixture archive was also processed through both complete local test
stacks.

| Metric | Baseline | Integrated |
|---|---:|---:|
| Terminal status | Completed | Completed |
| Files scanned | 3 | 3 |
| URL matches | 13 | 11 |
| MDO matches | Not available | 8 |
| Fallback matches | Not available | 3 |
| Other matches | Not available | 0 |
| Enrichment artifact | Produced | Produced |

Focused and full URL-pipeline regression suites passed for the integrated
implementation, followed by an independent review with no open findings.

## Scope

This controlled corpus demonstrates improvement for the represented parsing
defects. It does not claim universal precision or recall improvements across
all repositories, languages, or URL formats.
