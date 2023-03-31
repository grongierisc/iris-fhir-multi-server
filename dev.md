# useful commands
## clean up docker 
```
docker system prune -f
```

## build container with no cache
```
docker-compose build --no-cache
```

## start container
```
docker-compose up -d
```

## open terminal to docker
```
docker-compose exec iris iris session iris -U FHIRServer
```

## FHIR Namespace setup

do ##class(HS.HC.Util.Installer).InstallFoundation("FHIRServer")

## fhir server configuration setup
```
do ##class(HS.FHIRServer.ConsoleSetup).Setup()
```

## load fhir resources
```
zw ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles("/irisdev/app/output/fhir/", "FHIRServer", "/fhir/r4")

kill ^%ISCLOG

kill ^ISCLOG

set ^%ISCLOG=3
```
# remove data of an FHIR repository
```
set options("deleteDataOnly") = 1
set rm = ##class(HS.FHIRServer.API.RepoManager).getInstance(1)
d rm.DeleteService(1,.options)
```

