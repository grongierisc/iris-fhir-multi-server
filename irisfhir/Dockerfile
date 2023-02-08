FROM intersystemsdc/irishealth-community:preview

RUN \
	--mount=type=bind,src=.,dst=/home/irisowner/fhirapp \
	--mount=type=bind,src=./iris.script,dst=/tmp/iris.script \
	iris start IRIS && \
	iris session IRIS < /tmp/iris.script && \
	iris stop iris quietly
