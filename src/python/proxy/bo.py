from fhirpy import SyncFHIRClient
from fhir.resources import construct_fhir_element
from grongier.pex import BusinessOperation
from base64 import b64encode
import json
import iris

class FhirClient(BusinessOperation):
    """
    > This class is a business operation that will be used to save a FHIR
    resource in the FHIR server.
    """
    client: SyncFHIRClient = None

    def basic_auth(self,username, password):
        """
        > It creates a basic auth token to be used in the header of the request
        :param username: The username
        :type username: str
        :param password: The password
        :type password: str
        :return: The token
        :rtype: str
        """
        token = b64encode(f"{username}:{password}".encode('utf-8')).decode("ascii")
        return f'Basic {token}'

    def on_init(self):
        """
        It changes the current url if needed using the params of the
        management portal
        :return: None
        """
        if not hasattr(self,'url'):
            self.url = 'http://localhost:52773/fhir/r4'

        self.client = SyncFHIRClient(url=self.url,extra_headers={"Content-Type":"application/json+fhir"}
        , authorization= self.basic_auth('SuperUser', 'SYS'))

        return None


    def on_fhir_request(self, request:FhirRequest):
        """
        > When a FHIR request is received, create a FHIR resource from the request,
        and save it to the FHIR server. It can be any resource from the FHIR R4
        specification in a dict format.
        
        :param request: The FHIR request object
        :type request: FhirRequest
        :return: None
        """
        response = iris.cls('HS.FHIRServer.Interop.Response')._New()
        response.Response.Status = "200"
        # Get the resource type from the request ( here "Organization" )
        resource_type = request.resource["resource_type"]

        # Create a resource of this type using the request's data
        resource = construct_fhir_element(resource_type, request.resource)

        # Save the resource to the FHIR server using the client
        self.client.resource(resource_type,**json.loads(resource.json())).save()

        return response

    def on_message_from_hl7(self, message:'iris.HS.Message.FHIR.Request'):
        """
        > When a message is received, it calls the method on_message of the
        parent class (BusinessOperation) to handle the message.
        :param message: The message received
        :type message: iris.Message
        :return: None
        """
        response = iris.cls('HS.Message.FHIR.Response')._New()
        response.Status = "200"

        json_payload = json.loads(message.Payload.Read())
        if json_payload["resourceType"] != "Patient":
            # Don't save the patient in the FHIR server
            try:
                self.client.resource(message.Type,**json_payload).update()
            except Exception as e:
                response.Status = "500"
        
        return response

