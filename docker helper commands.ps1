$containerName = "naughty_aryabhata"
$imageName = "techotron/iis:0.1"
$newBuildTag = "techotron/iis:0.6"
$dockerFile = "c:\users\edwar\git\timecloud-scripts\Docker Builds\first-iis\."

# Build container
docker build -t $newBuildTag $dockerFile

# Start container
docker run -d -p 80:80 $imageName

# Open terminal within running container
docker exec -it $(docker ps -f "name=$containerName" -q) cmd

# Container URL
$("http://" + $(docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $containerName) + "/dev")

# Test the site
curl $("http://" + $(docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $containerName) + ":80")