import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets',
]

# Step 1: Revert all broken Theme.of expressions back to original hardcoded colors
patterns = [
    # Revert text colors with opacity
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.7\)\s*\?\?\s*Colors\.white70\)', 'Colors.white70'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.7\)\s*\?\?\s*Colors\.white70', 'Colors.white70'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.54\)\s*\?\?\s*Colors\.white54\)', 'Colors.white54'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.54\)\s*\?\?\s*Colors\.white54', 'Colors.white54'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.38\)\s*\?\?\s*Colors\.white38\)', 'Colors.white38'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.38\)\s*\?\?\s*Colors\.white38', 'Colors.white38'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.24\)\s*\?\?\s*Colors\.white24\)', 'Colors.white24'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.24\)\s*\?\?\s*Colors\.white24', 'Colors.white24'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.1\)\s*\?\?\s*Colors\.white10\)', 'Colors.white10'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.1\)\s*\?\?\s*Colors\.white10', 'Colors.white10'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.08\)\s*\?\?\s*Colors\.white\)', 'Colors.white.withOpacity(0.08)'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\?\.withOpacity\(0\.08\)\s*\?\?\s*Colors\.white', 'Colors.white.withOpacity(0.08)'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.05\)\s*\?\?\s*Colors\.white\)', 'Colors.white.withOpacity(0.05)'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.02\)\s*\?\?\s*Colors\.white\)', 'Colors.white.withOpacity(0.02)'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\(0\.2\)\s*\?\?\s*Colors\.white\)', 'Colors.white.withOpacity(0.2)'),
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\.withOpacity\([0-9.]+\)\s*\?\?\s*Colors\.white[0-9]*\)', lambda m: 'Colors.white.withOpacity(' + re.search(r'withOpacity\(([0-9.]+)\)', m.group(0)).group(1) + ')'),
    # Revert plain text color (no opacity)
    (r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\?\s*Colors\.white\)', 'Colors.white'),
    (r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\?\?\s*Colors\.white', 'Colors.white'),
    # Revert black comparison patterns
    (r'\(Theme\.of\(context\)\.colorScheme\.background\s*==\s*Colors\.white\s*\?\s*Colors\.black\s*:\s*Colors\.black\)', 'Colors.black'),
    # Revert scaffold background that replaced Color(0xFF141414)  
    # Only in sidebar/card specific places, not scaffold itself
]

for d in directories:
    if os.path.exists(d):
        for f in os.listdir(d):
            if f.endswith('.dart'):
                filepath = os.path.join(d, f)
                with open(filepath, 'r', encoding='utf-8') as fin:
                    content = fin.read()
                original = content
                for pat, repl in patterns:
                    content = re.sub(pat, repl, content)
                if content != original:
                    with open(filepath, 'w', encoding='utf-8') as fout:
                        fout.write(content)
                    print(f"Reverted: {filepath}")

print("Done reverting.")
