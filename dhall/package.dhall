{-|
These is a rough set of available operations. The actual implementations may be duplicated on multiple more specific types. This splits out the cases that have distinct result types (usually because one may fail).

- `anchor` – realize the types in the path
  - `Path/anchor: Path → < AbsDir : Directory/Absolute | AbsFile : File/Absolute | RelDir : Directory/Relative | RelFile : File/Relative >`
  - `Path/Ambiguous/anchor: Path/Ambiguous → < Abs : Path/Absolute/Ambiguous | Rel : Path/Relative/Ambiguous >`
- `ascend` – move up one level in the file hierarchy
  - `Directory/Absolute/ascend : Directory/Absolute → Optional (Directory/Absolute)`
  - `Directory/Relative/ascend : Directory/Relative → Directory/Relative`
- `basename : File anchor → Text` – get the name of the file referred to by the path
- `concat` – resolve a path relative to another one
  - `Directory/Absolute/concat : Directory anchor → Path/Relative type → Optional (Path/Anchored anchor type)`
  - `Directory/Relative/concat : Directory anchor → Path/Relative type → Path/Anchored anchor type`
- `containing : Path/Ambiguous anchor → Directory anchor` – find the containing directory for an ambiguous path
- `current : Directory/Relative` – the current directory, the starting point for building relative paths
- `descendThrough : Directory anchor → List Text → Directory anchor` – move multiple directories deeper in the file system
- `descendTo : Directory anchor → Text → Directory anchor` – like `descendThrough`, but for a single directory
- `directory : File anchor → Directory anchor` – find the directory containing the file
- `encapsulate : Directory/Absolute → Path/Relative type → Optional (Path/Relative type)` – sandboxes paths
- `forget` – forget whether a path is a file or a directory (making a path an ambiguous path)
  - `Directory/forget : Directory anchor → Optional (Path/Anchored/Ambiguous anchor)`
  - `File/forget : File anchor → Path/Anchored/Ambiguous anchor`
- `isCurrent` - identify whether the directory is the current directory
- `isRoot` - identify whether the directory is the root directory
- `reparent : Path[/Ambiguous]/Relative type → Path[/Ambiguous]/Relative type` – shift the directory one level higher in the file system
- `reparentBy : Path[/Ambiguous]/Relative type → Natural → Path[/Ambiguous]/Relative type` – shift the directory some number of levels higher in the file system
- `root : Directory/Absolute` – the root directory, the starting point for building absolute paths
- `route` – find a path from the first path to the second
  - `Path/Absolute/route : Directory/Absolute → Path/Absolute type → Path/Relative type`
  - `Path/Relative/route : Directory/Relative → Path/Relative type → Optional (Path/Relative type)`
- `selectFile : Directory anchor → Text → File anchor`
- `toText : Format → Path/[Ambiguous/]Any → Text` – serialize the path (formatted for specific systems)
- `unanchor` – generalize the type, for interfaces
  - `Path/unanchor : Path anchor type → Path/Any`
  - `Path/Ambiguous/unanchor : Path/Ambiguous anchor → Path/Ambiguous/Any`
-}
let Prelude =
      https://prelude.dhall-lang.org/v20.1.0/package.dhall
        sha256:26b0ef498663d269e4dc6a82b0ee289ec565d683ef4c00d0ebdd25333a5a3c98

let p =
      { Directory = ./Directory/package.dhall
      , File = ./File/package.dhall
      , Path = ./Path/package.dhall
      }

let D = p.Directory

let F = p.File

let P = p.Path

let exampleAbsDir =
      D.descendThrough P.Anc.Abs D.root [ "usr", "share", "emacs" ]

let --| Display a simple path.
    simplePathConstruction =
        assert
      : D.Absolute.toText P.Format.POSIX exampleAbsDir ≡ "/usr/share/emacs/"

let --| If it’s “ambiguous”, can’t show a trailing slash.
    ambiguousPathsNeverHaveTrailingSlash =
        assert
      :   Prelude.Optional.map
            P.Ambiguous.Absolute.Type
            Text
            (P.Ambiguous.Absolute.toText P.Format.POSIX)
            (D.forget P.Anc.Abs exampleAbsDir)
        ≡ Some "/usr/share/emacs"

let --| You can move up the file hierarchy.
    reparentedFilePath =
        assert
      :   F.Relative.toText
            P.Format.POSIX
            ( D.selectFile
                P.Anc.Rel
                ( D.descendThrough
                    P.Anc.Rel
                    (D.Relative.ascend D.current)
                    [ ".config", "ssh" ]
                )
                "id_rsa.pub"
            )
        ≡ "../.config/ssh/id_rsa.pub"

let --| Windows style paths are also supported.
    simplePathConstruction =
        assert
      :   D.Absolute.toText (P.Format.Windows (Some "C:")) exampleAbsDir
        ≡ "C:\\usr\\share\\emacs\\"

let ambiguousPathsNeverHaveTrailingSlash =
        assert
      :   Prelude.Optional.map
            P.Ambiguous.Absolute.Type
            Text
            (P.Ambiguous.Absolute.toText (P.Format.Windows (None Text)))
            (D.forget P.Anc.Abs exampleAbsDir)
        ≡ Some "\\usr\\share\\emacs"

let reparentedFilePath =
        assert
      :   F.Relative.toText
            (P.Format.Windows (None Text))
            ( D.selectFile
                P.Anc.Rel
                ( D.descendThrough
                    P.Anc.Rel
                    (D.Relative.ascend D.current)
                    [ ".config", "ssh" ]
                )
                "id_rsa.pub"
            )
        ≡ "..\\.config\\ssh\\id_rsa.pub"

in  p
