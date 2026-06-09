# AndroDeb

Debian XFCE Installer for Termux.

An automated and interactive script to install a fully functional **Debian environment** inside Termux (Android). 

During the installation, you can choose between a **Minimal CLI (Command Line)** environment or a **Full Desktop Environment (XFCE4)** integrated natively with Termux-X11.

![Termux Debian](https://img.shields.io/badge/Platform-Termux%20Android-blue)
![Debian](https://img.shields.io/badge/System-Debian-red)

## Features
- 🔄 **Interactive setup:** Choose between CLI-Only or Full Desktop (XFCE).
- 🧑‍💻 **Automatic User Creation:** Sets up a normal user with `sudo` privileges.
- 🕒 **Timezone Sync:** Automatically matches your Debian timezone with your Android timezone.
- 📂 **Shared Storage:** Automatically links your Android `Documents` folder to your Debian home folder.
- 🪄 **Magic Wrapper:** Easily launch your system using a single, intuitive `debian` command.
- 🔊 **Audio Support:** Pre-configured PulseAudio routing to Android.

---

## Prerequisites (For Desktop Mode)
If you plan to install the **Full Desktop (XFCE)**, you must install the **Termux-X11 Companion App** on your Android device:
1. Go to the [Termux-X11 GitHub Releases](https://github.com/termux/termux-x11/releases) page.
2. Download and install the latest `app-universal-debug.apk`.

*(No extra apps are required if you choose the CLI-Only installation).*

---

## One-Command Installation

Open Termux and run the following command to download and start the installation immediately:

```bash
curl -sLO https://raw.githubusercontent.com/an-droe/AndroDeb/refs/heads/main/install.sh && chmod +x install.sh && ./install.sh
```

> **Note:** Make sure to grant storage permissions to Termux if prompted. The script requires at least ~500MB for CLI and ~4GB for the GUI.

---

## How to Use

After a successful installation, you can use the newly created `debian` command anywhere in Termux.

### Log in as your Normal User (Recommended)
- **Terminal Only:**
  ```bash
  debian your_username
  ```
- **Launch XFCE Desktop:**
  ```bash
  debian your_username --x11
  ```

### Log in as Root (Administrator)
- **Terminal Only:**
  ```bash
  debian
  ```
- **Launch XFCE Desktop:**
  ```bash
  debian --x11
  ```

---

## How to Uninstall
If you want to completely remove Debian to free up space, run this in Termux:
```bash
proot-distro remove debian
rm $PREFIX/bin/debian
```

## 🤝 Contributing
Feel free to fork this project and submit pull requests. Any improvements are welcome!
