FROM wiremock/wiremock:3.9.1

# Copy the keystore and mappings
COPY keystore.p12 /home/wiremock/keystore.p12
COPY mappings /home/wiremock/mappings

# Expose HTTPS port (443 to match extensions.gnome.org)
EXPOSE 443

# Start WireMock with HTTPS enabled on port 443
CMD ["--https-port=443", "--https-keystore=/home/wiremock/keystore.p12", "--keystore-password=password", "--keystore-type=PKCS12", "--verbose"]
