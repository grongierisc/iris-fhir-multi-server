from grongier.pex import BusinessProcess

import iris

from fhir.resources import bundle

import json

class FhirRouter(BusinessProcess):

    def on_iri_fhir_message(self,request : 'iris.HS.FHIRServer.Interop.Request'):
        """
        > When a FHIR request is received, create a FHIR resource from the request,
        and save it to the FHIR server. It can be any resource from the FHIR R4
        specification in a dict format.
        
        :param request: The FHIR request object
        :type request: FhirRequest
        :return: None
        """
        # Prepare the response, by default it will be a 200
        response = iris.cls('HS.FHIRServer.Interop.Response')._New()
        response.Response.Status = "200"
        target = "FHIRDefault"

        # Get the path
        path = request.Request.RequestPath
        if path == "":
            # If the path is empty, it means that the request is for the root
            # then send it to the default server
            pass
        else:
            # path is not empty
            # swith case on the path
            if "Organization" in path:
                # If the path contains Organization, then send it to the
                # Organization server
                target = "FHIROrganization"
            elif "Claim" in path:
                # If the path contains claim, then send it to the
                # claim server hapifhirclaim
                target = "FHIRClaim"

        # Send the request to the FHIR server
        response = self.send_request_sync(target,request)

        # Return the response
        return response

    def from_hl7v2(self, msg:'iris.HS.Message.FHIR.Request'):
        """
        > When a FHIR request is received, create a FHIR resource from the request,
        and save it to the FHIR server. It can be any resource from the FHIR R4
        specification in a dict format.
        """
        response = iris.cls('HS.Message.FHIR.Response')._New()
        response.Status = "200"
        
        json_payload = json.loads(msg.Payload.Read())

        # parse the json payload as an FHIR bundle
        my_bundle = bundle.Bundle(**json_payload)
        # for each entry in the bundle
        for entry in my_bundle.entry:
            # check if the resource has an identifier
            if entry.resource.identifier:
                # check if the identifier has a value
                if entry.resource.identifier[0].value:
                    # print the value
                    print(entry.resource.identifier[0].value)
                    # update the ifNoneExist request of the entry wih the value
                    entry.request.ifNoneExist = f'identifier={entry.resource.identifier[0].value}'

        # clear the payload
        msg.Payload.Clear()
        # set the payload to a string
        json_string = my_bundle.json()
        # write the json string to the payload
        n = 3000
        chunks = [json_string[i:i+n] for i in range(0, len(json_string), n)]
        for chunk in chunks:
            msg.Payload.Write(chunk)

        # Create a quick stream from the payload
        quick_stream = iris.cls('HS.SDA3.QuickStream')._New()
        quick_stream.CopyFrom(msg.Payload)

        # Create a new FHIR request
        msg = iris.cls('HS.FHIRServer.Interop.Request')._New()
        # Set headers Accept and Content-Type
        msg.Request.AdditionalInfo.SetAt("*/*","HEADER:ACCEPT")
        msg.Request.AdditionalInfo.SetAt("application/fhir+json","HEADER:CONTENT-TYPE")
        # Set the request method
        msg.Request.RequestMethod = "POST"
        # Request Format is JSON
        msg.Request.RequestFormatCode = "JSON"
        # Response Format is JSON
        msg.Request.ResponseFormatCode = "JSON"
        # Set the payload
        msg.QuickStreamId=quick_stream._Id()

        # Send the request to the FHIR server
        rsp = self.send_request_sync("FHIRDefault",msg)

        # Return the response
        response.Status = rsp.Response.Status
        
        return response