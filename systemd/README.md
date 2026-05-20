# systemd unit templates — persistence / auto-start

Steps 5–6 of the main walkthrough leave the server-side processes running in
open terminals. The moment the C2 server or redirector reboots — or you
stop/start the instances to save on EC2 costs between sessions — those
processes die and the chain has to be hand-started again.

These three unit templates make the **server-side** processes start
automatically on boot. The operator-side SSH proxy (Step 5) stays manual —
it runs from your attack box, not the cloud hosts.

| Unit | Host | Process |
|---|---|---|
| `c2-teamserver.service` | C2 server | C2 teamserver (`:50050` control + `:443` listener) |
| `socat-redirector.service` | Redirector | socat `:443` → C2 server `:443` |
| `cloudflared-tunnel.service` | Redirector | cloudflared tunnel |

## Install (per unit)

1. Open the unit file and replace every `<PLACEHOLDER>` (see comments inside).
2. Copy it to its host and enable it:

   ```bash
   # example: teamserver on the C2 server (hop via bastion)
   scp -i .ssh/internal.pem systemd/c2-teamserver.service c2server@<C2_IPV4>:/tmp/
   ssh -i .ssh/internal.pem c2server@<C2_IPV4> '
     sudo mv /tmp/c2-teamserver.service /etc/systemd/system/
     sudo chown root:root /etc/systemd/system/c2-teamserver.service
     sudo systemctl daemon-reload
     sudo systemctl enable --now c2-teamserver.service
   '
   ```

   Same pattern for `socat-redirector.service` and `cloudflared-tunnel.service`
   on the redirector.

3. Validate before trusting it: `sudo systemd-analyze verify /etc/systemd/system/<unit>`

## Inspect

```bash
systemctl status <unit>
journalctl -u <unit> -f
```

## Notes

- `enable --now` enables (auto-start on boot) **and** starts immediately. If a
  process is already running in a tmux/screen session on the same port, drop
  `--now` to avoid a port collision — the unit will then take over on the next
  reboot instead.
- The teamserver password is read from a root-only file (`/root/.c2-teamserver-pass`)
  so it is never stored in the unit or in shell history. Create it once — see
  the comments in `c2-teamserver.service`.
- IPv6 addresses on an EC2 ENI are stable across stop/start, so the redirector
  and bastion keep their addresses. Auto-assigned public IPv4 does **not** —
  use an Elastic IP if a box needs a fixed public IPv4.
