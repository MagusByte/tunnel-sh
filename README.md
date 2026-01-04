# README

A small Bash utility to **safely tunnel `localhost` services over SSH** using a middle-man server — ideal for development when your home machine is **not directly accessible from the internet**.

---

## 📦 Requirements

* Bash (macOS / Linux)
* OpenSSH (`ssh`)
* A server that you can connect to using SSH (VPS, jump host, etc.)
  * If you can connect to it using SSH 

---

## 🔧 Installation

Clone the repo or copy the script:

```bash
git clone https://github.com/MagusByte/tunnel-sh
cd tunnel-sh
chmod +x tunnel.sh
```

---

## 🚀 Features

* ✅ Client / Server modes
* 💾 Remembers port & server between runs
* 🧭 Interactive prompts with defaults
* 🧾 Confirmation before execution
* 📋 List running tunnels
* ❌ Kill all tunnels safely
* 🤖 Non-interactive mode for scripts/CI

---

## 🧠 Usage

### Start a reverse tunnel (home machine)

```bash
./tunnel.sh server -p 4200 --server user@example.com
```

This exposes `localhost:4200` on your **home machine** to the middle-man server.

---

### Start a local tunnel (remote laptop)

```bash
./tunnel.sh client -p 4200
```

Now open `http://localhost:4200` on your laptop behaves as if the service were running locally on your home desktop.

---

## 🧑‍💻 Interactive Mode

If you omit values, the script will ask nicely and remember your answers:

```bash
./tunnel.sh client
```

You’ll see prompts like:

```
Tunnel configuration
➤ Port to forward [4200]:
➤ Middle-man server (user@host) [user@example.com]:
```

---

## ⚙️ Non-interactive Mode

Skip confirmation prompts with `-y`:

```bash
./tunnel.sh server -p 4200 --server user@example.com -y
```

---

## 📋 List Running Tunnels

```bash
./tunnel.sh list
```

Example output:

```
Active tunnels:
• server_4200 (PID 12345)
• client_4200 (PID 12378)
```

---

## ❌ Stop All Tunnels

```bash
./tunnel.sh kill
```

Safely stops all running tunnels started by the script on your **current** machine.

### 🆘 Emergency

If an error occurs, you can kill clean up everything using the following command:

```bash
# NOTE: This will kill any ssh connection.
pkill -f "ssh"
rm -rf ~/.tunnel-pids
```

---

## 📁 Files & State

| File              | Purpose                        |
| ----------------- | ------------------------------ |
| `~/.tunnelrc`     | Stores last used port & server |
| `~/.tunnel-pids/` | PID files for active tunnels   |

This keeps tunnel management isolated and predictable.

### Clean up

To remove everything, run the following command

```bash
pkill -f "ssh"
rm -rf ~/.tunnel-pids
rm ~/.tunnelrc
```

---

## 🔐 Security Notes

* Traffic is encrypted end-to-end via SSH
* No ports are exposed publicly on your home machine
* No custom domains or HTTP rewriting
* `localhost` remains `localhost`

This makes it suitable for:

* OAuth callbacks
* Dev servers bound to localhost
* Security-sensitive tooling

---

## Motivation

This tool was created to support a development workflow where the primary development machine is not physically accessible, but must still behave like a local environment.

While working remotely on a laptop that may be underpowered or lack required datasets, the actual development environment runs on a more powerful machine at home. Remote desktop solutions (e.g. Parsec, AnyDesk) don't give you to native feel (and require stable connection). A lot of "easy" port fowarding tools (such as VS Code builtin Remote port forwarding, ngrok) improves the experience, but their port forwarding uses **custom domains** and/or the data passes through servers you don't own, which breaks applications and security models that require strict use of localhost.

This script provides a lightweight, SSH-based solution that ensures:

* `localhost` remains `localhost`
* No public services or custom domains are introduced
* Development behavior is identical whether working locally or remotely

---

## 📄 License

MIT — do whatever you want, just don’t blame me 😉