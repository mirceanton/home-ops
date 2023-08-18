# Core Switch

## LAGGs

| LAGG  | Ports      | Name            | VLANs                                                          |
| :---: | :--------- | :-------------- | :------------------------------------------------------------- |
| LAG1  | 49, 51     | Firewall Uplink | ALL                                                            |
| LAG2  | 2, 3, 4, 5 | Storage Server  | `1101`, `1115`, `1969`, `1020`                                 |
| LAG3  | 7, 8       | Backup Server   | `1101`, `1115`                                                 |
| LAG4  |            |                 |                                                                |
| LAG5  | 9, 10      | Bingus Server   | `1010`, `1020`, `1030`, `1040`, `1101`, `1115`, `1742`, `1969` |
| LAG6  | 11, 12     | NUC Server      | `1020`, `1101`                                                 |
| LAG7  |            |                 |                                                                |
| LAG8  |            |                 |                                                                |

## Port Mappings

| Port  | Name                     | Defaul VLAN | Tagged VLAN                                    |
| :---: | :----------------------- | :---------: | :--------------------------------------------- |
|   1   | Storage Server Onboard   |   `1101`    |                                                |
|   2   | Storage Server Quad Port |     `1`     |                                                |
|   3   | Storage Server Quad Port |     `1`     |                                                |
|   4   | Storage Server Quad Port |     `1`     |                                                |
|   5   | Storage Server Quad Port |     `1`     |                                                |
|   6   | Backup Server Onboard    |   `1101`    |                                                |
|   7   | Backup Server Dual Port  |     `1`     |                                                |
|   8   | Backup Server Dual Port  |     `1`     |                                                |
|   9   | Bingus Server Onboard    |     `1`     |                                                |
|  10   | Bingus Server Onboard    |     `1`     |                                                |
|  11   | NUC Server Onboard       |     `1`     |                                                |
|  12   | NUC Server Onboard       |     `1`     |                                                |
|  13   | MinisForum               |   `1101`    | `1010`                                         |
|  14   |                          |             |                                                |
|  15   | Odroid N2+               |   `1769`    |                                                |
|  16   | Ordoid C4                |   `1101`    | `1101`, `1010`, `1020`, `1030`, `1040`, `1090` |
|  17   |                          |             |                                                |
|  18   |                          |             |                                                |
|  19   |                          |             |                                                |
|  20   |                          |             |                                                |
|  21   |                          |             |                                                |
|  22   |                          |             |                                                |
|  23   |                          |             |                                                |
|  24   |                          |             |                                                |
|  25   |                          |             |                                                |
|  26   |                          |             |                                                |
|  27   |                          |             |                                                |
|  28   |                          |             |                                                |
|  29   |                          |             |                                                |
|  30   |                          |             |                                                |
|  31   |                          |             |                                                |
|  32   |                          |             |                                                |
|  33   |                          |             |                                                |
|  34   |                          |             |                                                |
|  35   |                          |             |                                                |
|  36   |                          |             |                                                |
|  37   |                          |             |                                                |
|  38   |                          |             |                                                |
|  39   |                          |             |                                                |
|  40   |                          |             |                                                |
|  41   |                          |             |                                                |
|  42   |                          |             |                                                |
|  43   |                          |             |                                                |
|  44   |                          |             |                                                |
|  45   |                          |             |                                                |
|  46   |                          |             |                                                |
|  47   |                          |             |                                                |
|  48   |                          |             |                                                |
|  49   | Firewall Dual Port       |             |                                                |
|  50   |                          |             |                                                |
|  51   | Firewall Dual Port       |             |                                                |
|  52   | Desk Uplink              |   `1969`    |                                                |
