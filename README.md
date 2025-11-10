# MITM-Lab
Lab session: the Man-in-the-Middle Attacks

> **⚠️ Disclaimer:** This lab runs on a completely isolated virtual network to ensure ethical safety. Do not connect the lab environment to production or public networks.

## Lab Topology

The exercise uses a three-node layout:

- **Victim user node** (`Alice`): Ubuntu Desktop VM with a web browser. It resolves `victim.com` through the lab DNS and browses the simulated banking page.
- **Server node** (`Bob`): Ubuntu Server VM hosting the Flask victim application, Nginx reverse proxy, and dnsmasq DNS service. This system represents the legitimate infrastructure targeted in the MITM scenario.
- **Attacker node** (`Eve`): Kali Linux VM positioned on the same network segment, able to intercept or modify traffic between the victim and server.

## Lab Guide

Download the Virtual Machine images for this lab: **[Download Here](https://drive.google.com/drive/folders/1qfoB2r840WXnAG2EsF0gyGfLKoWyF8mM?usp=sharing)**

You can import them into your VMWare or VirtualBox (vmware is recommended because these images are exported from vmware workstation)

> **⚠️ WARN** when importing each image, please set their virtual network adapters to **Host-Only** mode to isolate them from the public network.

and then, you can power up these VMs to start the lab environment.

- On the **server node (Bob)**:
  - Launch the victim web app:
    ```bash
    cd MITM-Lab
    sudo chmod +x start.sh
    ./start.sh
    ```
- On the **user node (Alice)**:
  - Set DNS to `<server_ip>` (NetworkManager → IPv4 → DNS).
  - Browse to `http://victim.com/` to hit the simulated site.

- Attacker's guide (for kali linux):
  - [Task-1: MITM attack on HTTP](./attack_guide/MITM_HTTP.md)

## Simulated Victim Web App

This repository includes a simple Python + HTML victim site that accepts form submissions. It is meant to act as the target page during Man-in-the-Middle scenarios.


### Reverse proxy with Nginx
- **Provision server services with `start.sh`** (run on the server node)

  ```bash
  chmod +x start.sh
  ./start.sh
  ```

  The script configures Nginx and dnsmasq, copies the lab proxy configuration, and points `victim.com` to the server's detected IP address. Set `SERVER_IP=<server_ip>` if auto-detection picks the wrong interface.

  Ensure the Flask app is running on port `8000`, and update your hosts file (or DNS) so `victim.com` resolves to `<server_ip>`, the address of the Server node.

### Local DNS with dnsmasq

To make the experience more realistic, we set up a lightweight DNS server on the server node so the simulated web app can be accessed by domain instead of using its IP address directly. Point victim system (Alice) to use `<server_ip>` as its DNS server. On Ubuntu Desktop, edit the connection in NetworkManager (IPv4 tab → set DNS to `<server_ip>`).
