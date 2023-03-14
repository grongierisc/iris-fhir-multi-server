ARG IMAGE=store/intersystems/sam:1.0.0.115
FROM $IMAGE
   

COPY iris.script /tmp/iris.script

RUN iris start IRIS \
	&& iris session IRIS < /tmp/iris.script \
    && iris stop IRIS quietly
