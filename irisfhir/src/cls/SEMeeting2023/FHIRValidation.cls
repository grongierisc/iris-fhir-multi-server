Include HS.FHIRServer

Class SEMeeting2023.FHIRValidation [ Abstract ]
{

Parameter SkipIfNoProfileKEY = 1;

Parameter JavaGatewayPortKEY = 53272;

Parameter JavaGatewayServerKEY = "localhost";

Parameter IGListKEY = "/irisdev/app/src/fsh/CHUToulouseIG/fsh-generated/resources/";

Parameter TerminologyServerKEY = "https://tx.fhir.org/r4/";

Parameter PatientProfileKEY;

ClassMethod validate(theResource As %DynamicObject)
{
	#dim skipIfNoProfile As %String = ..#SkipIfNoProfileKEY
	
	#dim noProfile As %Boolean = ('theResource.%IsDefined("meta") || 'theResource.meta.%IsDefined("profile") || (theResource.meta.profile.%Size() = 0))
	
	// skipIfNoProfile: only validate if profile is specified
	if +skipIfNoProfile && noProfile
	{
		quit
	}
		
	#dim javaGatewayPort As %String = ..#JavaGatewayPortKEY
	#dim javaGatewayServer As %String = ..#JavaGatewayServerKEY
	#dim igList As %String = ..#IGListKEY
	#dim terminologyServer As %String = ..#TerminologyServerKEY
	#dim patientProfile As %String = ..#PatientProfileKEY
	
	#dim profileToValidateAgainst As %String = ""
	if noProfile 
			&& (theResource.resourceType = "Patient") 
			&& (patientProfile '= "")
	{
		set profileToValidateAgainst = patientProfile
	}	
	
	// check if Java Gateway is up
	#dim sc As %Status = ##class(%Net.Remote.Service).PingGateway(javaGatewayPort, javaGatewayServer)
	if $$$ISERR(sc)
	{
		// assuming this is local gateway, try to start it
		$$$ThrowOnError(##class(%Net.Remote.Service).StartGateway("%Java Server"))
		set sc = $$$OK
	}

	// connect to gateway
	#dim gw As %Net.Remote.Gateway = ##class(%Net.Remote.Gateway).%New()
	$$$ThrowOnError(gw.%Connect(javaGatewayServer, javaGatewayPort))
	
	// generate proxy class if it's not present
	if '$$$comClassDefined("SEMeeting2023.JavaValidatorFacade")
	{
		do ##class(%Net.Remote.Java.JavaGateway).%ExpressImport("SEMeeting2023.JavaValidatorFacade", javaGatewayPort, javaGatewayServer, $$$YES)
	}

	// create temporary file with the resource
	#dim file As %Stream.FileCharacter = ##class(%Stream.FileCharacter).%New()
	set file.TranslateTable = "UTF8"
	do theResource.%ToJSON(file)
	do file.Flush()

	// run FHIR validator against the file
	#dim json As %String = ""
	try
	{
		$$$FSLog("About to call Java validator...")
		set json = ##class(SEMeeting2023.JavaValidatorFacade).validate(gw, igList, file.Filename, terminologyServer, profileToValidateAgainst)
	}
	catch ex
	{
		set sc = $get(%objlasterror)  // exception with Java stack here!
		if (sc = "") set sc = ex.AsStatus()
	}
	kill file  // the file gets deleted here as we've never %Save()d it!

	$$$ThrowOnError(sc)


	// assemble error status in case of any severity=error issues
	#dim operationOutcome As %DynamicObject = {}.%FromJSON(json)

	#dim errorStatus As %Status = $$$OK
	#dim iter As %Iterator.Object = operationOutcome.issue.%GetIterator()
	#dim issue As %DynamicObject
	while iter.%GetNext(.key, .issue) 
	{
		if (issue.severity = "error")
		{
			#dim oneError As %Status = $$$ERROR($$$GeneralError, issue.details.text, $$$OutcomeWithPath(400, "error", issue.code, issue.expression.%Get(0)))
			$$$FHIRAddError(errorStatus, oneError)
		}
	}

	$$$ThrowOnError(errorStatus)
}

}
