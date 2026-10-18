using Documenter
using Documenter: Remotes

using ObibaOpal

makedocs(;
    modules=[ObibaOpal],
    authors="Hugo Solleder <hugo.solleder@epfl.ch> and contributors",
    repo=Remotes.GitHub("obiba", "ObibaOpal.jl"),
    sitename="ObibaOpal.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://obiba.github.io/ObibaOpal.jl",
        assets=String[],
    ),
    warnonly=[:missing_docs],
    pages=["Home" => "index.md", "API Reference" => "api.md"],
)

deploydocs(; repo="github.com/obiba/ObibaOpal.jl", devbranch="main")
