#!/usr/bin/env python3
import sys
import os

# Task manager script to add/update tasks displayed in fastfetch
TASKS_FILE = os.path.expanduser("~/.config/fastfetch/tasks.txt")

def read_tasks():
    if not os.path.exists(TASKS_FILE):
        return []
    with open(TASKS_FILE, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def write_tasks(tasks):
    os.makedirs(os.path.dirname(TASKS_FILE), exist_ok=True)
    with open(TASKS_FILE, 'w') as f:
        for t in tasks:
            f.write(t + "\n")

def add_or_update(task_text, new_prefix):
    tasks = read_tasks()
    found = False
    new_tasks = []
    
    cleaned_query = task_text.strip().lower()
    
    for t in tasks:
        content = t
        for pfx in ["[ ]", "[/]", "[x]", "- "]:
            if t.startswith(pfx):
                content = t[len(pfx):].strip()
                break
        
        if content.lower() == cleaned_query:
            new_tasks.append(f"{new_prefix} {content}")
            found = True
        else:
            new_tasks.append(t)
            
    if not found:
        new_tasks.append(f"{new_prefix} {task_text.strip()}")
        
    write_tasks(new_tasks)

def main():
    if len(sys.argv) < 3:
        print("Usage: manage_tasks.py <todo|doing|done> <task_text>")
        sys.exit(1)
        
    action = sys.argv[1]
    task_text = sys.argv[2]
    
    if action == "todo":
        add_or_update(task_text, "[ ]")
    elif action == "doing":
        add_or_update(task_text, "[/]")
    elif action == "done":
        add_or_update(task_text, "[x]")

if __name__ == "__main__":
    main()
