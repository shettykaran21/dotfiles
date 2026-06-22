#!/bin/bash
# Build 4 fixture git repos for pr-description skill tests.
# Each fixture is a fresh isolated repo with a specific state that tests one facet of the skill.
set -e

FIXTURES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$FIXTURES_DIR"

# Clean slate
rm -rf test1-no-template test2-with-template test3-existing-body test4-gh-unauth

# ---------- Test 1: current branch, no template, unstaged changes ----------
(
  mkdir -p test1-no-template && cd test1-no-template
  git init -q -b master
  git config user.email "fixture@example.com"
  git config user.name "Fixture"

  mkdir -p src/main/resources
  cat > src/main/resources/application.yml <<'EOF'
spring:
  profiles:
    active: dev
server:
  port: 8080
queue:
  inbound: prod_inbound_queue
EOF
  cat > src/main/resources/config.json <<'EOF'
{
  "columns": [
    {"name": "viewable", "type": "pct"},
    {"name": "blocked", "type": "pct"}
  ]
}
EOF
  git add . && git commit -q -m "Initial commit"

  git checkout -q -b PORT-1783-column-headers-v2
  # Commit: reorder columns in config.json
  cat > src/main/resources/config.json <<'EOF'
{
  "columns": [
    {"name": "totalEligible", "type": "count"},
    {"name": "viewable", "type": "pct"},
    {"name": "blocked", "type": "pct"},
    {"name": "failed", "type": "pct"}
  ]
}
EOF
  git add src/main/resources/config.json
  git commit -q -m "PORT-1783: Align column headers with metrics in report"

  # Unstaged change to application.yml that should be flagged as out-of-scope
  sed -i '' 's/prod_inbound_queue/dev_inbound_queue_karan/' src/main/resources/application.yml
)

# ---------- Test 2: current branch, with custom template ----------
(
  mkdir -p test2-with-template && cd test2-with-template
  git init -q -b main
  git config user.email "fixture@example.com"
  git config user.name "Fixture"

  mkdir -p .github src/main/java/com/example
  cat > .github/pull_request_template.md <<'EOF'
## What does this PR do?
<!-- Brief summary of the change -->

## Why is this change needed?
<!-- Link to ticket, explain motivation -->

## How was this tested?
- [ ] Unit tests pass
- [ ] Manually verified

## Rollback plan
<!-- How to revert if something goes wrong -->

## Screenshots (if UI change)
EOF

  cat > src/main/java/com/example/Metric.java <<'EOF'
package com.example;

public class Metric {
    private double value;
    public double getValue() { return value; }
}
EOF
  git add . && git commit -q -m "Initial"

  git checkout -q -b feat/DDL-2026-fix-c-lvl-metrics
  cat > src/main/java/com/example/Metric.java <<'EOF'
package com.example;

public class Metric {
    private double value;
    private boolean cLvl;
    public double getValue() { return cLvl ? value * 1.0 : value; }
    public boolean isCLvl() { return cLvl; }
    public void setCLvl(boolean cLvl) { this.cLvl = cLvl; }
}
EOF
  git add . && git commit -q -m "DDL-2026: Fix c_lvl metric calculation"

  cat > src/main/java/com/example/MetricTest.java <<'EOF'
package com.example;
public class MetricTest {}
EOF
  git add . && git commit -q -m "DDL-2026: Add test scaffold for c_lvl metric"
)

# ---------- Test 3: existing PR body, merge case ----------
(
  mkdir -p test3-existing-body && cd test3-existing-body
  git init -q -b master
  git config user.email "fixture@example.com"
  git config user.name "Fixture"

  mkdir -p src/uploader
  cat > src/uploader/s3.py <<'EOF'
def upload(path, bucket):
    import boto3
    s3 = boto3.client('s3')
    s3.upload_file(path, bucket, path)
EOF
  git add . && git commit -q -m "Initial"

  git checkout -q -b PORT-1900-retry-logic
  cat > src/uploader/s3.py <<'EOF'
import time

def upload(path, bucket, max_retries=3):
    import boto3
    s3 = boto3.client('s3')
    for attempt in range(max_retries):
        try:
            s3.upload_file(path, bucket, path)
            return
        except Exception:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)
EOF
  git add . && git commit -q -m "PORT-1900: Add retry logic to S3 uploader"

  # Two NEW commits after the existing PR body was written
  cat >> src/uploader/s3.py <<'EOF'

def upload_many(paths, bucket):
    for p in paths:
        upload(p, bucket)
EOF
  git add . && git commit -q -m "PORT-1900: Add upload_many helper for batch uploads"

  cat > src/uploader/s3_test.py <<'EOF'
def test_upload_retries():
    pass

def test_upload_many_continues_on_failure():
    pass
EOF
  git add . && git commit -q -m "PORT-1900: Add tests for retry behavior and batch uploads"
)

# ---------- Test 4: no git context, gh unauth scenario ----------
(
  mkdir -p test4-gh-unauth
  # Intentionally empty — no git repo. The prompt will provide a PR URL and
  # simulate gh being unauthenticated.
  echo "Scratch dir for Test 4" > test4-gh-unauth/README.txt
)

echo "Fixtures built:"
for dir in test1-no-template test2-with-template test3-existing-body test4-gh-unauth; do
  echo "  - $dir"
done
