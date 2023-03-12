Class SEMeeting2023.FHIRValidationInteractions Extends HS.FHIRServer.Storage.Json.Interactions
{

/* NB: After modifying this class, make sure to reset the endpoint using this command:

	do ##class(HS.FHIRServer.Service).InvalidateInstances((##class(HS.FHIRServer.API.InteractionsStrategy).GetStrategyForEndpoint("/fhir-validation")).InstanceKey)  kill ^FSLOG

*/
Parameter ResourceValidatorClass = "SEMeeting2023.FHIRResourceValidator";

Parameter BatchHandlerClass As %String = "SEMeeting2023.FHIRBundleProcessor";

/// %inTransactionFlag is a global variable indicating that we are processing a Bundle
///   if set, FHIRResourceValidator skips validation of Bundle entries
Method StartTransactionBundle(pBundleTransactionId As %Integer)
{
	do ##super(pBundleTransactionId)
	set %inTransactionFlag = $$$YES
}

Method EndTransactionBundle()
{
	kill %inTransactionFlag
	do ##super()
}

}

