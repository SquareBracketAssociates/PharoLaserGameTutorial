(TeX-add-style-hook "book.latex"
 (lambda ()
    (LaTeX-add-bibliographies
     "scg")
    (TeX-add-symbols
     "wholebook")
    (TeX-run-style-hooks
     "geometry"
     "9.21in}"
     ".75in}"
     "1in}"
     "ignoreheadfoot"
     "latex2e"
     "bk10"
     "book"
     "a4paper"
     "10pt"
     "twoside"
     "common")))

