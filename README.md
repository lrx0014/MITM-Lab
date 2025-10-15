# MITM-Lab
Lab session: the Man-in-the-Middle Attacks

> **⚠️ Disclaimer:** This lab runs on a completely isolated virtual network to ensure ethical safety. Do not connect the lab environment to production or public networks.

## Lab Topology

The exercise uses a three-node layout:

- **Victim workstation** (`192.168.99.1`): Ubuntu Desktop VM with a web browser. It resolves `victim.com` through the lab DNS and browses the simulated banking page.
- **Server node** (`192.168.99.2`): Ubuntu Server VM hosting the Flask victim application, Nginx reverse proxy, and dnsmasq DNS service. This system represents the legitimate infrastructure targeted in the MITM scenario.
- **Attacker node** (`192.168.99.3`): Kali Linux VM positioned on the same network segment, able to intercept or modify traffic between the victim and server.

## Simulated Victim Web App

This repository includes a simple Python + HTML victim site that accepts form submissions. It is meant to act as the target page during Man-in-the-Middle scenarios.

### Quick start (automated)

- **First of all, clone this repo**

  ```bash
  git clone https://github.com/lrx0014/MITM-Lab.git
  ```

- **Using Docker**

  ```bash
  docker build -t mitm-lab:victim-site .
  docker run --rm -p 8000:8000 mitm-lab:victim-site
  ```

- **Using `start.sh`**

  ```bash
  chmod +x start.sh
  ./start.sh
  ```

Both options launch the app on port `8000`. Adjust firewall rules or port mappings so the victim workstation (`192.168.99.1`) can reach `http://192.168.99.2:8000/`.


### Reverse proxy with Nginx (Automated Way)
- **Provision server services with `init_env.sh`** (run on the server node)

  ```bash
  chmod +x init_env.sh
  ./init_env.sh
  ```

  The script installs Nginx and dnsmasq if needed, copies the lab proxy configuration, and points `victim.com` to the server's detected IP address. Set `SERVER_IP=<your-server-ip>` if auto-detection picks the wrong interface.


### Reverse proxy with Nginx (Manual Way)

Use the provided `nginx_conf/nginx.conf` to forward traffic for `victim.com` to the Flask app:

```bash
sudo apt install nginx
sudo cp nginx_conf/nginx.conf /etc/nginx/sites-available/victim
sudo ln -s /etc/nginx/sites-available/victim /etc/nginx/sites-enabled/victim
sudo nginx -t
sudo systemctl reload nginx
```

Ensure the Flask app is running on port `8000`, and update your hosts file (or DNS) so `victim.com` resolves to `192.168.99.2`, the address of the Ubuntu Server node.

### Local DNS with dnsmasq

If you want a lightweight DNS service that resolves `victim.com` to your lab proxy, install and configure `dnsmasq` on Ubuntu:

```bash
sudo apt install dnsmasq
echo "address=/victim.com/192.168.99.2" | sudo tee /etc/dnsmasq.d/victim.conf
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq
```

Point victim systems to use `192.168.99.2` as their DNS server. On Ubuntu Desktop, edit the connection in NetworkManager (IPv4 tab → set DNS to `192.168.99.2`); on the server node itself, keep `/etc/systemd/resolved.conf` pointing to the local resolver with `DNS=127.0.0.1` and `Domains=~victim.com`, then run `sudo systemctl restart systemd-resolved`. With dnsmasq active, queries for `victim.com` from the victim workstation will resolve to `192.168.99.2`, keeping all traffic inside your MITM lab.
