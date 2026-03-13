# This script builds the container image for the catalog-api.
# It should be run from the root of the repository.

# Navigate to the Catalog.API directory
cd eShop

# Build the docker image
docker build -t catalog-api:latest -f src/Catalog.API/Dockerfile .

echo "Successfully built catalog-api:latest image."
