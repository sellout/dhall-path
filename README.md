# Paths (for Dhall)

[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fdhall-path)](https://garnix.io)

Well-typed path manipulation for Dhall

A path library for Dhall, with various type-level guarantees.

```dhall
  let emacsDir =
        Dir.descendThrough Anchor.Abs Dir.root [ "usr", "share", "emacs" ]
  in  Dir.Absolute.toText Path.Format.POSIX emacsDir
≡ "/usr/share/emacs/"
```

This library offers two primary path types

- `Path < Abs | Rel > < Dir | File >` and
- `Path/Ambiguous < Abs | Rel >`.

`Path` takes two type parameters, one indicating whether the path is absolute or relative (`Path/Anc`) and one indicating whether it’s a file or directory (`Path/Typ`). The latter only takes the `Path/Anc` parameter. Ambiguous paths can’t know whether they represent a file or directory. However, some operations (like `containing`) can bridge to non-ambiguous paths (since we know that regardless of what an ambiguous path represents, its containing path _must_ be a directory).

There are two other path representations, corresponding to the two above,

- `Path/Any` and
- `Path/Ambiguous/Any`.

These are structured the same as the primary ones, but don’t carry type information around. They’re mostly intended for interfacing with systems that don’t make those distinctions (for example, in Nix, basically all uses of paths accept any of the four possible `Path` structures, so it’s simpler to expose a single type covering all of them than a union of the distinct types). However, these are also used internally to simplify things like `toText`.

The stronger types of `Path` and `Path/Ambiguous` can always be recovered from the corresponding unanchored path type ([`Path/anchor`](./dhall/Path/anchor)), so operations are _only_ provided on “anchored” types, with the expectation of converting the type at interface boundaries as necessary.

There are also aliases for full and partial applications of `Path/Anchored`. Operations are defined for the most specific types possible, for example, `Directory/Absolute/isRoot`, not `Directory/isRoot` or `Path/isRoot`. Sometimes (like `isRoot`), this is because the function is undecidable in other cases. Without access to the file system, we can’t determine whether “../../../” is the root directory or not.

This type DAG[^1] not only shows all the aliases, but lists some operations (the labeled, dotted edges) that move between otherwise unconnected types. This isn’t a full diagram of the operations on paths, or even the subset of unary operations.

![type diagram](./type-diagram.png)

The only failure cases in this library is when some relative path has too much re-parenting (“../”) relative to some other path such that the operation is impossible. This is represented by a `None` result.

## documentation

API docs are on [GitHub Pages](https://sellout.github.io/dhall-path).

The [`package.dhall`](https://sellout.github.io/dhall-path/package.dhall.html) modules have high level docs and examples

## future ideas

### distinguish re-parented paths from relative paths?

This could reduce the scope of some failures. It’s also possible that some systems can’t directly express re-parenting, and they would be able to distinguish that at the type level.

## internals

Structurally, paths look like

```dhall
λ(ancType : Type) →
λ(typType : Type) →
  { --| If the path is relative, this is the number of levels up the
    --  hierarchy to move before descending into the directories (i.e.,
    --  “../”).
    parents : ancType
  , --| The directory components of the path in reverse order.
    directories : List Text
  , --| If the path represents a file, the name of the file.
    file : typeType
  }
```

with one minor variation – `Ambiguous` paths call `file` `component` (because the ambiguity is that we don’t know whether that component represents a directory name or a file name).

The `directories` are stored in reverse order, to make the common operations of cons, tail, fold, etc. a bit more intuitive[^2]. `ancType` is `{}` for absolute paths, `Natural` for relative paths, and `Optional Natural` for un-anchored paths. Similarly, `typType` is `{}` for directories, `Text` for files, and `Optional Text` for un-anchored paths.

[^2]: **TODO**: Perhaps switch to a non-reverse ordering, since Dhall’s types are structural, the ordering is exposed, even if we try to prevent users from seeing it. Keeping it consistent would be good to avoid confusion.

## development environment

We recommend the following steps to make working in this repository as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.cache/git/config`

This will apply our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.

## building & development

Especially if you are unfamiliar with the Dhall ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

## comparisons

Other projects similar to this one, and how they differ.

### `path` & `pathy`

This library was inspired by the [Haskell](https://hackage.haskell.org/package/path) `path` library and the [PureScript](https://github.com/purescript-contrib/purescript-pathy) & [Scala](https://github.com/precog/scala-pathy) `pathy` libraries. However, it differs from them in several ways.

For one, it supports `../` (unlike Haskell’s `path`). Avoiding re-parenting does nothing to eliminate failure cases, it just shifts them to different places. Avoiding escaping some scope can be handled via a “chroot”-style approach, using `encapsulate`.

Being in Dhall, it can’t support parsing strings, so it can never convert `Text` to `Path`. Since they must be held in a structured format anyway (which is good, regardless), it means that there is no system-specific awareness outside of the `toText` operation.

It supports a notion of “ambiguous” paths that aren’t either directories or files. This is due to its need to act as an interface to arbitrary systems.

Since Dhall can’t compare strings, we can’t identify or remove common prefixes. The closest approximation is `route`, which removes a prefix by re-parenting.

This library has no special handling of extensions.
