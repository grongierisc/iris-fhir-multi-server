from grongier.pex import BusinessProcess

import iris

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

    def router(self, resource):
        pass