#!/usr/bin/env python3
"""
Generate TASKS.md from tasks.yaml

Usage:
    python scripts/generate_tasks.py [--check]

Options:
    --check    Exit with code 1 if TASKS.md is out of sync (for CI)
"""
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime


def ensure_yaml_available():
    """Ensure PyYAML is available, install if needed.
    
    Returns:
        yaml module
        
    Raises:
        SystemExit: If PyYAML cannot be installed
    """
    try:
        import yaml
        return yaml
    except ImportError:
        # Create/use a venv for the generator
        root_dir = Path(__file__).parent.parent
        venv_dir = root_dir / ".venv-tasks"
        
        if not venv_dir.exists():
            subprocess.run(
                [sys.executable, "-m", "venv", str(venv_dir)],
                check=True,
                timeout=120
            )
        
        pip_bin = venv_dir / "bin" / "pip3"
        subprocess.run(
            [str(pip_bin), "install", "--no-warn-script-location", "pyyaml"],
            check=True,
            timeout=300
        )
        
        # Re-import with the installed package (use dynamic python version)
        python_version = f"python{sys.version_info.major}.{sys.version_info.minor}"
        sys.path.insert(0, str(venv_dir / "lib" / python_version / "site-packages"))
        import yaml
        return yaml


def format_list(items, indent="  "):
    """Format a list as markdown bullets or comma-separated."""
    if not items:
        return "none"
    if len(items) == 1:
        return str(items[0])
    return ", ".join(str(item) for item in items)


def format_commit_plan(commit_plan):
    """Format commit_plan dict as conventional commit string."""
    if not commit_plan:
        return "none yet"
    type_ = commit_plan.get("type", "chore")
    scope = commit_plan.get("scope", "")
    subject = commit_plan.get("subject", "update")
    if scope:
        return f"{type_}({scope}): {subject}"
    return f"{type_}: {subject}"


def format_homebrew(homebrew):
    """Format homebrew section."""
    if not homebrew:
        return None
    lines = [
        f"  - Formula: {homebrew.get('formula', 'N/A')}",
        f"  - Tap Repo: {homebrew.get('tap_repo', 'N/A')}",
        f"  - Smoke Command: {homebrew.get('smoke_command', 'N/A')}",
        f"  - Local Upgrade When Installed: {'true' if homebrew.get('local_upgrade_when_installed') else 'false'}",
    ]
    return "\n".join(lines)


def generate_tasks_md(tasks_data):
    """Generate TASKS.md content from parsed YAML data."""
    metadata = tasks_data.get("metadata", {})
    tasks = tasks_data.get("tasks", [])
    
    # Sort tasks by ID for deterministic output
    tasks_sorted = sorted(tasks, key=lambda t: t.get("id", ""))
    
    lines = []
    lines.append("# TASKS (Generated)")
    lines.append("")
    lines.append("Source of truth: `tasks.yaml`")
    lines.append(f"Last generated: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("")
    
    for task in tasks_sorted:
        task_id = task.get("id", "UNKNOWN")
        title = task.get("title", "Untitled")
        
        lines.append(f"## {task_id}: {title}")
        lines.append(f"- Owner: {task.get('owner', 'unassigned')}")
        lines.append(f"- Reviewer: {task.get('reviewer', 'unassigned')}")
        lines.append(f"- Priority: {task.get('priority', 'P3')}")
        lines.append(f"- Status: {task.get('status', 'todo')}")
        
        depends_on = task.get("depends_on", [])
        lines.append(f"- Depends on: {format_list(depends_on)}")
        
        lines.append(f"- Release Impact: {task.get('release_impact', 'none')}")
        
        inputs = task.get("inputs", [])
        lines.append(f"- Inputs: {format_list(inputs)}")
        
        lines.append(f"- Output: {task.get('output', 'N/A')}")
        
        acceptance = task.get("acceptance_criteria", [])
        lines.append("- Acceptance Criteria:")
        if acceptance:
            for criterion in acceptance:
                lines.append(f"  - {criterion}")
        else:
            lines.append("  - None specified")
        
        test_plan = task.get("test_plan", [])
        lines.append("- Test Plan:")
        if test_plan:
            for test in test_plan:
                lines.append(f"  - {test}")
        else:
            lines.append("  - None specified")
        
        commit_plan = task.get("commit_plan", {})
        lines.append(f"- Commit Plan: {format_commit_plan(commit_plan)}")
        
        lines.append(f"- Rollback Plan: {task.get('rollback_plan', 'None specified')}")
        
        evidence = task.get("evidence_links", [])
        lines.append(f"- Evidence Links: {format_list(evidence)}")
        
        telemetry = task.get("telemetry", [])
        lines.append(f"- Telemetry: {format_list(telemetry)}")
        
        # Homebrew section (only if release_impact is homebrew)
        if task.get("release_impact") == "homebrew":
            homebrew = task.get("homebrew", {})
            hb_lines = format_homebrew(homebrew)
            if hb_lines:
                lines.append("- Homebrew:")
                lines.append(hb_lines)
        
        lines.append("")
    
    return "\n".join(lines) + "\n"


def main():
    """
    Main entry point for TASKS.md generator.
    
    Reads tasks.yaml, generates markdown, and writes to TASKS.md.
    In --check mode, validates sync and exits with code 1 if out of sync.
    
    Exit codes:
        0 - Success (or sync OK in check mode)
        1 - Error (or sync failed in check mode)
    """
    yaml = ensure_yaml_available()
    
    root_dir = Path(__file__).parent.parent
    tasks_yaml = root_dir / "tasks.yaml"
    tasks_md = root_dir / "TASKS.md"
    
    # Check mode
    check_mode = "--check" in sys.argv
    
    if not tasks_yaml.exists():
        print(f"Error: {tasks_yaml} not found", file=sys.stderr)
        sys.exit(1)
    
    # Read and parse tasks.yaml with error handling
    try:
        with open(tasks_yaml, "r", encoding="utf-8") as f:
            tasks_data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"Error: Invalid YAML in {tasks_yaml}: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to read {tasks_yaml}: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Validate structure
    if not tasks_data or not isinstance(tasks_data, dict):
        print(f"Error: {tasks_yaml} must contain a valid YAML dictionary", file=sys.stderr)
        sys.exit(1)
    
    # Validate tasks exist and have required fields
    tasks = tasks_data.get("tasks", [])
    if not tasks or not isinstance(tasks, list):
        print(f"Error: {tasks_yaml} must contain a 'tasks' list", file=sys.stderr)
        sys.exit(1)
    
    REQUIRED_TASK_FIELDS = ["id", "title", "owner", "status", "priority"]
    for idx, task in enumerate(tasks):
        if not isinstance(task, dict):
            print(f"Error: Task {idx} must be a dictionary", file=sys.stderr)
            sys.exit(1)
        missing = [f for f in REQUIRED_TASK_FIELDS if f not in task or not task[f]]
        if missing:
            task_id = task.get("id", f"Task {idx}")
            print(f"Error: Task {task_id}: missing required fields: {missing}", file=sys.stderr)
            sys.exit(1)
    
    # Generate content
    generated = generate_tasks_md(tasks_data)
    
    if check_mode:
        # Check if TASKS.md matches
        if not tasks_md.exists():
            print("Error: TASKS.md does not exist. Run 'python scripts/generate_tasks.py' to generate.", file=sys.stderr)
            sys.exit(1)
        
        with open(tasks_md, "r", encoding="utf-8") as f:
            existing = f.read()
        
        # Compare (ignoring the "Last generated" line which changes each run)
        def normalize(content):
            lines = content.split("\n")
            return [l for l in lines if not l.startswith("Last generated:")]
        
        if normalize(generated) != normalize(existing):
            print("Error: TASKS.md is out of sync with tasks.yaml", file=sys.stderr)
            print("Run 'python scripts/generate_tasks.py' to regenerate.", file=sys.stderr)
            sys.exit(1)
        
        print("OK: TASKS.md is in sync with tasks.yaml")
        sys.exit(0)
    else:
        # Write TASKS.md
        with open(tasks_md, "w", encoding="utf-8") as f:
            f.write(generated)
        
        print(f"Generated: {tasks_md}")
        print(f"Tasks: {len(tasks_data.get('tasks', []))}")


if __name__ == "__main__":
    main()
