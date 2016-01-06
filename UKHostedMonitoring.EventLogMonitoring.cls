/// Created using the page template: Default
Class UKHostedMonitoring.EventLogMonitoring Extends %ZEN.Component.page

{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

/// Domain used for localization.
Parameter DOMAIN;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<html id="eventsLog" OnDrawContent="recoverLog"/>

</page>
}

/// recover log from Ens_Util.Log
Method recoverLog(pSeed As %String) As %Status
{
	Try {
		// TODO: implement
		// SELECT %NOLOCK ID, ConfigName, Job, MessageId, SessionId, 
		//  SourceClass, SourceMethod, Stack, Text, TimeLogged, TraceCat, Type
		//  FROM Ens_Util.Log
		//  Where Type = 2
		//  Order by TimeLogged desc
		
		
 	    &sql(Declare CRSTDTYPE Cursor For 
 	     SELECT %NOLOCK ConfigName,SourceClass,Text,TimeLogged 
 	     INTO :ConfigName,:SourceClass,:Text,:TimeLogged
 	     FROM Ens_Util.Log
 	     Where Type = 2 
 	     ORDER BY TimeLogged DESC)
		&sql(Open CRSTDTYPE)
		&sql(Fetch CRSTDTYPE)
		
		While SQLCODE=0 {
			w "<pre>",ConfigName," ",SourceClass," ",Text," ",TimeLogged,"</pre>"
			&sql(Fetch CRSTDTYPE)
		}
 
		&sql(Close CRSTDTYPE)

	}
	Catch(ex) {
		&html<Error in Server method:#($ZCVT(ex.DisplayString(),"O","JS"))#'>
	}
	Quit $$$OK
}

}
