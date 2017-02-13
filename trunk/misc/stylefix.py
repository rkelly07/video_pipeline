#!/usr/bin/python

import sys, os, time

# fix operator formatting
def fix_operators(line):

	# ignore empty lines
	if line.strip() == '':
		return line

	s = line

	# tokenize conflicting operators
	s = s.replace('==','__EQ__')
	s = s.replace('~=','__NE__')
	s = s.replace('<=','__LE__')
	s = s.replace('>=','__GE__')

	# fix operator spacing
	t = '='
	s = s.replace(t,(' '+t+' '))
	while (t+'  ') in s:
		s = s.replace((t+'  '),(t+' '))
	while ('  '+t) in s:
		s = s.replace(('  '+t),(' '+t))
	
	# replace tokens
	s = s.replace('__EQ__','==')
	s = s.replace('__NE__','~=')
	s = s.replace('__LE__','<=')
	s = s.replace('__GE__','>=')
	
	return s

# fix comment formatting
def fix_comments(line):

	# ignore empty lines
	if line.strip() == '':
		return line

	s = line

	if s.lstrip()[0] == '%' and s.lstrip()[1] != '%':
		x = s.lstrip()[1:]
		i = len(s)-len(x)-1
		j = len(x)-len(x.lstrip())
		s = (' '*i)+(' '*(j-1))+'%'+' '+x[j:]
		
	return s

# main
if __name__ == "__main__":

	input_filepath = os.path.realpath(sys.argv[1])
	input_file = open(input_filepath,'r')

	output_filepath = os.path.dirname(input_filepath) + '/output.txt'
	output_file = open(output_filepath,'w')
	
	for num,line in enumerate(input_file,1):
		s = line
		s = fix_operators(s)
		s = fix_comments(s)
		fixed_line = s
		if fixed_line != line:
			print 'Line ',num,':'
			print '>>',line.rstrip()
			print '=>',fixed_line.rstrip()
		output_file.write(fixed_line)

	input_file.close()

	print 'Done!'

	output_file.write(os.linesep)
	output_file.write('% ' + ('-'*48)+os.linesep)
	output_file.write('% ' + 'reformatted with stylefix.py on ')
        output_file.write(time.strftime('%Y/%m/%d %H:%M') + os.linesep)
	output_file.close()

	os.rename(input_filepath,input_filepath)
	os.rename(output_filepath,input_filepath)

