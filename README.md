**1985.**
As a Russian scientist and cryptologist, you spend your days studying and deciphering ancient documents and research. But one day, you are given a task unlike any other: to solve the mystery of the missing staff of the Hovrino Hospital. With the entire department tied up with other cases, the responsibility falls to you.

## Install (2 steps)

You need a server or VM with **Ubuntu 24.04** or **Debian 12/13** (a clean one is fine, 1 CPU and 1 GB RAM are enough) on the same network as the players. Debian has no Asterisk package, so there the installer builds Asterisk 22 from its official source (it takes longer; give the VM 2 GB RAM for that). On Debian without `sudo`, run the commands below as root (`su -`) and leave out `sudo`.

**1. On the server, download the game:**

```bash
sudo apt install -y git
git clone https://github.com/yaahoo77/HovrinoFacilityFixed.git
cd HovrinoFacilityFixed
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
0. Open the website in your browser: `http://SERVER-IP/` (the address the installer printed as **Website**, the same as SIP Server).
1. Log in to the phone app with the details from the install. Wait for **Online**.
2. Call **7000**. You hear a beep and the game hangs up.
3. Listen to the calls. Crack the clue.

## Gameplay (spoiler)

The phone calls you, plays a message, and keeps calling back with a clue until you find the right page on the website:

1. The player calls **7000** from their phone app. The game hangs up and, 10 seconds later, calls back with **Sms**.
2. 10 seconds after Sms has been heard to the end, it calls with the **Caesar cipher clue** (szyfrCezaraStrona). The clue plays over and over until the player hangs up. If the call isn't answered, it's tried again every 3 minutes. If Sms isn't heard to the end, Sms is repeated first.
3. After hanging up on the clue, the player has to crack it and open **/documentation** on the website. The phone then rings 10 seconds later with the final message (Untitled), which plays over and over until the player hangs up. However often the page is opened, it calls only once. If the player misses that call, it rings again every 30 seconds (up to 10 times).

4. **The ending.** When the player opens the document **X07 part 2** with its access code (the address becomes `/documentation/x07-research-part-2/unlocked`), the phone rings 2 minutes later with a message (ngagagagaga), then a voice says: *"Press one to accept what you have done. Press two to end it all."* Key **1** plays the happy ending, key **2** the bad ending. Either way the call then closes with one last message (outro). Without a choice the question repeats 3 times; if the call is missed or nobody presses a key, it rings again 30 seconds later (up to 10 times). This call also comes only once, and only after the /documentation call.

The website address can be shared freely: opening the site or /documentation **before** the player has picked up the clue call does nothing (no call, and the final call is not used up).

The clue is a Caesar cipher (shift 3) that gives only the page name: `grfxphqwdwlrq` decodes to `documentation`. The player adds it to the website address, which is the same address they typed into MicroSIP as SIP Server: `http://SERVER-IP/documentation`.

Every call comes from the same number, **7000 "Phone Game"**. Calling 7000 again restarts the game from the beginning.
