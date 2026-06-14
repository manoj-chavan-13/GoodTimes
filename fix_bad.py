import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets'
]

def fix_bad_replacements(content):
    # (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)54
    # -> (Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54) ?? Colors.white54)
    def replacer(m):
        opacity = m.group(1)
        val = int(opacity) / 100.0
        return f"?.withOpacity({val}) ?? Colors.white{opacity})"
        
    content = re.sub(r'\?\s*\?\s*Colors\.white\)([0-9]{2})', replacer, content)
    
    # Also fix extra positional arguments in settings screen
    content = re.sub(r'const SnackBar\(\s*content:\s*Text\([^\)]+\),\s*backgroundColor:\s*Colors\.[^\)]+\)', lambda m: m.group(0).replace('const SnackBar', 'SnackBar'), content)
    
    return content

for d in directories:
    if os.path.exists(d):
        for f in os.listdir(d):
            if f.endswith('.dart'):
                filepath = os.path.join(d, f)
                with open(filepath, 'r', encoding='utf-8') as f_in:
                    content = f_in.read()
                
                new_content = fix_bad_replacements(content)
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f_out:
                        f_out.write(new_content)
                    print(f"Fixed bad replacements in {filepath}")

print("Done")
