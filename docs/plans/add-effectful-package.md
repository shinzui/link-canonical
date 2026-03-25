# Add effectful integration package for link-canonical

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

After this change, users of the effectful ecosystem can canonicalize URLs using effectful effects instead of the `HttpClient` typeclass from link-canonical. A user writes `runLinkCanonical $ normalizeLink config uri` inside an `Eff` computation and gets redirect resolution, tracking-parameter stripping, and domain-rule normalization — all managed through the effectful effect stack rather than a bare `IO` monad or a custom typeclass.

The user-visible outcome is a working `link-canonical-effectful` package that exposes a `LinkCanonical` effect, an `HttpHead` effect (for testability), an IO-based handler, and re-exports the core library's configuration and result types so consumers need only one import.


## Progress

- [x] Define the `HttpHead` dynamic effect in `src/Effectful/Link/Canonical/Http.hs` (2026-03-25)
- [x] Write the IO-based handler `runHttpHead` that delegates to http-client-tls (2026-03-25)
- [x] Define the `LinkCanonical` dynamic effect in `src/Effectful/Link/Canonical.hs` (2026-03-25)
- [x] Write the handler `runLinkCanonical` that interprets via `HttpHead` and the core library's pure normalization (2026-03-25)
- [x] Update `link-canonical-effectful.cabal` with dependencies, exposed modules, and test suite (2026-03-25)
- [x] Write tests in `test/` using a mock `HttpHead` handler (2026-03-25)
- [x] Verify `cabal build all` and `cabal test all` pass — 184 tests pass (179 core + 5 effectful) (2026-03-25)
- [x] Run `nix fmt` and verify formatting — 0 files changed (2026-03-25)


## Surprises & Discoveries

- The `HttpClient (Eff es)` bridge instance required `TypeFamilies` (for `type instance DispatchOf`) and `UndecidableInstances` (the constraint `HttpHead :> es` is not structurally smaller than the instance head `HttpClient (Eff es)`). These were added as default extensions in the `common` stanza.

- The `http-client` and `http-client-tls` packages were not needed as direct dependencies of `link-canonical-effectful` because `Core.newHttpClientIO` and `Core.runHttpClientIO` from `link-canonical` already handle the HTTP client creation and request execution internally.

- The orphan instance `HttpClient (Eff es)` produces a `-Worphans` warning. Suppressed with `{-# OPTIONS_GHC -Wno-orphans #-}` in `Http.hs` since this is the canonical home for the bridge.


## Decision Log

- Decision: Use dynamic dispatch for both `HttpHead` and `LinkCanonical` effects.
  Rationale: Dynamic dispatch allows users to swap in mock handlers for testing and to provide alternative HTTP backends. This mirrors the flexibility the core library's `HttpClient` typeclass already provides, and aligns with the effectful ecosystem convention for effects that wrap IO operations (e.g., `streaming-http-effectful`).
  Date: 2026-03-25

- Decision: Separate `HttpHead` from `LinkCanonical` as distinct effects.
  Rationale: The core library separates its HTTP abstraction (`HttpClient` typeclass in `Link.Canonical.Http`) from the normalization logic (`normalizeLink` in `Link.Canonical`). Maintaining this separation in the effectful layer means users can mock HTTP independently of normalization, and can reuse `HttpHead` for other HTTP-head-request use cases. It also makes tests cleaner: mock the HTTP layer, keep the real normalization logic.
  Date: 2026-03-25

- Decision: Do not use Template Haskell (`makeEffect`) for effect generation.
  Rationale: Both effects have only one or two operations each, so the boilerplate is minimal. Avoiding TH keeps compile times lower, removes the `effectful-th` dependency, and makes the code easier to read for newcomers.
  Date: 2026-03-25

- Decision: Re-export core types from the effectful module so consumers can use a single import.
  Rationale: Convenience. A user importing `Effectful.Link.Canonical` should have access to `NormConfig`, `NormResult`, `NormError`, `URI`, `mkURI`, and configuration defaults without a separate `import Link.Canonical`.
  Date: 2026-03-25


## Outcomes & Retrospective

Both milestones completed. The `link-canonical-effectful` package exposes two dynamic-dispatch effects (`HttpHead` and `LinkCanonical`), an IO-based handler, a bridge `HttpClient` instance, and re-exports core types. The test suite validates YouTube canonicalization, tracking-parameter stripping, redirect following, the `normalizeWithDefaults` convenience API, and error propagation — all through mock HTTP handlers with no network access.

`cabal build all` passes with zero warnings. `cabal test all` passes all 184 tests (179 core + 5 effectful). `nix fmt` reports zero formatting changes.


## Context and Orientation

The repository at the root of this working tree is a multi-package Haskell project. Two Cabal packages live side-by-side:

- `link-canonical/` — the core library for URL canonicalization. It exposes a three-layer API: a pure normalizer (`normalizeUri`), a redirect-following normalizer (`normalizeLink`), and a convenience wrapper (`normalizeWithDefaults`). The redirect-following layer is polymorphic in any monad `m` satisfying the `HttpClient m` typeclass defined in `link-canonical/src/Link/Canonical/Http.hs`. That typeclass has a single method, `headRequest :: URI -> m (Either HttpClientError HttpResponse)`.

- `link-canonical-effectful/` — a skeleton package with a `.cabal` file but no source files yet. Its purpose is to provide effectful effects and handlers for the core library.

The `cabal.project` file at the repository root lists both packages. The Nix flake provides a development shell with GHC 9.12 and Cabal.

The effectful library (source at `/Users/shinzui/Keikaku/hub/haskell/effectful-project/`) is an algebraic effect system for Haskell. Effects are GADTs whose constructors represent operations. Each effect has a dispatch type (static or dynamic). Dynamic dispatch uses `interpret` to provide a handler; operations are invoked with `send`. The key imports are:

- `Effectful` — re-exports `Eff`, `IOE`, `(:>)`, `runEff`, etc.
- `Effectful.Dispatch.Dynamic` — `interpret`, `send`, `reinterpret`, `localSeqUnliftIO`, etc.

The module naming convention for effectful integrations is `Effectful.<Domain>`. For example, `Effectful.Time`, `Effectful.Network.Http`.

Key files in the core library that the effectful package will depend on:

- `link-canonical/src/Link/Canonical.hs` — public API entry point; exports `normalizeLink`, `normalizeWithDefaults`, configuration types, result types, error types, and HTTP types.
- `link-canonical/src/Link/Canonical/Http.hs` — defines `HttpClient` typeclass (one method: `headRequest`), `HttpResponse`, `HttpClientIO`, and `newHttpClientIO`.
- `link-canonical/src/Link/Canonical/Error.hs` — defines `NormError`, `RedirectError`, `HttpClientError`.
- `link-canonical/src/Link/Canonical/Types.hs` — defines `NormConfig`, `NormResult`, `NormTrace`, `RedirectConfig`, `TrackingConfig`, `TrailingSlash`.
- `link-canonical/src/Link/Canonical/Config.hs` — defines `defaultConfig`, `defaultRedirectConfig`, `defaultTrackingConfig`, `defaultTrackingParams`.
- `link-canonical/src/Link/Canonical/Redirect.hs` — defines `resolveFinalUriWithChain` which is polymorphic in `HttpClient m`.
- `link-canonical/src/Link/Canonical/Normalize.hs` — defines `normalizeUri` and `normalizeUriWithTrace` (pure functions).
- `link-canonical/src/Link/Canonical/Rules.hs` — defines `defaultDomainRules`.

The core library's `normalizeLink` function has this signature:

    normalizeLink :: (HttpClient m) => NormConfig -> URI -> m (Either NormError NormResult)

It calls `resolveFinalUriWithChain` (which calls `headRequest` from the `HttpClient` typeclass) and then applies pure normalization. The effectful integration needs to provide an `HttpClient` instance for `Eff es` so that `normalizeLink` can be called inside an effectful computation.


## Plan of Work

The work is divided into two milestones. The first creates the effect definitions and IO handler so the package compiles and can canonicalize URLs. The second adds tests with a mock HTTP handler.


### Milestone 1: Effect definitions and IO handler

At the end of this milestone, the `link-canonical-effectful` package compiles, exposes two effects (`HttpHead` and `LinkCanonical`), and provides IO-based handlers. A user can write:

    import Effectful
    import Effectful.Link.Canonical

    main :: IO ()
    main = runEff . runHttpHead . runLinkCanonical $ do
      let Right uri = mkURI "https://youtu.be/dQw4w9WgXcQ?utm_source=share"
      result <- normalizeLink defaultConfig uri
      liftIO $ print result

Acceptance: `cabal build all` succeeds with no errors and no `-Wunused-packages` warnings.

There are three files to create and one to update.

**File 1: `link-canonical-effectful/src/Effectful/Link/Canonical/Http.hs`**

This module defines the `HttpHead` effect — a dynamic-dispatch effect with a single operation mirroring the core library's `HttpClient` typeclass. It also provides an IO handler and a bridge instance so the core library's `HttpClient` constraint is satisfied for `Eff es` when `HttpHead` is in the effect stack.

Define a GADT `HttpHead` with one constructor:

    data HttpHead :: Effect where
      HeadRequest :: URI -> HttpHead m (Either HttpClientError HttpResponse)

Set its dispatch to dynamic:

    type instance DispatchOf HttpHead = Dynamic

Provide the operation function:

    headRequest :: (HttpHead :> es) => URI -> Eff es (Either HttpClientError HttpResponse)
    headRequest = send . HeadRequest

Provide the IO-based handler. It creates an `HttpClientIO` (TLS manager) on initialization and delegates each `HeadRequest` to `runHttpClientIO`:

    runHttpHead :: (IOE :> es) => Eff (HttpHead : es) a -> Eff es a
    runHttpHead action = do
      client <- newHttpClientIO
      interpret (\_ -> \case
        HeadRequest uri -> liftIO $ runHttpClientIO client uri
        ) action

Provide an `HttpClient` instance for `Eff es` when `HttpHead :> es`:

    instance (HttpHead :> es) => HttpClient (Eff es) where
      headRequest = Effectful.Link.Canonical.Http.headRequest

This instance is the bridge that lets the core library's `normalizeLink` (which requires `HttpClient m`) run inside `Eff es`.

**File 2: `link-canonical-effectful/src/Effectful/Link/Canonical.hs`**

This is the main module users import. It defines the `LinkCanonical` effect for URL normalization, provides a handler, and re-exports core types.

Define a GADT `LinkCanonical` with two operations corresponding to the core library's two IO-dependent functions:

    data LinkCanonical :: Effect where
      NormalizeLink :: NormConfig -> URI -> LinkCanonical m (Either NormError NormResult)
      NormalizeWithDefaults :: URI -> LinkCanonical m (Either NormError URI)

Set dispatch to dynamic:

    type instance DispatchOf LinkCanonical = Dynamic

Provide operation functions:

    normalizeLink :: (LinkCanonical :> es) => NormConfig -> URI -> Eff es (Either NormError NormResult)
    normalizeLink config uri = send $ NormalizeLink config uri

    normalizeWithDefaults :: (LinkCanonical :> es) => URI -> Eff es (Either NormError URI)
    normalizeWithDefaults = send . NormalizeWithDefaults

Provide the handler. It interprets `LinkCanonical` by delegating to the core library's functions. Because those core functions require `HttpClient m`, the handler needs `HttpHead :> es` in its constraint:

    runLinkCanonical :: (HttpHead :> es) => Eff (LinkCanonical : es) a -> Eff es a
    runLinkCanonical = interpret $ \_ -> \case
      NormalizeLink config uri -> Core.normalizeLink config uri
      NormalizeWithDefaults uri -> Core.normalizeWithDefaults uri

Here `Core` is a qualified import of `Link.Canonical`.

Re-export from this module: `NormConfig(..)`, `NormResult(..)`, `NormError(..)`, `RedirectError(..)`, `HttpClientError(..)`, `RedirectConfig(..)`, `TrackingConfig(..)`, `TrailingSlash(..)`, `DomainRule(..)`, `NormHooks(..)`, `defaultConfig`, `defaultRedirectConfig`, `defaultTrackingConfig`, `defaultTrackingParams`, `defaultDomainRules`, `normalizeUri`, `URI`, `mkURI`.

Also re-export `HttpHead`, `runHttpHead`, and `headRequest` from the Http module.

**File 3: Update `link-canonical-effectful/link-canonical-effectful.cabal`**

Add the following build-depends to the library stanza (in addition to the existing `base` and `link-canonical`):

    effectful-core >= 2.5 && < 2.6
    http-client >= 0.7 && < 0.8
    http-client-tls >= 0.3 && < 0.4
    modern-uri >= 0.3 && < 0.4
    text >= 2.0 && < 2.2

Add exposed modules:

    exposed-modules:
      Effectful.Link.Canonical
      Effectful.Link.Canonical.Http

The `effectful-core` package (not `effectful`) is the right dependency because we only need the core effect machinery, not the full batteries-included package.


### Milestone 2: Test suite with mock HTTP handler

At the end of this milestone, a test suite exercises URL normalization through the effectful layer using a mock HTTP handler that returns canned redirect responses. This proves the effects compose correctly and the bridge instance works.

Acceptance: `cabal test all` passes, including the new `link-canonical-effectful-test` test suite.

**File 4: `link-canonical-effectful/test/Main.hs`**

Create a test module using Tasty and HUnit. Define a mock HTTP handler:

    runMockHttpHead :: Map URI HttpResponse -> Eff (HttpHead : es) a -> Eff es a
    runMockHttpHead responses = interpret $ \_ -> \case
      HeadRequest uri -> pure $ case Map.lookup uri responses of
        Just resp -> Right resp
        Nothing -> Left (ConnectionError "Mock: unknown URI")

Write test cases:

1. **Pure normalization via effect**: Call `normalizeLink` with an empty redirect map (URI returns 200 OK directly). Verify the canonical URL has tracking params stripped and domain rules applied.

2. **Redirect following**: Set up a mock map where URI A redirects to URI B (3xx with Location header), and URI B returns 200. Verify `normalizeLink` follows the redirect and returns the normalized form of URI B.

3. **Error propagation**: Mock a URI that returns a connection error. Verify the effect returns `Left (RedirectError (ConnectionFailed ...))`.

**Update cabal file** to add the test suite stanza:

    test-suite link-canonical-effectful-test
      import: common
      type: exitcode-stdio-1.0
      hs-source-dirs: test
      main-is: Main.hs
      build-depends:
        base >= 4.18 && < 5,
        containers >= 0.6 && < 0.8,
        effectful-core >= 2.5 && < 2.6,
        link-canonical,
        link-canonical-effectful,
        modern-uri >= 0.3 && < 0.4,
        tasty >= 1.4 && < 1.6,
        tasty-hunit >= 0.10 && < 0.11,
        http-types >= 0.12 && < 0.13,
        text >= 2.0 && < 2.2,


## Concrete Steps

All commands are run from the repository root: `/Users/shinzui/Keikaku/bokuno/link-canonical-project/link-canonical/`.

**Step 1**: Create directory structure.

    mkdir -p link-canonical-effectful/src/Effectful/Link/Canonical
    mkdir -p link-canonical-effectful/test

**Step 2**: Create `link-canonical-effectful/src/Effectful/Link/Canonical/Http.hs` with the `HttpHead` effect, `runHttpHead` handler, `headRequest` operation, and `HttpClient (Eff es)` instance. (See File 1 in Plan of Work.)

**Step 3**: Create `link-canonical-effectful/src/Effectful/Link/Canonical.hs` with the `LinkCanonical` effect, `runLinkCanonical` handler, operation functions, and re-exports. (See File 2 in Plan of Work.)

**Step 4**: Update `link-canonical-effectful/link-canonical-effectful.cabal` to add dependencies, exposed modules, and test suite. (See File 3 and cabal update in Plan of Work.)

**Step 5**: Build to verify compilation.

    cabal build all

Expected: builds successfully with no errors.

**Step 6**: Create `link-canonical-effectful/test/Main.hs` with mock handler and test cases. (See File 4 in Plan of Work.)

**Step 7**: Run tests.

    cabal test all

Expected: all tests pass, including the new `link-canonical-effectful-test` suite.

**Step 8**: Format.

    nix fmt

Expected: no changes (code was written following fourmolu conventions) or minor whitespace fixes applied.


## Validation and Acceptance

**Compilation test**: `cabal build all` must succeed with no errors and no `-Wunused-packages` warnings. This proves the dependency list is correct and the modules are well-formed.

**Unit tests**: `cabal test all` must pass all suites. The effectful test suite must contain at minimum:

1. A test that normalizes a YouTube short URL (`https://youtu.be/dQw4w9WgXcQ`) through the effect stack with a mock 200 response and verifies the canonical form is `https://www.youtube.com/watch?v=dQw4w9WgXcQ`.

2. A test that normalizes a URL with tracking parameters (`?utm_source=share&utm_medium=social`) and verifies they are stripped.

3. A test that follows a mock redirect chain (A -> B, where A returns 301 with Location: B, and B returns 200) and verifies the result uses B's normalized form.

4. A test that verifies error propagation when the mock returns a connection error.

**Formatting**: `nix fmt` produces no changes on the final code, confirming it meets project formatting standards.


## Idempotence and Recovery

All steps are safe to repeat. Creating files overwrites any previous attempt. `cabal build all` is idempotent. If a build fails, read the error, fix the source, and re-run `cabal build all`. The mock-based tests have no external dependencies and produce deterministic results.

If the `HttpClient (Eff es)` orphan instance causes issues (e.g., overlapping instances), the fallback is to avoid the instance entirely and instead have `runLinkCanonical` call `resolveFinalUriWithChain` and `normalizeUriWithTrace` directly, bypassing the typeclass. This would require importing those internal functions from the core library.


## Interfaces and Dependencies

**Haskell packages used by link-canonical-effectful:**

- `effectful-core` (>= 2.5, < 2.6) — provides `Eff`, `Effect`, `IOE`, `(:>)`, `interpret`, `send`, `DispatchOf`, `Dynamic`, `liftIO`, `runEff`. This is the minimal effectful dependency without batteries.
- `link-canonical` — the core library. Provides all types, configuration, normalization, redirect resolution, and the `HttpClient` typeclass.
- `http-client` (>= 0.7, < 0.8) — needed by the IO handler for `HC.Manager`.
- `http-client-tls` (>= 0.3, < 0.4) — needed by the IO handler for `newTlsManager`.
- `modern-uri` (>= 0.3, < 0.4) — provides `URI` and `mkURI`, needed in type signatures.
- `text` (>= 2.0, < 2.2) — needed for `Text` type used in errors and parameters.
- `base` (>= 4.18, < 5) — standard library.

**Test-only packages:**

- `tasty` (>= 1.4, < 1.6) — test framework.
- `tasty-hunit` (>= 0.10, < 0.11) — HUnit integration for Tasty.
- `containers` (>= 0.6, < 0.8) — `Data.Map` for mock response lookup.
- `http-types` (>= 0.12, < 0.13) — HTTP status codes for mock responses.

**Types and interfaces that must exist after Milestone 1:**

In `Effectful.Link.Canonical.Http`:

    data HttpHead :: Effect where
      HeadRequest :: URI -> HttpHead m (Either HttpClientError HttpResponse)

    type instance DispatchOf HttpHead = Dynamic

    headRequest :: (HttpHead :> es) => URI -> Eff es (Either HttpClientError HttpResponse)

    runHttpHead :: (IOE :> es) => Eff (HttpHead : es) a -> Eff es a

    instance (HttpHead :> es) => HttpClient (Eff es)

In `Effectful.Link.Canonical`:

    data LinkCanonical :: Effect where
      NormalizeLink :: NormConfig -> URI -> LinkCanonical m (Either NormError NormResult)
      NormalizeWithDefaults :: URI -> LinkCanonical m (Either NormError URI)

    type instance DispatchOf LinkCanonical = Dynamic

    normalizeLink :: (LinkCanonical :> es) => NormConfig -> URI -> Eff es (Either NormError NormResult)
    normalizeWithDefaults :: (LinkCanonical :> es) => URI -> Eff es (Either NormError URI)

    runLinkCanonical :: (HttpHead :> es) => Eff (LinkCanonical : es) a -> Eff es a
