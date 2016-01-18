/// Created using the page template: Default
Class UKHostedMonitoring.EventLogMonitoring Extends %ZEN.Report.reportPage
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

Parameter DEFAULTMODE = "xml";

/// This is the optional XML namespace used for the report.
Parameter REPORTXMLNAMESPACE;

/// Parameter for recover an arbitrary number of records
Property LastIdRequest As %ZEN.Datatype.integer(ZENURL = "LastIdRequest");

/// This XML defines the logical contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
 name="Events" OnCreateResultSet="recoverLogs">

<group name="LogEntry">
<element name="ID" field="ID"/>
<element name="ConfigName" field="ConfigName"/>
<element name="SourceClass" field="SourceClass"/>
<element name="Text" field="Text"/>
<element name="TimeLogged" field="TimeLogged"/>
</group>

</report>
}

Method recoverLogs(ByRef pSC As %Status, ByRef pParameters) As %ResultSet
{
	
	set tempFolder = ##class(%SYS.System).TempDirectory()
	set instance = ##class(%SYS.System).GetInstanceName()
	set nameSpace = ##class(%SYSTEM.SYS).NameSpace()
	
	// ToDo: change the / on file name just in case we want to run on Windows
	Set fileLogID = tempFolder_"/EventLogMonitoring_"_instance_"-"_nameSpace_".log"
	Set LastId = "0"
	Set LastIdRequest=$Get(%request.Data("LastIdRequest",1))

	If LastIdRequest = "" {
		If ##class(%File).Exists(fileLogID) {
			Set file=##class(%File).%New(fileLogID)
			Do file.Open("RS")
			Set LastId = file.ReadLine()
			Do file.Close()
		}		
		//Look for the new max ID and store it on the monitor file
		set rs2 = ##class(%Library.ResultSet).%New()
		s sql = "SELECT %NOLOCK MAX(id) as MaxID FROM Ens_Util.Log Where Type = 2"
		d rs2.Prepare(sql)
		d rs2.Execute()
		d rs2.Next()
	
		Set file=##class(%File).%New(fileLogID)
		Do file.Open("WSN")
		Do file.Write(rs2.Data("MaxID"))
		Do file.Close()
	}
	Else {		
		Set LastId = LastIdRequest
	}
	
	set rs = ##class(%Library.ResultSet).%New()
		
	// SELECT %NOLOCK ID, ConfigName, Job, MessageId, SessionId, 
	//  SourceClass, SourceMethod, Stack, Text, TimeLogged, TraceCat, Type
	//  FROM Ens_Util.Log
	//  Where Type = 2
	//  Order by TimeLogged desc

	set sql = "SELECT %NOLOCK ID,ConfigName,SourceClass,Text,TimeLogged FROM Ens_Util.Log"
	_ " Where Type = 2 and ID > " _ LastId _ " ORDER BY TimeLogged DESC"
	
	set pSC = rs.Prepare(sql)
	set pSC = rs.Execute()

	Quit rs
}

}
