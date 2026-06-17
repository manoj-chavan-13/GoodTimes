import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets'
]

for d in directories:
    if os.path.exists(d):
        for f in os.listdir(d):
            if f.endswith('.dart'):
                filepath = os.path.join(d, f)
                with open(filepath, 'r', encoding='utf-8') as f_in:
                    content = f_in.read()
                
                new_content = content
                # Remove const before TextStyle if the same line has Theme.of
                lines = new_content.split('\n')
                for i in range(len(lines)):
                    if 'Theme.of' in lines[i] and 'const TextStyle' in lines[i]:
                        lines[i] = lines[i].replace('const TextStyle', 'TextStyle')
                new_content = '\n'.join(lines)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f_out:
                        f_out.write(new_content)
                    print(f"Removed const TextStyle in {filepath}")

print("Done")
