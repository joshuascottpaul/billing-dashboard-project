#!/usr/bin/env python3
"""
Unit tests for tasks.yaml → TASKS.md generator.

Run:
    python tests/test_tasks_generator.py
"""
import sys
import tempfile
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))

from generate_tasks import (
    format_list,
    format_commit_plan,
    format_homebrew,
    generate_tasks_md,
)


def test_format_list_empty():
    """Empty list returns 'none'."""
    assert format_list([]) == "none"


def test_format_list_single():
    """Single item returns the item as string."""
    assert format_list(["OUTCOMES.md"]) == "OUTCOMES.md"
    assert format_list([123]) == "123"


def test_format_list_multiple():
    """Multiple items returns comma-separated string."""
    result = format_list(["A", "B", "C"])
    assert result == "A, B, C"


def test_format_commit_plan_empty():
    """Empty commit plan returns 'none yet'."""
    assert format_commit_plan({}) == "none yet"
    assert format_commit_plan(None) == "none yet"


def test_format_commit_plan_full():
    """Full commit plan returns conventional commit format."""
    plan = {
        "type": "feat",
        "scope": "orchestration",
        "subject": "add tasks board generator",
    }
    assert format_commit_plan(plan) == "feat(orchestration): add tasks board generator"


def test_format_commit_plan_no_scope():
    """Commit plan without scope omits parentheses."""
    plan = {
        "type": "docs",
        "subject": "update readme",
    }
    assert format_commit_plan(plan) == "docs: update readme"


def test_format_homebrew_empty():
    """Empty homebrew returns None."""
    assert format_homebrew({}) is None
    assert format_homebrew(None) is None


def test_format_homebrew_full():
    """Full homebrew returns formatted lines."""
    hb = {
        "formula": "my-formula",
        "tap_repo": "org/homebrew-tap",
        "smoke_command": "my-formula --version",
        "local_upgrade_when_installed": True,
    }
    result = format_homebrew(hb)
    assert "Formula: my-formula" in result
    assert "Tap Repo: org/homebrew-tap" in result
    assert "Smoke Command: my-formula --version" in result
    assert "Local Upgrade When Installed: true" in result


def test_generate_tasks_md_structure():
    """Generated markdown has expected structure."""
    tasks_data = {
        "metadata": {
            "repo": "test-repo",
            "last_updated": "2026-03-10",
        },
        "tasks": [
            {
                "id": "T-001",
                "title": "Test task",
                "owner": "test-agent",
                "reviewer": "review-agent",
                "status": "in_progress",
                "priority": "P0",
                "depends_on": [],
                "release_impact": "none",
                "inputs": ["README.md"],
                "output": "Test output",
                "acceptance_criteria": ["Criterion 1"],
                "test_plan": ["Test 1"],
                "commit_plan": {"type": "feat", "scope": "test", "subject": "add feature"},
                "rollback_plan": "Revert if broken",
                "evidence_links": [],
                "telemetry": ["test.metric"],
            }
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    # Check structure
    assert "# TASKS (Generated)" in result
    assert "Source of truth: `tasks.yaml`" in result
    assert "Last generated:" in result
    assert "## T-001: Test task" in result
    assert "- Owner: test-agent" in result
    assert "- Reviewer: review-agent" in result
    assert "- Priority: P0" in result
    assert "- Status: in_progress" in result
    assert "- Depends on: none" in result
    assert "- Release Impact: none" in result
    assert "- Inputs: README.md" in result
    assert "- Output: Test output" in result
    assert "- Acceptance Criteria:" in result
    assert "  - Criterion 1" in result
    assert "- Test Plan:" in result
    assert "  - Test 1" in result
    assert "- Commit Plan: feat(test): add feature" in result
    assert "- Rollback Plan: Revert if broken" in result
    assert "- Evidence Links: none" in result
    assert "- Telemetry: test.metric" in result


def test_generate_tasks_md_sorting():
    """Tasks are sorted by ID."""
    tasks_data = {
        "metadata": {},
        "tasks": [
            {"id": "T-003", "title": "Third"},
            {"id": "T-001", "title": "First"},
            {"id": "T-002", "title": "Second"},
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    # Check order
    first_pos = result.find("T-001")
    second_pos = result.find("T-002")
    third_pos = result.find("T-003")
    
    assert first_pos < second_pos < third_pos


def test_generate_tasks_md_homebrew_section():
    """Homebrew section only appears for homebrew tasks."""
    tasks_data = {
        "metadata": {},
        "tasks": [
            {
                "id": "T-001",
                "title": "Non-homebrew task",
                "owner": "test",
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": [],
                "release_impact": "app",
                "inputs": [],
                "output": "Output",
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
            },
            {
                "id": "T-002",
                "title": "Homebrew task",
                "owner": "homebrew-agent",
                "reviewer": "release-agent",
                "status": "todo",
                "priority": "P0",
                "depends_on": [],
                "release_impact": "homebrew",
                "inputs": [],
                "output": "Output",
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
                "homebrew": {
                    "formula": "test-formula",
                    "tap_repo": "org/tap",
                    "smoke_command": "test --version",
                    "local_upgrade_when_installed": True,
                },
            },
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    # T-001 should not have Homebrew section
    t001_section = result[result.find("## T-001"):result.find("## T-002")]
    assert "- Homebrew:" not in t001_section
    
    # T-002 should have Homebrew section
    t002_section = result[result.find("## T-002"):]
    assert "- Homebrew:" in t002_section
    assert "Formula: test-formula" in t002_section


def test_generate_tasks_md_depends_on():
    """Depends on formats correctly."""
    tasks_data = {
        "metadata": {},
        "tasks": [
            {
                "id": "T-001",
                "title": "No deps",
                "owner": "test",
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": [],
                "release_impact": "none",
                "inputs": [],
                "output": "Output",
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
            },
            {
                "id": "T-002",
                "title": "With deps",
                "owner": "test",
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": ["T-001", "T-003"],
                "release_impact": "none",
                "inputs": [],
                "output": "Output",
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
            },
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    assert "- Depends on: none" in result
    assert "- Depends on: T-001, T-003" in result


def test_generate_tasks_md_unicode():
    """Unicode characters in titles and descriptions render correctly."""
    tasks_data = {
        "metadata": {},
        "tasks": [
            {
                "id": "T-001",
                "title": "Task with émojis 🚀 and spëcial çhars",
                "owner": "test",
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": [],
                "release_impact": "none",
                "inputs": [],
                "output": "Output with €uro and £pound",
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
            },
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    assert "🚀" in result
    assert "émojis" in result
    assert "€uro" in result


def test_generate_tasks_md_long_fields():
    """Long text fields render without truncation."""
    long_title = "A" * 500
    long_output = "B" * 1000
    
    tasks_data = {
        "metadata": {},
        "tasks": [
            {
                "id": "T-001",
                "title": long_title,
                "owner": "test",
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": [],
                "release_impact": "none",
                "inputs": [],
                "output": long_output,
                "acceptance_criteria": [],
                "test_plan": [],
                "commit_plan": {},
                "rollback_plan": "Revert",
                "evidence_links": [],
                "telemetry": [],
            },
        ],
    }
    
    result = generate_tasks_md(tasks_data)
    
    assert long_title in result
    assert long_output in result


def test_generate_tasks_md_null_values():
    """None/null values handled gracefully."""
    tasks_data = {
        "metadata": {},
        "tasks": [
            {
                "id": "T-001",
                "title": "Task with nulls",
                "owner": None,
                "reviewer": "reviewer",
                "status": "todo",
                "priority": "P1",
                "depends_on": None,
                "release_impact": "none",
                "inputs": None,
                "output": "Output",
                "acceptance_criteria": None,
                "test_plan": None,
                "commit_plan": None,
                "rollback_plan": None,
                "evidence_links": None,
                "telemetry": None,
            },
        ],
    }
    
    # Should not crash - uses .get() with defaults
    result = generate_tasks_md(tasks_data)
    
    assert "T-001" in result
    assert "Task with nulls" in result


def test_generate_tasks_md_empty_tasks_list():
    """Empty tasks list generates valid (empty) output."""
    tasks_data = {
        "metadata": {},
        "tasks": [],
    }
    
    result = generate_tasks_md(tasks_data)
    
    assert "# TASKS (Generated)" in result
    assert "Source of truth: `tasks.yaml`" in result
    # Should not have any task sections
    assert "## T-" not in result


def run_tests():
    """Run all tests and report results."""
    tests = [
        test_format_list_empty,
        test_format_list_single,
        test_format_list_multiple,
        test_format_commit_plan_empty,
        test_format_commit_plan_full,
        test_format_commit_plan_no_scope,
        test_format_homebrew_empty,
        test_format_homebrew_full,
        test_generate_tasks_md_structure,
        test_generate_tasks_md_sorting,
        test_generate_tasks_md_homebrew_section,
        test_generate_tasks_md_depends_on,
        test_generate_tasks_md_unicode,
        test_generate_tasks_md_long_fields,
        test_generate_tasks_md_null_values,
        test_generate_tasks_md_empty_tasks_list,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            print(f"✓ {test.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {test.__name__}: Unexpected error: {e}")
            failed += 1
    
    print()
    print(f"Results: {passed} passed, {failed} failed")
    
    return failed == 0


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
