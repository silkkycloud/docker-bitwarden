####################### VAULT BUILD IMAGE  #######################
# The web-vault digest specifies a particular web-vault build on Docker Hub.
# Using the digest instead of the tag name provides better security,
# as the digest of an image is immutable, whereas a tag name can later
# be changed to point to a malicious image.
#
# To verify the current digest for a given tag name:
# - From https://hub.docker.com/r/vaultwarden/web-vault/tags,
#   click the tag name to view the digest of the image it currently points to.
# - From the command line:
#     $ docker pull vaultwarden/web-vault:v2.25.0
#     $ docker image inspect --format "{{.RepoDigests}}" vaultwarden/web-vault:v2.25.0
#     [vaultwarden/web-vault@sha256:0df389deac9e83c739a1f4ff595f12f493b6c27cb4a22bb8fcaba9dc49b9b527
#
# - Conversely, to get the tag name from the digest:
#     $ docker image inspect --format "{{.RepoTags}}" vaultwarden/web-vault@sha256:0df389deac9e83c739a1f4ff595f12f493b6c27cb4a22bb8fcaba9dc49b9b527
#     [vaultwarden/web-vault:v2.25.0]
#
FROM vaultwarden/web-vault@sha256:df7f12b1e22bf0dfc1b6b6f46921b4e9e649561931ba65357c1eb1963514b3b5 AS vault

####################################################################################################
## Final image
####################################################################################################
FROM ghcr.io/silkkycloud/caddy:2.4.6

COPY --from=vault --chown=caddy:caddy /web-vault/. /srv

USER caddy