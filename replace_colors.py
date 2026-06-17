import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets'
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace hardcoded backgrounds
    content = content.replace('const Color(0xFF141414)', 'Theme.of(context).scaffoldBackgroundColor')
    content = content.replace('Color(0xFF141414)', 'Theme.of(context).scaffoldBackgroundColor')
    
    # Replace hardcoded primary color
    content = content.replace('const Color(0xFFE50914)', 'Theme.of(context).primaryColor')
    content = content.replace('Color(0xFFE50914)', 'Theme.of(context).primaryColor')
    
    # For text colors, it's a bit tricky because some are white in both themes (e.g., if we kept images dark) 
    # but the user asked for a light theme, so text needs to be adaptive.
    # Let's replace Colors.white with adaptive text color, except in specific places if needed.
    # A simple approach: use Theme.of(context).textTheme.bodyLarge?.color or just theme it properly.
    # Actually, a better approach is to use `Theme.of(context).colorScheme.onBackground`
    
    content = re.sub(r'Colors\.white(\.withOpacity\([^)]+\))?', lambda m: f'(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white){m.group(1) or ""}', content)
    content = re.sub(r'Colors\.white([0-9]{2})', lambda m: f'(Theme.of(context).textTheme.bodyLarge?.color?.withOpacity({int(m.group(1))/100}) ?? Colors.white{m.group(1)})', content)
    
    content = re.sub(r'Colors\.black(\.withOpacity\([^)]+\))?', lambda m: f'(Theme.of(context).colorScheme.background == Colors.white ? Colors.black : Colors.black){m.group(1) or ""}', content) # Keep black as black mostly for shadows, or adapt it? Let's leave black as is for shadows, but for backgrounds:
    
    # Wait, Colors.black used as background should be `Theme.of(context).scaffoldBackgroundColor`
    content = content.replace('color: Colors.black,', 'color: Theme.of(context).scaffoldBackgroundColor,')
    content = content.replace('backgroundColor: Colors.black', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor')
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for d in directories:
    if os.path.exists(d):
        for f in os.listdir(d):
            if f.endswith('.dart'):
                process_file(os.path.join(d, f))

print("Done")
