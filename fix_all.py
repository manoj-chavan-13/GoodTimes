import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets',
]

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # FIX 1: "Colors.black)87" -> "Colors.black87"  (and other opacity suffixes)
    # Pattern: (... == Colors.white ? Colors.black : Colors.black)NN -> Colors.blackNN
    content = re.sub(
        r'\(Theme\.of\(context\)\.colorScheme\.background == Colors\.white \? Colors\.black : Colors\.black\)([0-9]+)',
        r'Colors.black\1',
        content
    )

    # FIX 2: "Colors.white)NN" -> "Colors.whiteNN" (leftover from replace_colors.py)
    content = re.sub(
        r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color \?\? Colors\.white\)([0-9]+)',
        r'Colors.white\1',
        content
    )

    # FIX 3: Remove const from any widget lines that contain Theme.of()
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'Theme.of' in line:
            # Remove leading 'const ' before common widget constructors
            lines[i] = re.sub(
                r'\bconst\s+(Center|Column|Row|Container|SizedBox|Icon|Text|BoxDecoration|CircularProgressIndicator|Padding|Positioned|Material|Divider|ElevatedButton|SnackBar|AlertDialog|ListTile)\b',
                r'\1',
                lines[i]
            )
            # Also remove the 'const' if it's a standalone const before {
            lines[i] = re.sub(r'\bconst\s+TextStyle\b', 'TextStyle', lines[i])
    content = '\n'.join(lines)

    # FIX 4: const BoxDecoration( containing Theme.of - remove const
    # This is tricky multiline - handle single-line const BoxDecoration with Theme.of
    content = re.sub(
        r'const\s+BoxDecoration\(([^)]*Theme\.of[^)]*)\)',
        r'BoxDecoration(\1)',
        content
    )

    # FIX 5: Clean up redundant (Theme.of(context).colorScheme.background == Colors.white ? Colors.black : Colors.black)
    # Replace those with Colors.black (they're always black)
    content = re.sub(
        r'\(Theme\.of\(context\)\.colorScheme\.background == Colors\.white \? Colors\.black : Colors\.black\)',
        'Colors.black',
        content
    )

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")

for d in directories:
    if os.path.exists(d):
        for fname in os.listdir(d):
            if fname.endswith('.dart'):
                fix_file(os.path.join(d, fname))

print("All done.")
