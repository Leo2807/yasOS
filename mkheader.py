#!/bin/env python3

import sys
import re

opening_bracket = re.compile(r'\s*{')
function_desc = re.compile(r'\S.+ .+\(.*\)$')
include_directive = re.compile(r'#include "(.*)"')
no_header = re.compile(r'/\* .*(?:n\'t)|(?:not?).*header.* \*/', re.IGNORECASE)
header = re.compile(r'/\* .*header.* \*/', re.IGNORECASE)
end = re.compile(r'/\* .*end.* \*/', re.IGNORECASE)

functions = []
includes = []
forced_data = ""

with open(sys.argv[1], 'r') as f:
	print("Opened input file: {}\n".format(sys.argv[1]))
	print("Defenitions found:\n")

	no_header_block = False
	header_block = False
	
	previous_line = ""
	
	for line in f:
		
		imatch = include_directive.match(line)
		
		# End of special block
		if end.match(line):
			header_block = False
			no_header_block = False
			print("--- End of block ---")
			continue
			
			# ignore things inside a no header block
		if no_header_block:
			print(line)
			continue
			
			# forced inclusion
		elif header_block:
			forced_data += line
			print(line)
			
			# function definition
		elif opening_bracket.match(line) and function_desc.match(previous_line):
			func_def = previous_line.rstrip("\n")
			print(func_def)
			functions.append(func_def)
			
			# include directive
		elif imatch:
			includes.append(imatch.group(1))
			
			# not in header block
		elif no_header.match(line):
			no_header_block = True
			print("Found no header block:")
			
			# force include block
		elif header.match(line):
			header_block = True
			print("Found header block:")
		
		previous_line = line

with open(sys.argv[2], 'a') as f:
	print("\nWriting to file")
	
	f.write("/* Automatic generated header for {} */\n".format(sys.argv[1]))
	f.write("\n")
	
	header_define = re.sub(r'[/.-]', '_', sys.argv[2].upper())
	f.write("""\
#ifndef __{h}
#define __{h}
""".format(h=header_define))
	
	if forced_data != "":
		f.write("\n")
		f.write(forced_data)
	
	f.write("\n/* Includes */\n")
	for include in includes:
		f.write("#include \"{}\"\n".format(include))
	
	f.write("\n/* Functions */\n")
	for function in functions:
		f.write("extern " + function + ";\n")
	
	f.write("\n#endif\n")
