# Network Setup

## VLANS

|  Name   |      Network      |  Tag   | Description                    |
| :-----: | :---------------: | :----: | :----------------------------- |
|  `MKC`  |  `10.0.10.0/24`   | `1010` | Management Kubernetes Cluster  |
|  `AKC`  |  `10.0.20.0/24`   | `1020` | Application Kubernetes Cluster |
|  `DKC`  |  `10.0.30.0/24`   | `1030` | Development Kubernetes Cluster |
| `HVST`  |  `10.0.40.0/24`   | `1040` | Harvester Cluster              |
| `PIPDU` |  `10.0.90.0/24`   | `1090` | PiPDU Management Network       |
| `STOR`  |  `10.10.15.0/24`  | `1115` | Storage Network                |
|  `IOT`  | `172.16.69.0/24`  | `1769` | Smart Home Network             |
|  `LAN`  | `192.168.69.0/24` | `1969` | Home Network                   |
|  `DMZ`  | `172.16.42.0/24`  | `1742` | Unsafe Network                 |
|  `MAN`  |  `10.10.1.0/24`   | `1101` | Management Network             |
|  `EMG`  | `192.168.1.0/24`  | `N/A`  | EMERGENCY Network              |
|  `WAN`  |      `DHCP`       | `N/A`  | Internet                       |
