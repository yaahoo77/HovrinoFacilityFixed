**1985.**
As a Russian scientist and cryptologist, you spend your days studying and deciphering ancient documents and research. But one day, you are given a task unlike any other: to solve the mystery of the missing staff of the Hovrino Hospital. With the entire department tied up with other cases, the responsibility falls to you.

## Install (2 steps)

You need a server or VM with **Ubuntu 24.04** or **Debian 12/13** (a clean one is fine, 1 CPU and 1 GB RAM are enough) on the same network as the players. Debian has no Asterisk package, so there the installer builds Asterisk 22 from its official source (it takes longer; give the VM 2 GB RAM for that). On Debian without `sudo`, run the commands below as root (`su -`) and leave out `sudo`.

**1. On the server, download the game:**

```bash
sudo apt install -y git
git clone https://github.com/yaahoo77/HovrinoFacility.git
cd HovrinoFacility
```

**2. Run the installer:**

```bash
sudo bash install.sh
```

It asks once, then does everything by itself: installs Asterisk, Apache and PHP, fixes a fresh Asterisk (missing config files, no SIP port), backs up any existing Asterisk config, adds the game and the website, and opens the firewall if `ufw` is on. At the end it prints the login for MicroSIP (Menu > Add account):

```
Account name : Phone Game
SIP Server   : 192.168.1.50
Username     : 6001
Domain       : 192.168.1.50
Login        : 6001
Password     : xxxxxxxxxxxxxxxx
Transport    : UDP
```

Running the installer again is safe, keeps the password and prints the same login again. For a new password run `sudo NEW_PASSWORD=1 bash install.sh`.

To update the game later: `git pull`, then `sudo bash install.sh` again.

**Using a VirtualBox VM?** Set its network adapter to **Bridged Adapter** (Settings → Network). With the default NAT, the VM gets an address like `10.0.2.15` that phones and other PCs can't reach.

If Asterisk is already set up on the server, the installer only adds its own files and one `#include` line in `pjsip.conf` and `extensions.conf`, after a backup.

## Your website

The website is in the `site/` folder and is installed together with the game, at `http://SERVER-IP/`. 

## Play

1. Log in to the phone app with the details from the install. Wait for **Online**.
2. Call **7000**. You hear a beep and the game hangs up.
3. Listen to the calls. Crack the clue.

## Settings

`/etc/phonegame.conf` (times in seconds). Changes apply to the next planned call.

| Setting | Default | What |
|---|---|---|
| `SMS_DELAY` | 10 | from hanging up on 7000 to the Sms call |
| `FIRST_SZYFR_DELAY` | 10 | from the end of Sms to the first clue call |
| `SZYFR_INTERVAL` | 180 | a clue call that isn't answered is tried again after this (3 minutes) |
| `SZYFR_AGAIN_AFTER_HANGUP` | 0 | 0 = after the player hangs up on the clue, wait for /documentation. For example 180 = also call with the clue again 3 minutes later |
| `MAX_SZYFR_CALLS` | 10 | stop after this many clue calls (call 7000 to start again) |
| `DOCUMENTATION_DELAY` | 10 | from opening /documentation to the /documentation call |
| `ENDING_DELAY` | 120 | from opening X07 part 2 /unlocked to the ending call (press 1 or 2) |

To use other sounds, convert them to 8 kHz mono WAV with the same names (`ffmpeg -i new.mp3 -ar 8000 -ac 1 sms.wav`) and copy them to Asterisk's `sounds/custom/` folder (`/usr/share/asterisk/sounds/custom` on Ubuntu's package, `/var/lib/asterisk/sounds/custom` when Asterisk was built from source).

## Useful commands

```bash
sudo -u asterisk phonegame-call status    # clue calls so far, waiting calls
sudo -u asterisk phonegame-call reset     # stop all calls, forget progress
sudo -u asterisk phonegame-call start     # same as calling 7000
sudo asterisk -rx "pjsip show contacts"   # is the phone app online?
journalctl -t phonegame                   # what the game planned
```

## If something doesn't work

| What you see | What to do |
|---|---|
| MicroSIP stays "Registering" / offline | Use the server's network address (`hostname -I`, like `192.168.x.x`) in SIP Server and Domain. VirtualBox VM: network adapter set to **Bridged Adapter**. |
| `curl -X POST http://localhost/phonegame/documentation.php` says `could not plan the call` | Its `detail` says why. Run `sudo bash install.sh` again (it re-creates `/var/lib/phonegame-web` with the right permissions). Check the watcher with `systemctl status phonegame-web.path`. |
| `planned`, but the phone doesn't ring | `sudo journalctl -u phonegame-web.service` shows what happened. `sudo -u asterisk phonegame-call status` shows whether a call is waiting. |
| `already_called` | /documentation has already called once. Call 7000 to start a new game. |
| `too_early` | The player hasn't picked up the clue call yet, so /documentation does nothing on purpose. Call 7000 and listen to the calls first. |
| Asterisk shows an error or doesn't answer | `sudo systemctl restart asterisk`, then `sudo systemctl status asterisk` should say "active (running)". If it doesn't start, `sudo journalctl -u asterisk -n 30` and `sudo tail -50 /var/log/asterisk/messages.log` show why. Running `sudo bash install.sh` again also repairs the setup and restarts Asterisk. |
| "Unable to open ... asterisk.conf" | Harmless: `asterisk` was run without `sudo`. Use `sudo asterisk -r` to open the Asterisk console. |

## How it works

| File | What |
|---|---|
| `asterisk/phonegame-pjsip.conf` | the player's line 6001. It can only call 7000 (context `phonegame-phone`). Its password is kept in `/etc/phonegame-6001.password` (root only), so the installer can print the login every time. |
| `asterisk/phonegame-extensions.conf` | 7000 starts the game; `sms`, `szyfr`, `documentation` play the sounds; `ending` plays ngagagagaga and asks for key 1 or 2; after each call a hangup handler (or the `failed` extension, if nobody answered) asks `phonegame-call` for the next call |
| `bin/phonegame-call` | writes call files to `/var/spool/asterisk/outgoing/`. A call file whose modification time is in the future is placed by Asterisk at that time, which is how the delays work. It remembers progress in `/var/lib/phonegame/`. |
| `web/phonegame/documentation.php`, `ending.php` | leave a request file in `/var/lib/phonegame-web/` (/documentation opened, X07 part 2 opened). That's all the website is allowed to do: no sudo, no access to Asterisk. |
| `systemd/phonegame-web.path` | watches for that file and runs `phonegame-call web` as the asterisk user, which plans the last call (on servers without systemd, a cron job does this once a minute) |
| `site-assets/` | the website's own recordings (x07-part-2-conversation.wav for X07, ward14.wav for the cameras). Lovable keeps uploaded files on its server, so `tools/build-site.sh` copies these into `site/` at the address the website asks for |
| `sounds/` | sms.wav, szyfr.wav, documentation.wav, ngagagagaga.wav, ending_menu.wav (the "press one / press two" voice), happy_ending.wav, bad_ending.wav, outro.wav (8 kHz mono) |
## Gameplay (spoiler)

The phone calls you, plays a message, and keeps calling back with a clue until you find the right page on the website:

1. The player calls **7000** from their phone app. The game hangs up and, 10 seconds later, calls back with **Sms**.
2. 10 seconds after Sms has been heard to the end, it calls with the **Caesar cipher clue** (szyfrCezaraStrona). The clue plays over and over until the player hangs up. If the call isn't answered, it's tried again every 3 minutes. If Sms isn't heard to the end, Sms is repeated first.
3. After hanging up on the clue, the player has to crack it and open **/documentation** on the website. The phone then rings 10 seconds later with the final message (Untitled), which plays over and over until the player hangs up. However often the page is opened, it calls only once. If the player misses that call, it rings again every 30 seconds (up to 10 times).

4. **The ending.** When the player opens the document **X07 part 2** with its access code (the address becomes `/documentation/x07-research-part-2/unlocked`), the phone rings 2 minutes later with a message (ngagagagaga), then a voice says: *"Press one to accept what you have done. Press two to end it all."* Key **1** plays the happy ending, key **2** the bad ending. Either way the call then closes with one last message (outro). Without a choice the question repeats 3 times; if the call is missed or nobody presses a key, it rings again 30 seconds later (up to 10 times). This call also comes only once, and only after the /documentation call.

The website address can be shared freely: opening the site or /documentation **before** the player has picked up the clue call does nothing (no call, and the final call is not used up).

The clue is a Caesar cipher (shift 3) that gives only the page name: `grfxphqwdwlrq` decodes to `documentation`. The player adds it to the website address, which is the same address they typed into MicroSIP as SIP Server: `http://SERVER-IP/documentation`.

Every call comes from the same number, **7000 "Phone Game"**. Calling 7000 again restarts the game from the beginning.

There's no app server, database or Node.js: it's Asterisk's dialplan, one small shell script that writes Asterisk "call files", and one PHP file for the website.


Built with help from Claude (AI).
