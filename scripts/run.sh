docker run --rm \
  -p 444:443 \
  -v $PWD/certs:/workspace/certs/ \
  quantum-safe-web-server
