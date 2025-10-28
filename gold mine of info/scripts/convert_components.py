#!/usr/bin/env python3
"""
Component Converter - Converts .rbxmx files to Luau code
Allows you to reuse your GUI components as Luau modules
"""

import os
import xml.etree.ElementTree as ET
import re

def convert_rbxmx_to_luau(rbxmx_path, output_path):
    """Convert a .rbxmx file to Luau code"""
    
    print(f"Converting {rbxmx_path} to {output_path}")
    
    # Parse the XML file
    tree = ET.parse(rbxmx_path)
    root = tree.getroot()
    
    # Generate Luau code
    luau_code = generate_luau_code(root, os.path.basename(rbxmx_path))
    
    # Write to output file
    with open(output_path, 'w') as f:
        f.write(luau_code)
    
    print(f"✅ Converted {rbxmx_path} to {output_path}")

def generate_luau_code(root, filename):
    """Generate Luau code from XML root"""
    
    component_name = filename.replace('.rbxmx', '').replace('.rbxm', '')
    class_name = component_name.title().replace('_', '')
    
    luau_code = f"""--[[
    {class_name} - Generated from {filename}
    Reusable GUI component for Animal Crossing game
]]

local TweenService = game:GetService("TweenService")

local {class_name} = {{}}
{class_name}.__index = {class_name}

function {class_name}.new(parent)
    local self = setmetatable({{}}, {class_name})
    self._parent = parent
    self._gui = nil
    
    self:_createGUI()
    
    return self
end

function {class_name}:_createGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "{class_name}GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self._parent
    
    -- TODO: Add your GUI elements here
    -- This is a placeholder - you'll need to manually convert the XML elements
    
    self._gui = screenGui
    print("[{class_name}] GUI created")
end

function {class_name}:Show()
    if self._gui then
        self._gui.Enabled = true
        print("[{class_name}] Shown")
    end
end

function {class_name}:Hide()
    if self._gui then
        self._gui.Enabled = false
        print("[{class_name}] Hidden")
    end
end

function {class_name}:Destroy()
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
        print("[{class_name}] Destroyed")
    end
end

return {class_name}
"""
    
    return luau_code

def main():
    """Main conversion function"""
    
    # Define input and output paths
    input_files = [
        "hi.rbxmx",
        "test.rbxm"
    ]
    
    output_dir = "src/shared/Components/Generated"
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Convert each file
    for input_file in input_files:
        if os.path.exists(input_file):
            output_file = os.path.join(output_dir, f"{input_file.replace('.rbxmx', '').replace('.rbxm', '')}.luau")
            convert_rbxmx_to_luau(input_file, output_file)
        else:
            print(f"⚠️  File not found: {input_file}")
    
    print("\n🎉 Component conversion complete!")
    print("Generated components are in src/shared/Components/Generated/")

if __name__ == "__main__":
    main()
