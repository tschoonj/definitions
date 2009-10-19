<?xml version="1.0" encoding="UTF-8"?>

<!--
    ########### SVN repository information ###################
    # $Date$
    # $Author$
    # $Revision$
    # $HeadURL$
    # $Id$
    ########### SVN repository information ###################
    
    Purpose:
    This stylesheet is used to translate the NeXus Definition Language
    specifications into Schematron Schema (.sch) files for use in
    validating candidate NeXus data files.
    
    Usage (for example NXsource class):
    xsltproc nxdl2sch.xsl NXsource.nxdl.xml > NXsource.sch
-->

<xsl:stylesheet
    version="1.0"
    xmlns:nxdl="http://definition.nexusformat.org/nxdl/3.1"
    xmlns:nxsd="http://definition.nexusformat.org/schema/3.1"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <xsl:output method="xml" indent="yes" version="1.0" encoding="UTF-8"/>
    
    <xsl:template match="/">
        <xsl:element name="sch:schema">
            <xsl:attribute name="queryBinding">xslt2</xsl:attribute>
            <xsl:element name="sch:ns">
                <xsl:attribute name="uri">http://definition.nexusformat.org/schema/3.1</xsl:attribute>
                <xsl:attribute name="prefix">nx</xsl:attribute>
            </xsl:element>
            <xsl:element name="sch:ns">
                <xsl:attribute name="uri">http://www.w3.org/2001/XMLSchema-instance</xsl:attribute>
                <xsl:attribute name="prefix">xsi</xsl:attribute>
            </xsl:element>
            <xsl:apply-templates select="*"/>
            </xsl:element>
    </xsl:template>
    
    <xsl:template match="nxdl:definition">
        <xsl:variable name="mycontext">
            <xsl:choose>
                <xsl:when test="@restricts">nx:<xsl:value-of select="@restricts"/>[@xsi:type='<xsl:value-of select="@name"/>']</xsl:when>
                <xsl:otherwise>nx:<xsl:value-of select="@name"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="sch:pattern">
                <xsl:attribute name="fpi">
                    <xsl:value-of select="name()"/>: <xsl:value-of select="@name"
                    /> fields</xsl:attribute>
                <xsl:element name="sch:rule">
                        
                    <xsl:attribute name="context">//<xsl:value-of 
                        select="$mycontext"/>/*[count(child::*) = 0]</xsl:attribute>
                    <xsl:element name="sch:let">
                        <xsl:attribute name="name">fields</xsl:attribute>
                        <xsl:attribute name="value">(<xsl:for-each 
                            select="nxdl:field"><xsl:if 
                                test="position()>1">,</xsl:if>'<xsl:value-of 
                                    select="@name"/>'</xsl:for-each>)</xsl:attribute>
                    </xsl:element>
                    <xsl:if test="not(@restricts)">
                      <xsl:element name="sch:report">
                        <xsl:attribute name="test">count(index-of($fields,name()))=0</xsl:attribute>                        
                        Non-standard field <sch:value-of select="name()"/> in <sch:value-of select="name(..)"/> 
                      </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:element>
            <xsl:element name="sch:pattern">
                <xsl:attribute name="fpi">
                    <xsl:value-of select="name()"/>: <xsl:value-of select="@name"
                    /> groups</xsl:attribute>
                <xsl:element name="sch:rule">
                    <!-- Groups always have child nodes.  Easy to find them. -->
                    <xsl:attribute name="context">//<xsl:value-of 
                        select="$mycontext"/>/*[count(child::*) > 0]</xsl:attribute>
                    <!--
                        The test for groups is a bit more complicated.  Example:
                        In NXDL, name() = 'group', @type='NXsource', @name="second" (and is optional)
                        Build a list of NXsource/* or NXsource/second
                    -->
                    <xsl:element name="sch:let">
                        <xsl:attribute name="name">group_types</xsl:attribute>
                        <xsl:attribute name="value">(<xsl:for-each 
                            select="nxdl:group"><xsl:if 
                                test="position()>1">,</xsl:if>'<xsl:value-of 
                                    select="@type"/>'</xsl:for-each>)</xsl:attribute>
                    </xsl:element>
                    
                    <xsl:if test="not(@restricts)">  
                      <xsl:element name="sch:report">
                        <xsl:attribute name="test">count(index-of($group_types,name()))=0</xsl:attribute>                        
                        Non-standard group in: 
                        <xsl:element name="sch:value-of">
                            <xsl:attribute name="select">name()</xsl:attribute>
                        </xsl:element>[<xsl:element name="sch:value-of">
                            <xsl:attribute name="select">@name</xsl:attribute>
                        </xsl:element>]
                      </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:element>
            <xsl:apply-templates select="nxdl:field|nxdl:group">
                <xsl:with-param name="restricts" select="@restricts"></xsl:with-param>
                <xsl:with-param name="context" select="$mycontext"></xsl:with-param>
            </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="nxdl:field">
        <xsl:param name="restricts" />
        <xsl:param name="context" />
        <xsl:text>
        </xsl:text>
        <xsl:element name="sch:pattern">
            <xsl:attribute name="fpi">
                <xsl:value-of select="$context"/>/<xsl:value-of select="@name"/>
            </xsl:attribute>
            <xsl:if test="$restricts">
                <xsl:element name="sch:rule">
                    <xsl:attribute name="context">//<xsl:value-of select="$context"/></xsl:attribute>
                    <xsl:element name="sch:assert">
                        <xsl:attribute name="test">nx:<xsl:value-of select="@name"/></xsl:attribute>                        
                        Missing field '<xsl:value-of select="@name"/>' in <sch:value-of select="name()"/>
                    </xsl:element> 
                </xsl:element>
            </xsl:if>
            <xsl:element name="sch:rule">
                <xsl:attribute name="context">//<xsl:value-of select="$context"/>/nx:<xsl:value-of 
                        select="@name"/></xsl:attribute>
                <xsl:comment> sch:extends  check NAPItype attribute value (syntax is already checked) </xsl:comment>
                <!-- assume that the converted files will supply all defaults -->
                <xsl:element name="sch:assert">
                    <xsl:variable name="ntype">
                      <xsl:choose>
                        <xsl:when test="@type"><xsl:value-of select="@type"/></xsl:when>
                        <xsl:otherwise>NX_CHAR</xsl:otherwise>
                      </xsl:choose>                        
                    </xsl:variable>
                    <xsl:variable name="valid_types">
                        <xsl:call-template name="translate_type">
                            <xsl:with-param name="type" select="$ntype"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:attribute name="test">count(index-of(<xsl:value-of select="$valid_types"/>,tokenize(@NAPItype,'\[')[1] )) = 1</xsl:attribute>
                    NAPItype must be one of <xsl:value-of select="$valid_types"/> for '<xsl:value-of select="@name"/>'
                </xsl:element>
            </xsl:element>
        </xsl:element>
        <!-- handle enumerations -->
        <xsl:if test="nxdl:enumeration">
            <xsl:element name="sch:pattern">
                <xsl:attribute name="fpi">
                    <xsl:value-of select="$context"/>/<xsl:value-of 
                        select="@name"/>_enumeration</xsl:attribute>
                <xsl:comment> check value against enumeration </xsl:comment>
                <xsl:variable name="enum_name">enumeration</xsl:variable>
                <xsl:element name="sch:rule">
                    <xsl:attribute name="context">//<xsl:value-of 
                        select="$context"/>/nx:<xsl:value-of 
                            select="@name"/></xsl:attribute>
                    <xsl:element name="sch:let">
                        <xsl:attribute name="name">enumeration</xsl:attribute>
                        <xsl:attribute name="value">(<xsl:for-each 
                            select="nxdl:enumeration/nxdl:item"><xsl:if 
                                test="position()>1">,</xsl:if>'<xsl:value-of 
                                    select="@value"/>'</xsl:for-each>)</xsl:attribute>
                    </xsl:element>
                    <xsl:element name="sch:assert">
                        <xsl:attribute name="test">count(index-of($enumeration,.))=1</xsl:attribute>
                        type 
                        <xsl:element name="sch:value-of">
                            <xsl:attribute name="select">.</xsl:attribute>
                        </xsl:element>
                        must be one of 
                        <xsl:element name="sch:value-of">
                            <xsl:attribute name="select">$enumeration</xsl:attribute>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="nxdl:group">
        <xsl:param name="restricts" />
        <xsl:param name="context" />
        <xsl:comment>::<xsl:value-of select="name()"/>::<xsl:value-of 
                select="@type"/><xsl:if 
                    test="count(@name)>0">[<xsl:value-of 
                        select="@name"/>]</xsl:if>::</xsl:comment>
        <xsl:if test="$restricts">
            <xsl:element name="sch:pattern">
                <xsl:attribute name="fpi">
                    <xsl:value-of select="$context"/>/<xsl:value-of select="@name"/>
                </xsl:attribute>
                <xsl:element name="sch:rule">
                <xsl:attribute name="context">//<xsl:value-of select="$context"/></xsl:attribute>
                <xsl:element name="sch:assert">
                    <xsl:attribute name="test">nx:<xsl:value-of select="@type"/></xsl:attribute>                        
                    Missing group '<xsl:value-of select="@type"/>' in <sch:value-of select="name()"/>
                </xsl:element> 
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:variable name="mycontext">
            <xsl:value-of select="$context"/>/nx:<xsl:value-of select="@type"/>
            <xsl:if test="@name">[@name='<xsl:value-of select="@name"/>']</xsl:if>
        </xsl:variable>        
        <xsl:apply-templates select="nxdl:field|nxdl:group">
            <xsl:with-param name="restricts" select="$restricts"></xsl:with-param>
            <xsl:with-param name="context" select="$mycontext"></xsl:with-param>
        </xsl:apply-templates>
        
    </xsl:template>
    
    <!-- return a sequence of valid types for an NXDL type -->
    <xsl:template name="translate_type">
        <xsl:param name="type" select="NX_CHAR"/>
        <xsl:variable name="posints">'NX_UINT8','NX_UINT16','NX_UINT32','NX_UINT64'</xsl:variable>
        <xsl:variable name="ints"><xsl:value-of select="$posints"/>,'NX_INT8','NX_INT16','NX_INT32','NX_INT64'</xsl:variable>
        <xsl:variable name="floats">'NX_FLOAT32','NX_FLOAT64'</xsl:variable>
        <xsl:variable name="numbers"><xsl:value-of select="$ints"/>,<xsl:value-of select="$floats"/></xsl:variable>
        <xsl:choose>
            <xsl:when test="$type = 'NX_NUMBER'">(<xsl:value-of select="$numbers"/>)</xsl:when>
            <xsl:when test="$type = 'NX_FLOAT'">(<xsl:value-of select="$floats"/>)</xsl:when>
            <xsl:when test="$type = 'NX_INT'">(<xsl:value-of select="$ints"/>)</xsl:when>
            <xsl:when test="$type = 'NX_UINT'">(<xsl:value-of select="$posints"/>)</xsl:when>
            <xsl:when test="$type = 'NX_DATE_TIME'">('NX_CHAR')</xsl:when>
            <xsl:when test="$type = 'ISO8601'">('NX_CHAR')</xsl:when>
            <xsl:otherwise>('<xsl:value-of select="$type"/>')</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- return type string before any [ -->
    <xsl:template name="get_type">
        <xsl:param name="type" select="NX_CHAR"/>
        <xsl:variable name="mat" select="substring-before($type, '[')"/>
        <xsl:choose>
            <xsl:when test="$mat"><xsl:value-of select="$mat"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
