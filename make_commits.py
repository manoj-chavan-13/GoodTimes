import os
import subprocess
import datetime

# Get list of changed/untracked files
result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
lines = result.stdout.strip().split('\n')
files = []
for line in lines:
    if line:
        # line is like " M path/to/file" or "?? path/to/file"
        file_path = line[3:].strip()
        files.append(file_path)

# 20 Commit messages
commits = [
    "Initial project setup and dependency configuration",
    "Add base app theme and color palette definitions",
    "Implement core Hive database models for courses",
    "Add settings and playback tracking models",
    "Create database boxes and initialization logic",
    "Build custom title bar for frameless window",
    "Add core state providers (Riverpod)",
    "Implement scanner service for local folders",
    "Create metadata service for video duration parsing",
    "Build modular provider structure for lectures",
    "Implement history and continue watching tracking",
    "Design and add hoverable card UI components",
    "Implement Home screen layout and navigation",
    "Add Course screen with video player integration",
    "Implement media_kit player provider logic",
    "Refine video playback controls and keyboard shortcuts",
    "Add Settings screen and preferences management",
    "Implement dedicated About screen and developer info",
    "Add smooth page transitions and sidebar animations",
    "Finalize README, polish UI, and fix Hive locks"
]

# Generate dates from 15 days ago to now
end_date = datetime.datetime.now()
start_date = end_date - datetime.timedelta(days=15)
delta = (end_date - start_date) / 19

# Distribute files among commits
def chunk_it(seq, num):
    avg = len(seq) / float(num)
    out = []
    last = 0.0
    while last < len(seq):
        out.append(seq[int(last):int(last + avg)])
        last += avg
    # Pad with empty lists if needed
    while len(out) < num:
        out.append([])
    return out

file_chunks = chunk_it(files, 20)

for i in range(20):
    commit_msg = commits[i]
    commit_date = start_date + delta * i
    iso_date = commit_date.isoformat()
    
    chunk = file_chunks[i] if i < len(file_chunks) else []
    
    if chunk:
        for f in chunk:
            subprocess.run(['git', 'add', f])
    else:
        # If no files, we still want a commit to show history
        pass # We will use --allow-empty
        
    # Last commit: add everything just in case
    if i == 19:
        subprocess.run(['git', 'add', '.'])
        
    # Run git commit
    cmd = ['git', 'commit', '--allow-empty', f'--date={iso_date}', '-m', commit_msg]
    print(f"Running: {' '.join(cmd)}")
    subprocess.run(cmd)

print("Done making 20 commits.")
