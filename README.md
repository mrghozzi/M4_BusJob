# M4 Bus Job

A dynamic and immersive bus driver job script for QBCore-based FiveM servers.
[![Watch the video](https://img.youtube.com/vi/t64kSHRymmQ/hqdefault.jpg)](https://www.youtube.com/watch?v=t64kSHRymmQ)



## Features 🚍
- Multiple color-coded bus lines with unique routes
- Interactive line selection menu using `qb-menu`
- Automatic GPS guidance to stations
- Blips for every station along the route
- In-bus dashboard displaying route information and next station
- Real-time distance tracking to the next station
- Virtual passengers who board and exit at stations
- Passenger count display on the dashboard
- Financial rewards for each passenger who completes their journey
- Total earnings display on the dashboard
- Ability to open/close bus doors using the `K` key
- Delete the bus with the `G` key
- Automatically receive keys upon bus spawn
- Notifications and instructions throughout the route
- Route loops automatically after completing all stations
- Restricted access to players with the `busdriver` job

---

## What's New in 1.4

- Dashboard auto-hides when the bus is deleted and when the player changes job away from `busdriver`.
- More robust dashboard visibility logic using `currentBusEntity` to avoid race conditions and ensure it only shows inside the spawned bus.
- NUI UI fully translated to English; distance unit set to meters (`m`).
- Compact dashboard size with more transparent background for a cleaner look.
- Dashboard hides cleanly on resource stop to prevent stuck UI elements.

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
- Open `config.lua` and change the value of `allowedJob` if you want a different job to access the system:
  ```lua
  Config.AllowedJob = "busdriver"
  ```

---

## How to Use 🛠️

- Head to the **bus depot blip** on the map.
- Press `E` near the depot to select a bus line.
- Enter the spawned bus to begin the route.
- Follow the GPS to each station.
- Use the **in-bus dashboard** on the right side of your screen to view:
  - Current route information
  - Current and next station numbers
  - Distance to the next station
  - Current passenger count
  - Total earnings from passenger fares
  - Helpful instructions
- Press `K` to open/close bus doors at stations.
- When you open doors at a station:
  - Virtual passengers will exit if it's their destination
  - You'll earn money for each passenger that completes their journey
  - New passengers will board the bus
  - You'll receive notifications about passengers boarding and exiting, including earned money
- Press `G` to delete your bus if needed. You'll see a final summary of your total earnings.

---

## Support My Work 💖
If you enjoy this script and want to support my work, you can donate here:

- ☕ [Support me on Ko-fi](https://ko-fi.com/mrghozzi)
- 💸 [Support me on Ba9chich](https://ba9chich.com/en/mrghozzi)

---

## License 📄

This script is provided as-is with no warranty. You may modify it for personal use. Do not re-upload or sell without permission.