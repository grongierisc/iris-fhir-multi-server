/// FHIR REST Handler
Class Proxy.FHIRServer.RestHandler Extends HS.FHIRServer.RestHandler
{

/// This internal method assumes that the request URL has already been approved for processing.
ClassMethod dispatchToEnsemble(pRequest As HS.FHIRServer.API.Data.Request, hsrestconfig As HS.Util.RESTCSPConfig) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	
	Set inputQuickStream = ""
	Set outputQuickStream = ""
	Set inputQuickStreamId = ""
	Set outputStream = ##class(HS.FHIRServer.Util.DeviceStream).%New()	
	try {
		// Copy the HTTP body (if any) to the Ensemble-bound message
		if (..#ServiceConfigName = ""){
			Set tServiceConfigName = hsrestconfig.ServiceConfigName
		} else {
			Set tServiceConfigName = ..#ServiceConfigName
		}

		// Process Protocol rules for Accept and Content-Type Headers.
		// Check Accept (Output) first, to cover the case where Accept
		// is valid but Content-Type is not, so we can know the format
		// for the OperationOutcome for the invalid Content-Type.
		Set pRequest.ResponseFormatCode =  ..determineOutputFormatCode()
		Set pRequest.RequestFormatCode =  ..determineInputFormatCode()
		$$$FSLog("RequestType: "_pRequest.RequestFormatCode_", ResponseType: "_pRequest.ResponseFormatCode)

		// Put any uploaded content into a QuickStream
		If $IsObject(%request.Content) {
			Set inputQuickStream = ##class(HS.SDA3.QuickStream).%New()
			Set inputQuickStreamId = inputQuickStream.%Id()
			$$$ThrowOnError( inputQuickStream.CopyFrom(%request.Content) )
		}
		$$$FSLog("Processing via Interop Service: "_tServiceConfigName)
		// Dispatch to the FHIR business service
		#dim ensRequest as HS.FHIRServer.Interop.Request = ##class(HS.FHIRServer.Interop.Request).%New()
		#dim ensResponse as HS.FHIRServer.Interop.Response
		
		// Invoke the Service
		Set ensRequest.Request = pRequest
		Set ensRequest.QuickStreamId = inputQuickStreamId
	
		// An exception is thrown if the FHIR Request was not processed.
		If $G($$$EnsRuntime("Name"))="" {
			#; Production not running.
			$$$ThrowFHIR($$$HttpOnlyResponse(503))
		}
		
		// Construct the business service
		$$$ThrowOnError( ##class(Ens.Director).CreateBusinessService(tServiceConfigName, .tService) )

		// Now, process it
		$$$ThrowOnError( tService.ProcessInput(ensRequest, .ensResponse) )
		
		// Set up the HttpResponse from the FHIR Response
		Do ..marshallResponseHeaders(ensResponse.Response)
		
		// If there is any content, pass it back directly
		if ( ensResponse.QuickStreamId '= "" ) {
			Set %response.ContentType = ensResponse.ContentType
			Set %response.CharSet = ensResponse.CharSet
			Set outputQuickStream = ##class(HS.SDA3.QuickStream).%OpenId(ensResponse.QuickStreamId)
			Do outputStream.CopyFrom(outputQuickStream)
		
		}
	} catch tEx {
		Set tStatus = tEx.AsStatus()
		Set outcome = ##class(HS.FHIRServer.Util.Outcome).CreateFromStatus(tStatus, .httpStatus)
		Set %response.Status = httpStatus
		If ($IsObject($Get(pRequest))&&(pRequest.ResponseFormatCode'="")) {
			Do ..WriteResponse(outcome, pRequest.ResponseFormatCode, 1, "", outputStream, %response)
		} Else {
			Do ..WriteErrorResponse(outcome, "", "", outputStream, %response)
		}
	}
	
	// If an access token was provided with the request, and the request was
	// rejected with 401 Unauthorized, then fill in the WWW-Authenticate
	// response header. Rejection because of not using https does not count
	// as bad access token. Rejection because of placing the token in the
	// URL or in the form encoded body does not count as bad access token.
	If (+%response.Status = 401) && (%request.Secure) && (pRequest.AdditionalInfo.GetAt("USER:OAuthToken") '= "") {
		Do %response.SetHeader("WWW-Authenticate", "Bearer")
	}
	
	// ---- FINALLY ----
	// Clear out the request QuickStream
	if ( inputQuickStream '= "" ) {
		#; Do inputQuickStream.Clear(1)
		#; kill inputQuickStream
	}

	// Clear out the response QuickStream
	if ( outputQuickStream '= "" ) {
		#; Do outputQuickStream.Clear(1)
		#; kill outputQuickStream
	}

	// Return the status
	Return $$$OK
}

}
