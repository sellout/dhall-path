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

let simplePathConstruction =
        assert
      : D.Absolute.toText P.Format.POSIX exampleAbsDir ≡ "/usr/share/emacs/"

let ambiguousPathsNeverHaveTrailingSlash =
        assert
      :   Prelude.Optional.map
            P.Ambiguous.Absolute.Type
            Text
            (P.Ambiguous.Absolute.toText P.Format.POSIX)
            (D.forget P.Anc.Abs exampleAbsDir)
        ≡ Some "/usr/share/emacs"

let reparentedFilePath =
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

let simplePathConstruction =
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
