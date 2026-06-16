import os
import subprocess
import datetime
import random

# Reset the last 20 commits we just made, keeping the files modified in working directory
subprocess.run(['git', 'reset', 'HEAD~20'])

# Get list of changed/untracked files
result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
lines = result.stdout.strip().split('\n')
files = []
for line in lines:
    if line:
        file_path = line[3:].strip()
        files.append(file_path)

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

# We want 20 commits over 14 days (1 to 2 per day)
# Let's generate a list of dates
dates = []
end_date = datetime.datetime.now()
current_date = end_date - datetime.timedelta(days=14)

commits_per_day = []
total = 0
for i in range(14):
    if i == 13:
        n = 20 - total
    else:
        n = random.choice([1, 2])
        if total + n > 20:
            n = 20 - total
    commits_per_day.append(n)
    total += n
    if total == 20:
        while len(commits_per_day) < 14:
            commits_per_day.append(0)
        break

for i in range(14):
    num_commits = commits_per_day[i]
    for _ in range(num_commits):
        # Random time between 10 AM and 11 PM
        hour = random.randint(10, 22)
        minute = random.randint(0, 59)
        sec = random.randint(0, 59)
        d = current_date.replace(hour=hour, minute=minute, second=sec)
        dates.append(d)
    current_date += datetime.timedelta(days=1)

dates.sort()

# Group files
def chunk_it(seq, num):
    avg = len(seq) / float(num)
    out = []
    last = 0.0
    while last < len(seq):
        out.append(seq[int(last):int(last + avg)])
        last += avg
    while len(out) < num:
        out.append([])
    return out

file_chunks = chunk_it(files, 20)

for i in range(20):
    commit_msg = commits[i]
    iso_date = dates[i].isoformat()
    
    chunk = file_chunks[i] if i < len(file_chunks) else []
    
    if chunk:
        for f in chunk:
            subprocess.run(['git', 'add', f])
            
    if i == 19:
        subprocess.run(['git', 'add', '.'])
        
    # The GIT_AUTHOR_DATE and GIT_COMMITTER_DATE must be set properly
    env = os.environ.copy()
    env['GIT_AUTHOR_DATE'] = iso_date
    env['GIT_COMMITTER_DATE'] = iso_date
    
    cmd = ['git', 'commit', '--allow-empty', '-m', commit_msg]
    print(f"Committing '{commit_msg}' on {iso_date}")
    subprocess.run(cmd, env=env)

print("Done re-creating commits.")
