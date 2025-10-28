import os
import re

def remove_type_annotations(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove type annotations in function definitions
    # Example: function name(param: Type) -> function name(param)
    content = re.sub(r'function ([^(]+)\(([^)]*?):\s*[^,)]+([,)])', r'function \1(\2\3', content)
    content = re.sub(r'([,\(]\s*)([a-zA-Z0-9_]+)\s*:\s*[a-zA-Z0-9_.]+(\s*[,\)])', r'\1\2\3', content)
    
    # Remove type casting with ::
    # Example: local x = y :: Type -> local x = y
    content = re.sub(r'(=\s*[^:;]+)\s*::\s*[a-zA-Z0-9_\[\]{}?|.]+', r'\1', content)
    
    # Remove type annotations in variable declarations
    # Example: local x: number = 5 -> local x = 5
    content = re.sub(r'local\s+([a-zA-Z0-9_]+)\s*:\s*[a-zA-Z0-9_\[\]{}?|.]+(\s*=)', r'local \1\2', content)
    
    # Remove function return type annotations
    # Example: function x(): number -> function x()
    content = re.sub(r'function ([^(]+\([^)]*\)):\s*[a-zA-Z0-9_\[\]{}?|.]+', r'function \1', content)
    
    # Remove type and export type declarations
    # Example: type X = ... or export type X = ...
    content = re.sub(r'(local\s+)?type\s+[^=]+=\s*[^;]+;?', '', content)
    content = re.sub(r'export\s+type\s+[^=]+=\s*[^;]+;?', '', content)
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed type annotations in {file_path}")

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.luau'):
                fix_file = os.path.join(root, file)
                remove_type_annotations(fix_file)

# Process the source code directory
process_directory('./src')
print("Done fixing type annotations")
