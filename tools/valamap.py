#!/usr/bin/python

# go to a dir with vala code and do:
# valamap.py ./ | dot -Tsvg -o /tmp/valamap.svg && firefox /tmp/valamap.svg

import sys
import os
import re
from lxml import etree



class ValaMap ():

	def __init__ (self, dir):

		self.dir = os.path.abspath (dir) + "/"
		self.classfiledict = {}
		self.sclasscolordict = {}
		self.root = etree.Element ("valamap")
		self.root.set ("path", self.dir)


	
	def parse_classes (self):

		files = os.listdir (self.dir)
		for file in files:
			if (file.split (".")[-1] == "vala"):
				self.find_classes_in_file (file)



	def parse_references (self):

		for child in self.root:
			name = child.get ("name")
			for cname in self.classfiledict:
				if cname != name:
					refs = self.get_references (self.classfiledict[cname], name)
					if len (refs) >= 1:
						node = etree.SubElement (child, "reference")
						node.set ("class", cname)
						for ref in refs:
							subnode = etree.SubElement (node, "line")
							subnode.set ("num", str (ref))



	def print_xml (self):
	
		print (etree.tostring (self.root, pretty_print=True))
	
	
	
	def print_dot (self):
	
		dot_style = ""
		dot_nodes = ""
		dot_colors = ""
		
		# colors / superclasses
		numcols = len (self.sclasscolordict)
		lol = 1
		dot_colors += 'colors [label=<'
		dot_colors += '<table border="1" cellpadding="6" cellborder="0" cellspacing="0">'
		for sclass, color in self.sclasscolordict.iteritems():
			huestep = 1.0 / numcols
			h = huestep*lol
			col = self.sclasscolordict[sclass] = str (h) + ' 0.2 0.9'
			dot_colors += '<tr><td align="left" bgcolor="' + col + '">'
			dot_colors += ' ' + sclass.strip () + ' </td></tr>'
			lol += 1
		dot_colors += "</table>>,shape=box,color=white,fontcolor=white,fontsize=16,fontname=sans,labelloc=b,labeljust=l];\n"
		
		# styles & co
		for child in self.root:
			dot_style += '"' + child.get ("name") + '" '
			dot_style += "["
			
			file = child.get ("file")
			lnum = child.get ("line")
			dot_style += 'href="' + self.dir + file + '",'
			dot_style += 'tooltip="' + file + ' @ ' + lnum + '",'
			
			supercolor = self.sclasscolordict[child.get ("super")]
			dot_style += 'fillcolor="' + supercolor + '",'
			
			if child.get ("main") == "True":
				dot_style += 'style="filled",shape=folder'
			elif child.get ("type") == "public":
				dot_style += 'style="filled",shape=box'
			else:
				dot_style += 'style="filled,rounded",shape=box'
			
			dot_style += "];\n"

		# nodes
		for child in self.root:
			name = '"' + child.get ("name") + '"'
			if len (child) < 1:
				dot_nodes += name + " "
			else:
				for subchild in child:
					dot_nodes += name + '->"' + subchild.get ("class") + '" '
			dot_nodes += ";\n"

		node_list = dot_nodes.split ("\n")
		node_list.sort (cmp=self.bylength)
		dot_nodes = "\n".join (node_list)

		print "digraph G {\n"
		print 'size="6.0,6.0";'
		print 'edge [arrowhead=normal];'
		print "node [fontsize=16,fontname=sans];"
		print dot_colors
#		print 'subgraph cluster_main {'
		print dot_nodes
		print dot_style
#		print "}"
		print "}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



	def bylength (self, str1, str2):
		return len (str2) - len (str1)



	def get_references (self, file, classname):
		f = open (self.dir + file, 'r')
		#refname = "new " + classname
		#refname2 = " " + classname + " "
		refname = classname
		output = []
		linenum = 0
		for line in f:
			linenum += 1
			line.strip ()
			if line.startswith ("//"):
				continue
			if line.find (refname) > -1:
				output.append (linenum)
#			if line.find (refname2) > -1:
#				output.append (linenum)
		return output



	def find_classes_in_file (self, file):
		found = False
		main = False
		foundline = ""
		foundlinenum = 0
		linenum = 0
	
		f = open (self.dir + file, 'r')

		for line in f:
			linenum += 1
			line.strip ()

			if line.startswith ("//"):
				continue

			if line.find (" class ") > -1:
				foundline = line
				foundlinenum = linenum
				found = True

			if line.find ("public static int main") > -1:
				main = True
	
		if found == True:
			self.class_to_xml (foundline, file, foundlinenum, main)
		


	def class_to_xml (self, line, file, linenum, main):
		exp = "^(\w+)\s+class\s+(\w+\.)?([\w\<\>]+)(\s*:\s*)?([\w\.]+)?(\s*,\s*)?(\w+)?"
		res = re.search (exp, line)
		if (res):
			# lets ignore <?> in classname<?> for now
			classname = res.group (3).split ("<")[0]

			node = etree.SubElement (self.root, "class")
			node.set ("name", classname)
			#node.set ("space", res.group (2).rstrip(".") or "")
			node.set ("space", res.group (2) or "")
			node.set ("type", res.group (1))
			super = res.group (5) or ""
			node.set ("super", super)
			node.set ("interface", res.group (7) or "")
			node.set ("file", file)
			node.set ("line", str (linenum))
			node.set ("main", str (main))
			self.classfiledict[classname] = file
			self.sclasscolordict[super] = ""

################################################################################

if __name__ == "__main__":

	if len (sys.argv) <= 1:
		print "Usage: " + sys.argv[0] + " <source dir>"
		exit (1)

	valamap = ValaMap (sys.argv[1])
	valamap.parse_classes ()
	valamap.parse_references ()
	#valamap.print_xml ()
	valamap.print_dot ()

