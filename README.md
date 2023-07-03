# astrotube - youtube/netflix clone in ![zig](https://ziglang.org/img/zig-logo-dynamic.svg)

This is based on [Beachtube](https://github.com/beachglasslabs/beachtube) with the addition of [Astro](https;//astro.build) for the composition of templates.

![login](https://raw.githubusercontent.com/beachglasslabs/beachtube/master/screenshots/beachtube-login.jpg)
![main](https://raw.githubusercontent.com/beachglasslabs/beachtube/master/screenshots/beachtube-screen.jpg)

This particular project are written in ZAAX (Zig/Zap Astrojs Alpinejs htmX :stuck_out_tongue_winking_eye:):

To test it out:
 1. `git clone git@github.com:beachglasslabs/astrotube.git`
 2. `npm install` to install npm packages
 3. `cp env.oauth.sample.json env.oauth.json` and then optionally fill out the oauth2 information from [github](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps) and [google](https://developers.google.com/identity/protocols/oauth2)
 4. `npm run dev` to start the server
 5. go to [http://localhost:3000](http://localhost:3000) on your browser
