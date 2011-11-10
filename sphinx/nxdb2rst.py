#!/usr/bin/env python

########### SVN repository information ###################
# $Date: 2011-11-10 00:33:02 -0600 (Thu, 10 Nov 2011) $
# $Author: Pete Jemian $
# $Revision: 1009 $
# $URL: https://svn.nexusformat.org/definitions/trunk/sphinx/runner.py $
# $Id: runner.py 1009 2011-11-10 06:33:02Z Pete Jemian $
########### SVN repository information ###################

'''
Overrides certain handler routines for
translating DocBook elements into restructured 
text (reST) documents.
'''


import os
import db2rst
import lxml.etree as ET
import logging

NEXUS_DIR = "../manual"
NEXUS_DIR = os.path.abspath(NEXUS_DIR)


'''
WARNING:root:Don't know how to handle these DocBook elements: 
+  primary
+  subtitle
+  info
+  pubdate
+  org
+  uri
+  copyright
+  year
+  holder
+  legalnotice
'''


class NeXus_Convert(db2rst.Convert):
    '''
    NeXus overrides of the db2rst standard Convert class
    '''

    def e_table(self, el):
        s = "\n\n"
        id = el.get(self.parent.id_attrib, "")
        if len(id) > 0:
            s += ".. _%s:\n\n" % id
        
        s += ".. rubric:: Table: "
        title = self.childNodeText(el, 'title')
        if title is not None:
            s += title
        s += "\n\n"
        
        # get number of columns
        tgroup_node = el.find(self.parent.ns+'tgroup')
        cols = int(tgroup_node.attrib['cols'])
        widths = [ 0 ] * cols
        
        # calculate the widths of all the columns
        row_nodes = ET.ETXPath( './/%srow' % self.parent.ns )(el)

        for rowNum in range(len(row_nodes)):
            r = row_nodes[rowNum]
            col_nodes = r.findall(self.parent.ns+'entry')
            for colNum in range(len(col_nodes)):
                c = col_nodes[colNum]
                text = self._conv(c, do_assert = False)
                for line in text.split("\n"):
                    widths[colNum] = max( len(line), widths[colNum] )
        
        # write the tableText into s
        fmt = ' '.join(['%%-%is' % (size,) for size in widths]) + '\n'
        divider = fmt % tuple(['=' * size for size in widths])
        
        s += divider   # top row of table
        
        # TODO: consider trapping any directives for colspan or rowspan

        thead = tgroup_node.find(self.parent.ns+'thead')
        if thead is None:
            # fake the column labels
            s += fmt % tuple(['..' for _ in range(cols)])
        else:
            # actual column labels
            rows = thead.findall(self.parent.ns+'row')
            s += self._table_row(rows, divider, fmt, cols)

        s += divider   # label-end row of table

        tbody = tgroup_node.find(self.parent.ns+'tbody')
        rows = tbody.findall(self.parent.ns+'row')
        s += self._table_row(rows, divider, fmt, cols)
        
        s += divider   # bottom row of table
        
        return s
    
    def _get_entry_text_list(self, parent_node):
        '''
        '''
        nodes = parent_node.findall(self.parent.ns+'entry')
        rowText = [self._conv(item).split("\n") for item in nodes]
        return rowText
    
    def _table_row(self, rows, divider, fmt, cols):
        '''
        '''
        s = ''
        for row in rows:
            rowText = self._get_entry_text_list( row )
            # any <entry> might have one or more "\n"
            # we should line them up right
            numLines = map(len, rowText)
            maxNumLines = max( numLines )
            for lineNum in range( maxNumLines ):
                lineText = []
                for colNum in range(cols):
                    text = rowText[colNum]
                    if lineNum < len(text):
                        lineText.append(text[lineNum])
                    else:
                        lineText.append("")
                s += fmt % tuple(lineText)
        return s
    
    def e_example(self, el):
        '''
        Must parse an example specification such as::
        
            <example 
                    xmlns="http://docbook.org/ns/docbook" 
                    xmlns:xlink="http://www.w3.org/1999/xlink" 
                    xmlns:xi="http://www.w3.org/2001/XInclude" 
                    xml:id="native.hdf5.simple.write" 
                    xreflabel="Writing a simple NeXus file using native HDF5 commands">
                <title>Writing a simple NeXus file using native HDF5 commands</title>
                <programlisting linenumbering="numbered" language="c"
                    ><xi:include href="examples/nxh5write.c" parse="text"
                        /></programlisting>
            </example>

        into reST commands such as::
        
            .. code-block:: c        [ text | xml | python | c | ... ]
                :linenos: 
                
                [copy examples/napi-example.c file contents here]

        or::
        
            .. literalinclude:: napi-example.c  [ copy this file into same folder as .rst ]
                :linenos: 
                :tab-width: 4
        
        '''
        s = self.program_listing(el)
        # see ClassDefinitions.xml, line 143 for another representation
        if s is None:
            logging.info("line %d in %s" % (el.sourceline, str(el.base)))
            logging.info( "no <programlisting /> element" )
            s = self._docbook_source(el, 'EXAMPLE')  # unparsed representation
        return s
    
    def e_informalexample(self, el):
        s = self.program_listing(el)
        if s is None:
            logging.info("line %d in %s" % (el.sourceline, str(el.base)))
            logging.info( "no <programlisting /> element" )
            s = self._docbook_source(el, 'INFORMALEXAMPLE')  # unparsed representation
        return s
    
    def program_listing(self, el):
        '''
        could be in a figure or example
        '''
        child = self.parent.ns+"programlisting"
        pl_obj = el.find(child) 
        if pl_obj is None:
            grandchild = self.parent.ns+"programlistingco" + "/" + child
            pl_obj = el.find(grandchild)
            if pl_obj is None:
                return None
        logging.info("program_listing(): line %d in %s" % (el.sourceline, str(el.base)))
        #print el.sourceline, str(el.base)
        # read the XML
        id = el.get(self.parent.id_attrib, None)
        title_obj = el.find(self.parent.ns+"title")
        if title_obj is not None:
            title = self._concat( title_obj ).strip()
            # TODO Where is title used?
        xreflabel = el.get("xreflabel", None)
        language = pl_obj.get("language", "text")
        #
        # build the reST
        indent = " "*4
        s = ""
        if id:
            s += "\n.._%s:\n" % id
        s += "\n.. code-block:: %s\n" % language
        s += indent + ":linenos:\n\n" 
        xi = "{http://www.w3.org/2001/XInclude}"
        inc_obj = pl_obj.find(xi + "include")
        if inc_obj is not None:
            filename = inc_obj.get("href", None)
            full_filename = os.path.join( NEXUS_DIR, filename )
            if os.path.exists(full_filename):
                # copy the include file into the reST
                file = open(full_filename, 'r')
                for line in file:
                    s += indent + line.rstrip() + "\n"
        else:
            for line in pl_obj.text.split("\n"):
                s += indent + line.rstrip() + "\n"
        return s
    
    def e_figure(self, el):
        '''
        standard figure
        '''
        logging.info("line %d in %s" % (el.sourceline, str(el.base)))
        s = self.program_listing(el)
        if s is not None:
            return s
        s = self.mediaobject(el)
        if s is not None:
            return s
        s = self._docbook_source(el, 'FIGURE')  # unparsed representation
        return s
    
    def mediaobject(self, el):
        '''
        Docbook mediaobject (has a caption)::

            <figure 
                    xml:id="fig.example.NeXus.hierarchy" 
                    xreflabel="Example NeXus file hierarchy">
                <title>Example of a NeXus file</title>
                <mediaobject>
                    <imageobject>
                        <imagedata fileref="img/Hierarchy.png" width="300pt"
                            scalefit="1"/>
                    </imageobject>
                </mediaobject>
            </figure> 

        will be written as::
        
            .. _fig.example.NeXus.hierarchy:
            
            .. figure:: img/Hierarchy.png
                :width: 300 pt
                :alt: figure of Example NeXus file hierarchy
            
                Example of a NeXus file
        '''
        s = ""
        mo = el.find(self.parent.ns+"mediaobject")
        if mo is None:
            return None
        id = el.get(self.parent.id_attrib, None)
        title = self._concat( el.find(self.parent.ns+"title") ).strip()
        xreflabel = el.get("xreflabel", None)
        img_data_objs = ET.ETXPath( './/%simagedata' % self.parent.ns )(el)
        if len(img_data_objs) < 1:
            raise RuntimeWarning, "no <imagedata /> element found"
        if len(img_data_objs) > 1:
            raise RuntimeWarning, "multiple <imagedata /> elements found"
        s = ""
        obj = img_data_objs[0]
        file = obj.get("fileref", "")
        width = obj.get("width", None)
        indent = " "*4
        if id:
            s += "\n.._%s:\n\n" % id
        s += ".. figure:: %s\n" % file
        if width:
            s += indent + ":width: %s\n" % width
        if xreflabel:
            s += indent + ":alt: figure of %s\n" % xreflabel
        if title:
            s += "\n"*2 + indent + "%s\n" % title
        return s
    
    def e_subtitle(self, el):
        '''
        figure with a caption::
        
            .. _fig.data-pre-nexus:
            
            .. figure:: data-pre-nexus.jpg
                :width: 200 pt
                :alt: example NeXus data file hierarchy
            
                *N* separate file formats
        '''
        t = self._concat(el).strip()
        return "\n\n" + t + "\n" + "@" * len(t)

    e_info = db2rst.Convert._block_separated_with_blank_line
