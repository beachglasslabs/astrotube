# beachdemo astro - netflix clone in ![zig](https://ziglang.org/img/zig-logo-dynamic.svg)

This is based on [beachdemo.zig](https://github.com/beachglasslabs/beachdemo.zig) with the addition of [Astro](https://astro.build) for template composition.

![login](https://raw.githubusercontent.com/beachglasslabs/beachdemo.zig/master/screenshots/beachdemo-login.jpg)
![main](https://raw.githubusercontent.com/beachglasslabs/beachdemo.zig/master/screenshots/beachdemo-screen.jpg)

This particular project is written in ZAAX (Zig/Zap Astro Alpinejs htmX :stuck_out_tongue_winking_eye:):

To test it out:
 1. `git clone git@github.com:beachglasslabs/beachdemo-astro.zig.git`
 2. `npm install` to install npm packages
 3. `cp env.oauth.sample.json env.oauth.json` and then optionally fill out the oauth2 information from [github](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps) and [google](https://developers.google.com/identity/protocols/oauth2)
 4. `npm run dev` to start the server
 5. go to [http://localhost:3000](http://localhost:3000) on your browser
