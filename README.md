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
- For each node
  - Run `ip addr` to verify IPv4 assignment.
    If no IPv4 address is listed or the interface is DOWN, use the command below to re-enable it.
    ```bash
    sudo ip link set <interface_name> up
    sudo dhcpcd <interface_name>
    ```
    `<interface_name>` could be something like `enp0s17`, `en33`, or similar. This issue sometimes occurs when using VirtualBox.
- On the **server node (Bob)**:
  - the simulated bank app is running in docker:
    ```bash
    sudo docker ps
    ```
  - and a reverse proxy with nginx:
    ```bash
    sudo vim /etc/nginx/sites-available/victim
    ```
- On the **user node (Alice)**:
  - Set /etc/hosts to map `<server_ip>` → victim.com.
  - Browse to `http://victim.com/` to hit the simulated site.

- Attacker's guide (for kali linux):
  - [Tasks: MITM attacks](./attack_guide/MITM.md)

## Simulated Victim Web App

This repository includes a simple Python + HTML victim site that accepts form submissions. It is meant to act as the target page during Man-in-the-Middle scenarios.

