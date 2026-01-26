# Implementation Roadmap

## High Priority

### Domain Rules

- [x] **YouTube** - `youtu.be`, embed, shorts → `youtube.com/watch?v=`
  - Canonical: `https://www.youtube.com/watch?v={VIDEO_ID}`
  - Variants: `youtu.be/{id}`, `youtube.com/embed/{id}`, `youtube.com/v/{id}`, `youtube.com/shorts/{id}`, `m.youtube.com`
  - Strip: `t`, `start`, `end`, `feature`, `list`, `index`, `si`
  - Implemented in `Link.Canonical.Rules.YouTube`

- [x] **Amazon** - `/gp/product/` → `/dp/{ASIN}`
  - Canonical: `https://www.amazon.{TLD}/dp/{ASIN}` (preserves regional TLD)
  - Variants: `/gp/product/{ASIN}`, `/{product-name}/dp/{ASIN}`, `smile.amazon.*`
  - Strip: `tag`, `ref`, `psc`, `keywords`, `qid`, `sr`, `th`, `linkCode`, `camp`, `creative`
  - Note: `amzn.to` short URLs require redirect resolution (handled by redirect phase)
  - Implemented in `Link.Canonical.Rules.Amazon`

- [x] **Twitter/X** - `twitter.com` → `x.com`
  - Canonical: `https://x.com/{user}/status/{id}`
  - Variants: `twitter.com`, `www.twitter.com`, `mobile.twitter.com`
  - Strips `/photo/N` and `/video/N` suffixes from status URLs
  - Strip: `s`, `t`, `ref_src`
  - Implemented in `Link.Canonical.Rules.Twitter`

- [x] **GitHub** - www stripping, preserve line fragments
  - Canonical: `https://github.com/{owner}/{repo}[/path]`
  - Preserve: `#L123`, `#L10-L20` line number fragments (exception to fragment stripping)
  - Strip: `tab`, `ref_src`, `ref_source`
  - Implemented in `Link.Canonical.Rules.GitHub`

- [x] **Instagram** - normalize to www
  - Canonical: `https://www.instagram.com/p/{POST_ID}/`, `/reel/{ID}/`, `/{username}/`
  - Variants: `instagram.com` → `www.instagram.com`
  - Strip: `igshid` (utm_* handled by global tracking)
  - Implemented in `Link.Canonical.Rules.Instagram`

- [x] **Reddit** - normalize subdomains
  - Canonical: `https://www.reddit.com/r/{subreddit}/comments/{id}/{slug}/`
  - Variants: `old.reddit.com`, `np.reddit.com` → `www.reddit.com`
  - Strip: `utm_*`, `ref`, `ref_source`
  - Implemented in `Link.Canonical.Rules.Reddit`

### Normalization

- [x] **Dot segment normalization** - RFC 3986 Section 5.2.4
  - Remove `.` and `..` segments from paths
  - Implemented in `Link.Canonical.Normalize.normalizeDotSegments`

- [x] **Percent-encoding normalization**
  - Uppercase hex digits: `%2f` → `%2F`
  - Decode unreserved characters: `%41` → `A`
  - Handled by modern-uri library during parsing

## Medium Priority

### Tracking Parameters

- [ ] Add missing default patterns:
  - `mc_*` (Mailchimp)
  - `oly_*` (Omeda)
  - `_ga`, `_gl` (Google Analytics)
  - `msclkid` (Microsoft Ads)
  - `dclid` (DoubleClick)
  - `zanpid` (Zanox)
  - `igshid` (Instagram)
  - `si` (Spotify)

### Testing

- [ ] Redirect resolution tests
- [ ] Domain rule tests (per rule)
- [ ] Edge case tests

## Lower Priority

- [ ] Empty query removal: `example.com?` → `example.com`
- [ ] LinkedIn domain rule
