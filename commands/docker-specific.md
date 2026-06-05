# Docker-Specific Reclamation (Any Host / Backend)

Docker is special because:
- `docker system prune` reclaims inside the storage driver / backend (vhdx on WSL Docker Desktop, native FS otherwise).
- The "inside" step for WSL-backend docker_data.vhdx.
- Volumes can contain precious persistent data — always list + caution.
- Images/containers/build cache are usually safe to prune when unused.

## Always First: Visibility
```bash
docker system df
docker system df -v   # detailed: images, containers, volumes, build cache with sizes
```

Agent should surface the output to user during interview/plan: "Docker is using 37 GB (18 images, 4.2 volumes, 12 GB build cache)."

## Safe Prune Commands (after df + scope edu + permission)
```bash
# Conservative (dangling only, very safe)
docker system prune -f

# More (unused images + build; no volumes)
docker system prune -a -f

# Aggressive (includes unused named volumes — ask explicitly)
docker system prune -a --volumes -f
```

Variants:
```bash
docker builder prune -f          # build cache only
docker image prune -a -f
docker volume prune -f           # list volumes first!
docker container prune -f
```

**Volume caution in permission ask**:
"docker system prune -a --volumes will remove named volumes that are not currently mounted by a running container. This can delete databases or data you intended to keep. Shall we list volumes first and only prune anonymous/dangling, or do the full including --volumes after you confirm the list?"

List volumes:
```bash
docker volume ls
docker volume inspect <name>   # size not direct, but driver + mountpoint
```

## WSL Backend Specific (Docker Desktop)
- The data lives in `docker_data.vhdx` (detected via common path or docker info).
- Prune (above) is the guest-side equivalent of deleting inside the vhdx.
- Then: close-the-loop compact on that specific docker_data.vhdx (see close-the-loop.md).
- Detection will find it alongside distro ext4.vhdx.

From docker info:
```bash
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Docker Root Dir|Backing Filesystem|WSL'
```

## Full Reset (keeps Docker Desktop installed)
- Prune as above.
- (On WSL) compact the docker_data.vhdx.
- To completely remove Docker data: uninstall Docker Desktop + from host `wsl --unregister docker-desktop` (deletes its vhdx entirely). Only after user is sure (strong yellow/red edge).

## Inside Containers Themselves
Cleanup limited to container FS. The interesting space is the Docker *data dir* on the host/VM. Agent running inside a container can only do limited guest work; advise user to run the skill on the Docker host.

## Integration with Catalog
Catalog has "docker-system" entry (green, command-driven, no static paths) with decision_guidance exactly on the -a --volumes caution and "run df first".

## Agent Flow for Docker
1. Detection sees docker → run `docker system df -v` as part of scan.
2. In plan: educate briefly ("prune reclaims inside the backend; for WSL backend we can also compact the backing vhdx after").
3. If WSL-docker context + opt-in for host-visible: include the docker vhdx compact in close steps.
4. Permission for prune scope (list volumes if aggressive).
5. Direct execute the prune(s).
6. If hybrid: later the compact step for docker_data.vhdx (separate perm).
7. Re-df + report.

## Gotchas
- Running containers use images/volumes — prune skips in-use.
- Build cache is huge for some (multi-stage, layers).
- On native Linux Docker: prune + fstrim (if SSD) for full effect.
- Named volumes for databases: treat like yellow user data.

See close-the-loop.md for the WSL-docker compact sequence, green-prune.md for the prune lines, explanations/platform-notes.md, catalog "docker-system".
