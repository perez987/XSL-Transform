<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/">
    <html>
      <head>
        <title>XSL Transform</title>
      </head>
      <body style="font-family: Verdana; font-size: 10pt;">
        <div align="center">
          <h3>
            <u>XML file - > HTML document</u>
          </h3>
          <table border="1" cellpadding="4" cellspacing="4" style="font-family: Verdana; font-size: 10pt;">
            <tr bgcolor="#b4eeb4">
              <td align="left">
                <b>
                  <font color="black">ID</font>
                </b>
              </td>
              <td>
                <b>
                  <font color="black">Name</font>
                </b>
              </td>
              <td width="100">
                <b>
                  <font color="black">Phone 1</font>
                </b>
              </td>
              <td width="100">
                <b>
                  <font color="black">Phone 2</font>
                </b>
              </td>
            </tr>
            <xsl:for-each select="Phonebook/Contact">
              <xsl:sort select="Name" order="ascending"></xsl:sort>
              <tr>
                <xsl:attribute name="bgcolor">
                  <xsl:choose>
                    <xsl:when test="position() mod 2 = 0">gainsboro</xsl:when>
                    <xsl:otherwise>white</xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <td align="right">
                  <font color="black">
                    <xsl:value-of select="ID"></xsl:value-of>
                  </font>
                </td>
                <td>
                  <font color="black">
                    <xsl:value-of select="Name"></xsl:value-of>
                  </font>
                </td>
                <td>
                  <font color="black">
                    <xsl:value-of select="Phone1"></xsl:value-of>
                  </font>
                </td>
                <td>
                  <font color="black">
                    <xsl:value-of select="Phone2"></xsl:value-of>
                  </font>
                </td>
              </tr>
            </xsl:for-each>
          </table>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
