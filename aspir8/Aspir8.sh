docker run -d -p 5000:5000 --name registry registry:latest
dotnet tool install -g aspirate
aspirate init -cr localhost:5000 -ct latest --disable-secrets true --non-interactive
aspirate generate --image-pull-policy IfNotPresent --include-dashboard true --disable-secrets true --non-interactive
aspirate apply --non-interactive -k docker-desktop --disable-secrets true
