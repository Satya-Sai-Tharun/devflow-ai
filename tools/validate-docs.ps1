<#
.SYNOPSIS
    Documentation validator for the DevFlow AI repository.

.DESCRIPTION
    Checks the project-owned Markdown documentation for the failure modes that
    actually occur in this repository: broken relative links, unbalanced code
    fences, Mermaid blocks that cannot parse, unsupported implementation or
    performance claims, decision-status dishonesty, lifecycle-contract drift
    between restating documents, and stale repository facts.

    This is a documentation quality gate. It validates prose, not software, and
    it is NOT a CI system, a security scanner, or a substitute for review.

    Scope notes:
      - Only project-owned Markdown is checked. The gitignored third-party skill
        libraries (.agents, .claude, .codex, .opencode) and the generated
        graphify-out/ tree are always excluded.
      - The repository currently contains no application code. This script does
        not test application behaviour.
      - This script is intentionally ASCII-only. Windows PowerShell 5.1 reads
        BOM-less files as ANSI, which corrupts non-ASCII characters.

.PARAMETER RepoRoot
    Repository root. Defaults to the parent directory of this script.

.PARAMETER Verbose
    Lists every passing check in addition to failures.

.EXAMPLE
    powershell -File tools/validate-docs.ps1
    powershell -File tools/validate-docs.ps1 -Verbose

.NOTES
    Exit codes: 0 = all checks passed, 1 = at least one check failed,
                2 = the validator could not run (bad repository root).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------- setup

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Write-Host "FATAL: repository root not found: $RepoRoot" -ForegroundColor Red
    exit 2
}

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

# Directories that are never project-owned documentation.
$ExcludedPathPattern = '^(\.agents|\.claude|\.codex|\.opencode|graphify-out|node_modules|\.git)[\\/]'

$script:Failures = New-Object System.Collections.Generic.List[string]
$script:LinkCount = 0
$script:MermaidCount = 0

# Windows PowerShell 5.1 decodes BOM-less files as ANSI, which silently corrupts
# every non-ASCII character this documentation set uses (arrows, em dashes,
# section signs). That breaks any check that matches such a character and hides
# real content from the validator. All text reads therefore go through explicit
# UTF-8 rather than Get-Content -Raw.
$script:Utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-TextFile {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, $script:Utf8)
}

function Write-Head {
    param([string]$Text)
    Write-Host ''
    Write-Host "== $Text" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Text)
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host "  PASS  $Text" -ForegroundColor DarkGray
    }
}

function Write-Fail {
    param([string]$Check, [string]$Detail)
    $script:Failures.Add("[$Check] $Detail")
    Write-Host "  FAIL  $Detail" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  info  $Text" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- discovery

Write-Host ''
Write-Host 'DevFlow AI documentation validator' -ForegroundColor White
Write-Host "root: $RepoRoot" -ForegroundColor DarkGray

$allMarkdown = @()
Push-Location -LiteralPath $RepoRoot
try {
    # Tracked + untracked, excluding gitignored files (-co --exclude-standard),
    # so newly authored documentation is validated before it is ever committed.
    $listed = & git ls-files -co --exclude-standard 2>$null
    if ($LASTEXITCODE -eq 0 -and $listed) {
        $allMarkdown = @($listed |
            Where-Object { $_ -match '\.md$' } |
            Where-Object { $_ -notmatch $ExcludedPathPattern })
    }
}
finally {
    Pop-Location
}

if ($allMarkdown.Count -eq 0) {
    Write-Host 'FATAL: no project Markdown files discovered (is git available, and is this the repo root?)' -ForegroundColor Red
    exit 2
}

$allMarkdown = @($allMarkdown | Sort-Object -Unique)
Write-Info "documentation files in scope: $($allMarkdown.Count)"

# Regexes used by more than one check.
$LinkRegex = [regex]'\]\(([^)#\s]+?)(#[^)]*)?\)'

# ================================================================ CHECK 1
# Internal relative link integrity.
Write-Head 'Internal relative link integrity'

foreach ($doc in $allMarkdown) {
    $fullPath = Join-Path $RepoRoot $doc
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }

    $docDir = Split-Path -Parent $doc
    $content = Read-TextFile -Path $fullPath

    foreach ($m in $LinkRegex.Matches($content)) {
        $target = $m.Groups[1].Value

        # Skip absolute URLs, anchors, protocol-relative links, and @path syntax.
        if ($target -match '^(https?:|mailto:|ftp:|@|#|//)') { continue }

        $script:LinkCount++
        $decoded = [uri]::UnescapeDataString($target)
        $resolved = if ($docDir) { Join-Path $docDir $decoded } else { $decoded }

        try { $resolved = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $resolved)) }
        catch { Write-Fail 'links' "$doc -> $target (unresolvable path)"; continue }

        if (-not (Test-Path -LiteralPath $resolved)) {
            Write-Fail 'links' "$doc -> $target (target does not exist)"
        }
    }
}
Write-Pass "$($script:LinkCount) relative links resolve"

# ================================================================ CHECK 2
# Code fence balance and Mermaid block syntax.
Write-Head 'Code fences and Mermaid blocks'

$validDiagramHeads = @(
    'flowchart', 'graph', 'sequenceDiagram', 'stateDiagram-v2', 'stateDiagram',
    'erDiagram', 'classDiagram', 'journey', 'gantt', 'pie', 'quadrantChart',
    'mindmap', 'timeline', 'gitGraph', 'block-beta', 'requirementDiagram',
    'sankey-beta', 'xychart-beta'
)

foreach ($doc in $allMarkdown) {
    $fullPath = Join-Path $RepoRoot $doc
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }

    $lines = Get-Content -LiteralPath $fullPath
    $fenceTotal = @($lines | Where-Object { $_ -match '^\s*```' }).Count

    if ($fenceTotal % 2 -ne 0) {
        Write-Fail 'fences' "$doc has an unbalanced number of code fences ($fenceTotal)"
    }
    else {
        Write-Pass "$doc fences balanced ($fenceTotal)"
    }

    $inMermaid = $false
    $block = @()
    $blockStart = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if (-not $inMermaid -and $line -match '^\s*```mermaid\s*$') {
            $inMermaid = $true
            $block = @()
            $blockStart = $i + 1
            continue
        }

        if ($inMermaid -and $line -match '^\s*```\s*$') {
            $inMermaid = $false
            $script:MermaidCount++

            $body = @($block | Where-Object { $_.Trim() -ne '' })
            $where = "$doc line $blockStart"

            if ($body.Count -eq 0) {
                Write-Fail 'mermaid' "$where is an empty Mermaid block"
                continue
            }

            $first = $body[0].Trim()
            $headOk = $false
            foreach ($vh in $validDiagramHeads) {
                if ($first -eq $vh -or $first.StartsWith("$vh ")) { $headOk = $true; break }
            }

            if (-not $headOk) {
                Write-Fail 'mermaid' "$where has an unrecognised diagram type: '$first'"
            }
            else {
                Write-Pass "$where Mermaid '$($first.Split(' ')[0])'"
            }

            # A line inside a bracketed label with an odd number of quotes is
            # usually an unescaped label that will break rendering.
            $oddQuote = 0
            foreach ($bl in $body) {
                if ($bl -match '\[[^\]]*"' -and ((@($bl.ToCharArray() | Where-Object { $_ -eq '"' }).Count) % 2 -ne 0)) {
                    $oddQuote++
                }
            }
            if ($oddQuote -gt 0) {
                Write-Fail 'mermaid' "$where has $oddQuote line(s) with unbalanced double quotes"
            }

            # erDiagram: relationship lines have the form
            #   ENTITY_A <cardinality> ENTITY_B : "label"
            # A bare column definition (for example 'uuid owner_id FK') must not
            # be mistaken for a relationship, so require the quoted label.
            if ($first -eq 'erDiagram') {
                $relCount = 0
                foreach ($bl in $body) {
                    $t = $bl.Trim()
                    if ($t -eq '' -or $t -eq 'erDiagram') { continue }

                    # A block opened with '{' starts an attribute list; its lines
                    # are columns, not relationships.
                    if ($t -match '\{$') { continue }

                    $isRelationship = $t -match '^\w+\s+(\|\||o\{|o\||\}o|\}\||\|o|\|\{)\s*--\s*(\|\||o\{|o\||\}o|\}\||\|o|\|\{)\s+\w+\s*:\s*"'
                    if ($isRelationship) {
                        $relCount++
                        continue
                    }

                    # Anything containing a cardinality token but not matching the
                    # relationship form is malformed.
                    if ($t -match '(\|\||o\{|\}o|\|\{)') {
                        Write-Fail 'mermaid' "$where erDiagram relationship is malformed: '$t'"
                    }
                }
                Write-Pass "$where erDiagram parsed ($relCount relationships)"
            }
            continue
        }

        if ($inMermaid) { $block += $line }
    }

    if ($inMermaid) {
        Write-Fail 'mermaid' "$doc has an unterminated Mermaid block starting at line $blockStart"
    }
}
Write-Info "Mermaid diagrams checked: $($script:MermaidCount)"

# ================================================================ CHECK 3
# Unsupported implementation / performance claims.
Write-Head 'Unsupported implementation and performance claims'

# A claim states that something exists or passed. Because the repository has no
# application code and no measurements, such a statement must be either negated
# or explicitly qualified.
#
# These patterns match the AFFIRMATIVE form only, and 'passing tests' requires a
# completed state ('tests passed' / 'tests are passing') rather than the bare
# conditional 'tests pass' used when stating a future CI requirement.
#
# Note that 'assume exactly-once' is deliberately NOT treated as an affirmative
# claim: in this repository it appears exclusively as a prohibition ("must not
# assume exactly-once delivery"), never as an assertion.
$claimPatterns = @(
    @{ Name = 'implementation'; Pattern = '\b(?:is|are|was|were|has been|have been)\s+implemented\b' },
    @{ Name = 'passing tests';  Pattern = '\btests?\s+(?:passed|are passing|were passing)\b' },
    @{ Name = 'measured perf';  Pattern = '\b(?:has|have)\s+been\s+measured\b' },
    @{ Name = 'certification';  Pattern = '\b(?:SOC\s?2|ISO\s?27001|PCI-DSS|HIPAA-compliant|GDPR-compliant)\b' },
    @{ Name = 'exactly-once';   Pattern = '\b(?:is|are|was|were|be|been|has been|have been|provides?|provided|offers?|guarantees?|guaranteed|promises?|promised|claims?|claimed|gives?|delivers?|delivered|ensures?|ensured)\s+exactly-once\b' }
)

# A match is not a claim if the text either before OR after it negates, hedges,
# or conditions the statement. Looking both ways matters: this documentation set
# routinely writes "must not be promised" and "assume exactly-once delivery"
# as prohibitions, where the negation follows the matched phrase.
$negators = 'not|never|no|none|nobody|nothing|without|cannot|must not|must never|do not|does not|did not|neither|nor|absent|avoid|avoids|avoided|reject|rejects|rejected|forbid|forbids|forbidden|disallow|disallows|refuse|refuses|unverified|unmeasured|unproven|unqualified|proposed|planned|target|future|intended|expect|expected|would|should|may|might|will|if|unless|until|before|after|once|whether|only|required|require|requires|isn|aren|don|doesn|wasn|weren|hasn|haven|can'

$claimCount = 0
foreach ($doc in $allMarkdown) {
    $fullPath = Join-Path $RepoRoot $doc
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }

    $lines = @(Read-TextFile -Path $fullPath -split "?
")
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Documentation explains claims as often as it makes them. A sentence
        # that reads as a prohibition, a warning, or a required future test is
        # not an affirmative claim, so scan both directions around a match.
        foreach ($cp in $claimPatterns) {
            foreach ($m in ([regex]::Matches($line, $cp.Pattern, 'IgnoreCase'))) {
                $preStart = [Math]::Max(0, $m.Index - 110)
                $pre = $line.Substring($preStart, $m.Index - $preStart)

                $postLen = [Math]::Min(110, $line.Length - ($m.Index + $m.Length))
                $post = if ($postLen -gt 0) { $line.Substring($m.Index + $m.Length, $postLen) } else { '' }

                if ($pre -match "(?i)\b($negators)\b") { continue }
                if ($post -match "(?i)\b($negators)\b") { continue }

                $claimCount++
                Write-Fail 'claims' "$doc line $($i + 1) unqualified '$($cp.Name)' claim: $($line.Trim())"
            }
        }
    }
}
if ($claimCount -eq 0) { Write-Pass 'no unqualified implementation or performance claims' }

# ================================================================ CHECK 4
# Decision-record honesty: every ADR declares a valid status and is indexed.
Write-Head 'Decision record (ADR) status and indexing'

$decisionsDir = Join-Path $RepoRoot 'docs/decisions'
if (-not (Test-Path -LiteralPath $decisionsDir)) {
    Write-Info 'docs/decisions/ does not exist; skipping ADR checks'
}
else {
    $adrFiles = @(Get-ChildItem -LiteralPath $decisionsDir -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'README.md' } | Sort-Object Name)

    $validStatuses = @('Accepted', 'Proposed', 'Rejected', 'Superseded', 'Deprecated')
    $readmePath = Join-Path $decisionsDir 'README.md'
    $readme = if (Test-Path -LiteralPath $readmePath) { Read-TextFile -Path $readmePath } else { '' }

    $statusTally = @{}
    foreach ($adr in $adrFiles) {
        $rel = "docs/decisions/$($adr.Name)"
        $text = Read-TextFile -Path $adr.FullName

        $statusMatch = [regex]::Match($text, '(?im)^\s*[-*]?\s*\*\*Status:\*\*\s*([^\r\n]*)')
        if (-not $statusMatch.Success) {
            $statusMatch = [regex]::Match($text, '(?im)^\s*[-*]?\s*Status:\s*([^\r\n]*)')
        }

        if (-not $statusMatch.Success) {
            Write-Fail 'adr' "$rel does not declare a Status"
        }
        else {
            $declared = $statusMatch.Groups[1].Value.Trim()
            $found = @($validStatuses | Where-Object { $declared -match [regex]::Escape($_) })
            if ($found.Count -eq 0) {
                Write-Fail 'adr' "$rel has an unrecognised status: '$declared'"
            }
            else {
                $key = $found[0]
                if (-not $statusTally.ContainsKey($key)) { $statusTally[$key] = 0 }
                $statusTally[$key]++
                Write-Pass "$rel status $key"
            }
        }

        # Required sections. ADRs in this repository use '## Decision' and
        # '## Decision (recommended)', so trailing qualifiers are permitted.
        foreach ($section in @('## Context', '## Decision')) {
            if ($text -notmatch "(?m)^$([regex]::Escape($section))(\s.*)?$") {
                Write-Fail 'adr' "$rel is missing required section '$section'"
            }
        }

        if ($readme -and $readme -notmatch [regex]::Escape($adr.Name)) {
            Write-Fail 'adr' "$rel is not listed in docs/decisions/README.md"
        }
    }

    # The index must not reference a non-existent record.
    foreach ($m in [regex]::Matches($readme, '\]\((\d{4}-[^)]+\.md)\)')) {
        $target = $m.Groups[1].Value
        if (-not (Test-Path -LiteralPath (Join-Path $decisionsDir $target))) {
            Write-Fail 'adr' "docs/decisions/README.md links to a missing record: $target"
        }
    }

    Write-Info "ADR files found: $($adrFiles.Count)"
    if ($statusTally.Count -gt 0) {
        $summary = (@($statusTally.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" })) -join ', '
        Write-Info "ADR status distribution: $summary"
    }
    if ($statusTally.ContainsKey('Proposed') -and $statusTally['Proposed'] -gt 0) {
        Write-Info "$($statusTally['Proposed']) decision(s) remain Proposed and are NOT binding - owner input required"
    }
}

# ================================================================ CHECK 5
# Lifecycle-contract consistency across restating documents.
Write-Head 'Task lifecycle contract consistency'

$canonicalStates = @('queued', 'running', 'needs_approval', 'completed', 'failed', 'cancelled', 'blocked')

$restatingDocs = @(
    'SPEC.md',
    'ARCHITECTURE.md',
    'PROJECT_CONTEXT.md',
    'docs/API_CONTRACTS.md',
    'docs/THREAT_MODEL.md'
) | Where-Object { Test-Path -LiteralPath (Join-Path $RepoRoot $_) }

if ($restatingDocs.Count -lt 2) {
    Write-Info 'fewer than two restating documents found; skipping consistency check'
}
else {
    foreach ($doc in $restatingDocs) {
        $text = Read-TextFile -Path (Join-Path $RepoRoot $doc)
        foreach ($state in $canonicalStates) {
            if ($text -notmatch "\b$([regex]::Escape($state))\b") {
                Write-Fail 'lifecycle' "$doc does not mention canonical state '$state'"
            }
        }
        Write-Pass "$doc references the canonical state set"
    }

    # The approval-outcome decision was formerly an open gap (rejected/expired
    # approvals had no legal destination). The owner resolved it on 2026-10-13:
    # needs_approval -> failed, with distinct terminal reasons. This check now
    # guards the RESOLUTION rather than the gap, so a silent regression back to
    # an ambiguous state fails the build.
    $specText = Read-TextFile -Path (Join-Path $RepoRoot 'SPEC.md')

    # Acceptance may be expressed with an ASCII arrow ("->") or a Unicode
    # rightwards arrow. The arrow is built from its code point so this script
    # stays pure ASCII: Windows PowerShell 5.1 reads BOM-less files as ANSI and
    # would corrupt a literal non-ASCII character.
    #
    # Markdown wraps each state in backticks, which collide with PowerShell's own
    # escape character when embedded in a regex string. Stripping backticks from
    # the text before matching removes that whole class of escaping bug and makes
    # the check easy to read.
    #
    # Whitespace is matched with [^\S\r\n] rather than \s on purpose: \s matches
    # newlines, which would let "needs_approval" at the end of one line and
    # "failed" on a later line satisfy the check even when no transition exists.
    # The transition must appear on a single line.
    $arrow = [char]0x2192
    $specPlain = $specText -replace '`', ''
    $gap = "[^\S\r\n]*"
    $needsApprovalToFailed = "needs_approval" + $gap + "(?:->|" + $arrow + ")" + $gap + "failed"

    if ($specPlain -notmatch $needsApprovalToFailed) {
        Write-Fail 'lifecycle' "SPEC.md no longer includes the 'needs_approval -> failed' transition, which was accepted on 2026-10-13 (docs/decisions/0010)"
    }
    else { Write-Pass "SPEC.md includes the accepted 'needs_approval -> failed' transition" }

    foreach ($reason in @('approval_rejected', 'approval_expired')) {
        if ($specText -notmatch [regex]::Escape($reason)) {
            Write-Fail 'lifecycle' "SPEC.md does not define the accepted terminal reason '$reason' (docs/decisions/0010)"
        }
        else { Write-Pass "SPEC.md defines terminal reason '$reason'" }
    }

    if ($specText -match 'Known gap') {
        Write-Fail 'lifecycle' 'SPEC.md still describes an open approval-outcome "Known gap", but it was resolved on 2026-10-13; the stale gap text must be removed'
    }

    $adr10 = Join-Path $RepoRoot 'docs/decisions/0010-approval-outcome-transitions.md'
    if (-not (Test-Path -LiteralPath $adr10)) {
        Write-Fail 'lifecycle' 'docs/decisions/0010-approval-outcome-transitions.md is missing but referenced by SPEC.md'
    }
    else {
        $adr10Text = Read-TextFile -Path $adr10
        if ($adr10Text -notmatch '(?im)^\s*[-*]?\s*\*\*Status:\*\*\s*\*\*Accepted\*\*') {
            Write-Fail 'lifecycle' 'ADR 0010 is not marked Accepted, but SPEC.md implements its accepted transition; the two must agree'
        }
        else { Write-Pass 'ADR 0010 is Accepted and consistent with SPEC.md' }
    }

    # PERFORMANCE.md is authoritative for budgets; nothing else may claim to be.
    $perfPath = Join-Path $RepoRoot 'docs/PERFORMANCE.md'
    if (Test-Path -LiteralPath $perfPath) {
        $perf = Read-TextFile -Path $perfPath
        if ($perf -match '(?i)authoritative') { Write-Pass 'docs/PERFORMANCE.md declares budget authority' }
    }
}

# ================================================================ CHECK 6
# Declared repository facts must match the checkout.
Write-Head 'Repository fact freshness'

Push-Location -LiteralPath $RepoRoot
try { $headCommit = (& git rev-parse HEAD 2>$null) }
finally { Pop-Location }

if (-not $headCommit) {
    Write-Info 'git rev-parse failed; skipping freshness check'
}
else {
    $shortCommit = $headCommit.Substring(0, 7)
    Write-Info "HEAD = $shortCommit"

    # .agent-state/CURRENT.md records the commit its facts were verified against.
    #
    # The correct test is ANCESTRY, not equality. A document does not become false
    # merely because a later commit exists - that would make the check fail after
    # every single commit and train the reader to ignore it. What genuinely
    # invalidates a verification claim is the commit disappearing (unknown to the
    # repository) or no longer being in HEAD's history (history rewritten, reset,
    # or rebased). Both of those are real defects and still fail.
    $currentStatePath = Join-Path $RepoRoot '.agent-state/CURRENT.md'
    if (Test-Path -LiteralPath $currentStatePath) {
        $cs = Read-TextFile -Path $currentStatePath
        $commitClaim = [regex]::Match($cs, '(?im)commit\s+`?([0-9a-f]{7,40})')
        if ($commitClaim.Success) {
            $claimed = $commitClaim.Groups[1].Value

            Push-Location -LiteralPath $RepoRoot
            try {
                $null = & git cat-file -e "$claimed^{commit}" 2>$null
                $claimIsReal = ($LASTEXITCODE -eq 0)

                $null = & git merge-base --is-ancestor $claimed HEAD 2>$null
                $claimIsAncestor = ($LASTEXITCODE -eq 0)

                $behind = 0
                if ($claimIsAncestor -and ($headCommit -notlike "$claimed*")) {
                    $behind = @(& git rev-list --count "$claimed..HEAD" 2>$null)[0]
                }
            }
            finally { Pop-Location }

            if (-not $claimIsReal) {
                Write-Fail 'staleness' ".agent-state/CURRENT.md claims verification at commit $claimed, which does not exist in this repository"
            }
            elseif (-not $claimIsAncestor) {
                Write-Fail 'staleness' ".agent-state/CURRENT.md claims verification at commit $claimed, which is NOT an ancestor of HEAD ($shortCommit) - history was rewritten, reset, or rebased since that verification"
            }
            elseif ($headCommit -like "$claimed*") {
                Write-Pass ".agent-state/CURRENT.md verification commit ($claimed) is HEAD"
            }
            else {
                Write-Pass ".agent-state/CURRENT.md verification commit ($claimed) is an ancestor of HEAD ($behind commit(s) since); facts may need re-verification if those commits changed the repository"
            }
        }
        else {
            Write-Info '.agent-state/CURRENT.md does not pin a commit; freshness cannot be checked automatically'
        }
    }

    # The repository must not silently acquire application code while documents
    # still insist it is documentation-only.
    Push-Location -LiteralPath $RepoRoot
    try {
        $manifests = @(& git ls-files -co --exclude-standard 2>$null | Where-Object {
            $_ -match '(^|/)(pyproject\.toml|package\.json|requirements\.txt|poetry\.lock|uv\.lock|pnpm-lock\.yaml|package-lock\.json)$' -and
            $_ -notmatch $ExcludedPathPattern
        })
    }
    finally { Pop-Location }

    if ($manifests.Count -gt 0) {
        $docsOnlyClaimants = @()
        foreach ($d in @('PROJECT_CONTEXT.md', 'README.md', '.agent-state/CURRENT.md', 'AGENTS.md')) {
            $p = Join-Path $RepoRoot $d
            if (-not (Test-Path -LiteralPath $p)) { continue }
            $t = Read-TextFile -Path $p
            if ($t -match '(?i)(?:repository|checkout|project).{0,80}(?:documentation-only|documentation and specification only|no application code|no dependency manifest)|(?:documentation-only|documentation and specification only|no application code|no dependency manifest).{0,80}(?:repository|checkout|project)') {
                $docsOnlyClaimants += $d
            }
        }
        if ($docsOnlyClaimants.Count -gt 0) {
            Write-Fail 'staleness' "application manifests now exist ($($manifests -join ', ')) but these documents still claim documentation-only: $($docsOnlyClaimants -join ', ')"
        }
        else { Write-Pass 'application manifests present and no stale documentation-only claim' }
    }
    else {
        Write-Pass 'no application manifests present (consistent with documentation-only status)'
    }
}

# ================================================================ CHECK 7
# Machine-specific absolute paths break portability.
Write-Head 'Portability (no machine-specific absolute paths)'

$absPathHits = 0
foreach ($doc in $allMarkdown) {
    $fullPath = Join-Path $RepoRoot $doc
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }
    $lines = @(Read-TextFile -Path $fullPath -split "?
")
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '[A-Za-z]:\\Users\\|[A-Za-z]:\\Program Files\\') {
            Write-Fail 'portability' "$doc line $($i + 1) contains a machine-specific absolute path"
            $absPathHits++
        }
    }
}
if ($absPathHits -eq 0) { Write-Pass 'no machine-specific absolute paths in documentation' }

# ================================================================ CHECK 8
# Line endings must match .gitattributes (eol=lf).
#
# A file committed with CRLF while .gitattributes mandates LF produces a diff
# on every touch, a normalisation churn on the next `git add`, and a permanent
# warning from git. This check enforces the declared policy on the text file
# types this repository owns. Files marked binary in .gitattributes are skipped,
# and tools/validate-docs.ps1 itself is included deliberately so the policy
# applies to the checker too.
Write-Head 'Line endings (must match .gitattributes eol=lf)'

$crlfChecked = 0
$crlfOffenders = 0
$textFilePattern = '\.(md|py|ts|tsx|js|jsx|json|ya?ml|toml|ps1|sh|css|scss|html|sql|txt|cfg|ini)$'
$binaryPattern   = '\.(png|jpe?g|gif|ico|pdf|zip|woff2?|ttf|eot|so|dll|exe)$'

# Every tracked or untracked-but-not-ignored project file, not only Markdown.
$allProjectFiles = @()
Push-Location -LiteralPath $RepoRoot
try {
    $allProjectFiles = @(& git ls-files -co --exclude-standard 2>$null |
        Where-Object { $_ -notmatch $ExcludedPathPattern })
}
finally { Pop-Location }

foreach ($rel in $allProjectFiles) {
    if ($rel -notmatch $textFilePattern) { continue }
    if ($rel -match $binaryPattern) { continue }

    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($full)
    $crlf = 0
    for ($i = 1; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 10 -and $bytes[$i - 1] -eq 13) { $crlf++ }
    }
    $crlfChecked++

    if ($crlf -gt 0) {
        Write-Fail 'line-endings' "$rel has $crlf CRLF line ending(s); .gitattributes declares 'eol=lf'"
        $crlfOffenders++
    }
}
if ($crlfChecked -gt 0) {
    if ($crlfOffenders -eq 0) { Write-Pass "$crlfChecked text file(s) use LF line endings" }
    else { Write-Info "$crlfOffenders of $crlfChecked text file(s) violate the LF policy" }
}

# ================================================================ summary

Write-Host ''
Write-Host ('-' * 72) -ForegroundColor DarkGray

if ($script:Failures.Count -eq 0) {
    Write-Host 'RESULT: PASS - no documentation defects found' -ForegroundColor Green
    Write-Host "checked: $($allMarkdown.Count) documents, $($script:LinkCount) links, $($script:MermaidCount) Mermaid diagrams" -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

Write-Host "RESULT: FAIL - $($script:Failures.Count) defect(s)" -ForegroundColor Red
Write-Host ''
$n = 1
foreach ($f in $script:Failures) {
    Write-Host "  $n. $f" -ForegroundColor Yellow
    $n++
}
Write-Host ''
Write-Host 'These are documentation defects. Fix them, or update the documentation' -ForegroundColor DarkGray
Write-Host 'to match reality - whichever is actually correct. Do not silence the check.' -ForegroundColor DarkGray
Write-Host ''
exit 1
