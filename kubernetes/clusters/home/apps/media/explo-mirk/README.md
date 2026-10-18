# Explo for mirk

Explo imports ListenBrainz recommendations into Navidrome using Lidarr to acquire
missing albums. This is one instance for one user, not a shared multi-user service.
The UI is available only on the internal gateway at
`https://explo-mirk.home.mirceanton.com` (port 7288 inside the cluster).

## Before running an import

1. Confirm the `Navidrome` item (fields `username` and `password`) and the
   `ListenBrainz Token - mirk` item (field `password`) exist in a 1Password vault
   accessible to the `onepassword` ClusterSecretStore. The `Lidarr API Key` item
   (field `password`) is already used by Lidarr. Check that the `explo-mirk-secret`
   ExternalSecret is Ready. No secret values belong in Git.
2. In Lidarr, check the exact **root-folder name** `Music`. The repo shows Lidarr
   mounting the NAS's `/mnt/tank/Media/` at `/data/media`, but does not declare
   Lidarr's runtime root-folder settings. For direct imports without migration,
   the selected root must be within `/data/media/Music`, the NAS folder that
   Navidrome scans read-only as `/music`. If the folder name is different, change
   `LIDARR_ROOT_FOLDER` in the HelmRelease. Do not run an import before checking:
   Explo falls back to Lidarr's first root folder when the name is missing.
3. Log in to Navidrome as the user whose playlist this instance should create.
   In Personal Settings, enable **Scrobble to ListenBrainz** and paste that user's
   token. Enabling external services at the server level does not authorize the
   user: this per-user step is required for recommendations based on listening
   history. Note that enabling external services also turns on other Navidrome
   external integrations, not only ListenBrainz.
4. Log in to Explo with the `Navidrome` item's username and password. Set up the
   desired weekly playlist schedule in Explo's UI and try one import after the
   Lidarr folder and ListenBrainz history are confirmed. The UI stores schedule
   and application state on the 5Gi VolSync-backed config PVC; do not put
   credentials into the UI wizard. Credentials and integration endpoints come
   from the HelmRelease and ExternalSecret. Only `lidarr` is enabled as a download
   source; no YouTube or Soulseek fallback is configured.

The upstream v1.2.0 entrypoint updates yt-dlp via pip at startup and manages a
root crontab, even though this deployment only uses Lidarr. It therefore cannot
use the usual non-root/read-only-root-filesystem hardening without replacing the
entrypoint or rebuilding the image; the application process itself drops to UID
568 using `PUID`/`PGID`. The NFS music mount is read-only from Explo, while Lidarr
has its own writable music mount. Keep `--clean-downloads` disabled: the music
path is not owned by Explo.

## Rollback

Revert the PR to stop Explo and restore Navidrome's external-services setting.
The VolSync PVC has prune disabled and is not automatically removed; leave the
claim and NAS music data in place unless data deletion is explicitly approved.
