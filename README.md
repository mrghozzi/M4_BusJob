# M4 Bus Job

A dynamic and immersive bus driver job script for QBCore-based FiveM servers.

## Features 🚍
- Multiple color-coded bus lines with unique routes
- Interactive line selection menu using `qb-menu`
- Automatic GPS guidance to stations
- Blips for every station along the route
- Ability to open/close bus doors using the `K` key
- Delete the bus with the `G` key
- Automatically receive keys upon bus spawn
- Notifications and instructions throughout the route
- Route loops automatically after completing all stations
- Restricted access to players with the `busdriver` job

---

## Installation 📦

1. **Download or Clone** this repository into your `resources` folder.
2. **Add the following line** to your `server.cfg`:

``` 
ensure m4-busjob 
```

3. **Make sure you have the following dependencies installed:**
- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)
- [vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys) or compatible key management system

4. **Set the job name (optional):**
- Open `client.lua` and change the value of `allowedJob` if you want a different job to access the system:
  ```lua
  local allowedJob = "busdriver"
  ```

---

## How to Use 🛠️

- Head to the **bus depot blip** on the map.
- Press `E` near the depot to select a bus line.
- Enter the spawned bus to begin the route.
- Follow the GPS to each station.
- Press `K` to open/close bus doors at stations.
- Press `G` to delete your bus if needed.

---

## Support My Work 💖
If you enjoy this script and want to support my work, you can donate here:

- ☕ [Support me on Ko-fi](https://ko-fi.com/mrghozzi)
- 💸 [Support me on Ba9chich](https://ba9chich.com/en/mrghozzi)

---

## License 📄

This script is provided as-is with no warranty. You may modify it for personal use. Do not re-upload or sell without permission.
