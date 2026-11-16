# Telly privacy policy

_Last updated: 15 November 2026_

Telly is an open-source IPTV player for iPhone, iPad and Apple TV. It has **no
backend, no accounts and no analytics**.

## What Telly stores

- The playlist (M3U / Xtream Codes) and EPG (XMLTV) URLs you enter, the channels
  and guide data fetched from them, your favourites, watch history, My List and
  settings. All of this lives **only on your device**, in a local database.
- Your playlist and EPG configuration is also saved to your **iCloud Keychain**
  (Apple's end-to-end encrypted sync) so it survives a reinstall and follows you
  to your other devices. Telly never sees this data; Apple cannot read it either.

## What Telly sends

- Telly fetches your playlist, guide and streams **directly from the provider
  URLs you configure**. Those requests go from your device to your provider;
  Telly has no server in between and collects nothing.
- The built-in **demo playlist** streams Apple's public HLS reference streams and
  public sample clips. No identifying information is sent.

## What Telly does not do

- No tracking, no advertising identifiers, no crash reporting, no analytics.
- No data is sold or shared with anyone.

## Contact

Open an issue at <https://github.com/johnpc/telly-apple/issues>.
