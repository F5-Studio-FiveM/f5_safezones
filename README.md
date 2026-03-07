<div align="center">

<img src="https://i.imgur.com/OE6A1wO.jpeg" alt="F5 Safezones" width="100%" />

<br /><br />

<a href="https://github.com/F5StudioFiveM/f5_safezones/releases"><img src="https://img.shields.io/github/v/release/F5StudioFiveM/f5_safezones?label=&style=for-the-badge&color=f5a623&labelColor=16161d" alt="Version" /></a>&nbsp;
<a href="https://github.com/F5StudioFiveM/f5_safezones/releases"><img src="https://img.shields.io/github/downloads/F5StudioFiveM/f5_safezones/total?label=downloads&style=for-the-badge&color=16161d&labelColor=16161d" alt="Downloads" /></a>&nbsp;
<a href="https://github.com/F5StudioFiveM/f5_safezones/stargazers"><img src="https://img.shields.io/github/stars/F5StudioFiveM/f5_safezones?label=stars&style=for-the-badge&color=16161d&labelColor=16161d" alt="Stars" /></a>&nbsp;
<a href="https://dc.f5stud.io"><img src="https://img.shields.io/discord/1396957541530865927?label=discord&style=for-the-badge&color=5865F2&labelColor=16161d" alt="Discord" /></a>

<br /><br />

<img src="https://img.shields.io/badge/QBCore-supported-f5a623?style=flat-square&labelColor=16161d" alt="QBCore" />&nbsp;
<img src="https://img.shields.io/badge/QBox_Core-supported-f5a623?style=flat-square&labelColor=16161d" alt="QBox" />&nbsp;
<img src="https://img.shields.io/badge/ESX-supported-f5a623?style=flat-square&labelColor=16161d" alt="ESX" />&nbsp;
<img src="https://img.shields.io/badge/framework-auto--detected-white?style=flat-square&labelColor=16161d" alt="Auto-detected" />

<br /><br />

The most advanced open-source safezone system for FiveM.<br />
Drop it in, ensure, and play. No config needed, no SQL, no Keymaster.

<br />

[**Read the Docs**](https://docs.f5stud.io/docs/f5-safezones/installation) &nbsp;&nbsp;&middot;&nbsp;&nbsp; [**Join Discord**](https://dc.f5stud.io) &nbsp;&nbsp;&middot;&nbsp;&nbsp; [**Report a Bug**](https://github.com/F5StudioFiveM/f5_safezones/issues)

</div>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>Why F5 Safezones?</h2>
</div>

<br />

<table align="center">
<tr>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Zone_Creators-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>Fly around and draw <b>polygon</b> or <b>circle</b> zones directly in-game. Place points, adjust radius, and preview markers without leaving the server.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Admin_Panel-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>Full NUI interface with an <b>interactive map</b>, zone management, player monitoring, audit logs, and debug tools. Comes with three map layers.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Ghosting_&_Protection-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>Vehicle and player <b>ghosting</b>, invincibility, explosion cancellation, weapon restrictions, and vehicle damage prevention. All configurable per zone.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Zero_Config-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub><b>Auto-detects</b> your framework at startup. No SQL needed, no manual setup. All data is stored in JSON. Just drop it in and <code>ensure</code>.</sub>
<br /><br />
</td>
</tr>
</table>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>Quick Start</h2>
</div>

<br />

```bash
cd resources/[f5]
git clone https://github.com/F5StudioFiveM/f5_safezones.git
```

Add to `server.cfg`:

```cfg
ensure qb-core    # or qbx_core / es_extended
ensure f5_safezones
```

> **That's it.** The default Legion Square safezone is ready. Open `/szadmin` in-game to manage zones.

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>At a Glance</h2>
</div>

<br />

<div align="center">

| | |
|:---|:---|
| **Zone Types** | Circle &nbsp;&bull;&nbsp; Polygon |
| **Markers** | Cylinder &nbsp;&bull;&nbsp; Circle Fat &nbsp;&bull;&nbsp; Circle Skinny &nbsp;&bull;&nbsp; Circle Arrow &nbsp;&bull;&nbsp; Split Arrow &nbsp;&bull;&nbsp; Dome |
| **Animations** | Pulsing &nbsp;&bull;&nbsp; Bobbing &nbsp;&bull;&nbsp; Rotating &nbsp;&bull;&nbsp; Color Shift |
| **Protection** | Invincibility &nbsp;&bull;&nbsp; Ghosting &nbsp;&bull;&nbsp; Explosion Cancel &nbsp;&bull;&nbsp; Weapon Block &nbsp;&bull;&nbsp; Vehicle Damage Block |
| **Frameworks** | QBCore &nbsp;&bull;&nbsp; QBox Core &nbsp;&bull;&nbsp; ESX (auto-detected via bridge) |
| **Storage** | JSON files, no database required |
| **Logging** | NDJSON audit logs with retention and admin tracking |
| **Requirements** | Server Build 4752+ &nbsp;&bull;&nbsp; Game Build 2189+ &nbsp;&bull;&nbsp; Lua 5.4 |

</div>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<details>
<summary><b>Available Exports</b></summary>

<br />

**Client**

```lua
exports['f5_safezones']:IsPlayerInSafezone()
exports['f5_safezones']:GetCurrentSafezone()
exports['f5_safezones']:GetAllZones()
exports['f5_safezones']:IsPlayerInGhostMode()
exports['f5_safezones']:GetPlayersInCurrentZone()
```

**Server**

```lua
exports['f5_safezones']:IsPlayerInSafezone(source)
exports['f5_safezones']:GetPlayerSafezoneInfo(source)
exports['f5_safezones']:GetAllPlayersInSafezones()
exports['f5_safezones']:GetAllSafezones()
exports['f5_safezones']:GetPlayersInSpecificZone(zoneName)
```

[See full API reference &rarr;](https://docs.f5stud.io/docs/f5-safezones/exports-events)

</details>

<details>
<summary><b>Admin Commands</b></summary>

<br />

| Command | Description |
|:---|:---|
| `/szadmin` | Open the admin panel |
| `/szdebug` | Toggle debug visualization |
| `/szcoords` | Copy current coordinates |
| `/sztoggle <zone>` | Toggle marker visibility |
| `/listsafezones` | List all zones in console |

</details>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>Contributing</h2>
</div>

<br />

This project is open source and we'd love your help to make it better.

- **Report bugs** by opening an [issue](https://github.com/F5StudioFiveM/f5_safezones/issues)
- **Suggest features** or improvements via [issues](https://github.com/F5StudioFiveM/f5_safezones/issues) or [Discord](https://dc.f5stud.io)
- **Submit pull requests** with bug fixes, new features, or optimizations
- **Add translations** by creating a new locale file in the `locales/` folder
- **Share the project** by starring the repo and spreading the word

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">

<a href="https://docs.f5stud.io/docs/f5-safezones/installation"><img src="https://img.shields.io/badge/read_the_docs-docs.f5stud.io-f5a623?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Documentation" height="35" /></a>
&nbsp;&nbsp;
<a href="https://dc.f5stud.io"><img src="https://img.shields.io/badge/join-discord-5865F2?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Discord" height="35" /></a>
&nbsp;&nbsp;
<a href="https://f5stud.io"><img src="https://img.shields.io/badge/visit-f5stud.io-white?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Website" height="35" /></a>

<br /><br />

<sub>Open source and free forever. Made by <a href="https://f5stud.io"><b>F5 Studio</b></a></sub>

</div>
