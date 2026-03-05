Rollout (a simple static site generator)
========

!!! Experimental !!!

A pipeline based static "site" generator focused on allowing flexible generation. Fundamentally, this project is simple and only enforces a simple set of rules, filesystem structures, and a small subset of exposed environment variables.

Reasoning
---------

I write my entire life in markdown, and things that aren't in markdown get generators to turn them into markdown for my own consumption. While some static site generators have a common markdown backend I found that often the generated code was hard to pipeline into other outputs, such as Gopher. 

Additionally, my CI of choice is Laminar-CI which takes the opinionated stance of "just use job shell scripts". I found this rather freeing from implementation specific DSLs or janky non-reproducible web interface configuration management.

I wanted something that allowed me to write a simple step-by-step sychronous pipeline using POSIX.1-2008 shell scripts and allow me to write the pipeline steps in any language I felt like programming in.

Versions
--------

Rollout contains 2 supported versions:

* `rollout.sh` - A POSIX.1-2008 shell script that contains all the logic for building a site
* `rollout.go` - The Go implementation that is used for more programmatic logic, will eventually contain an extention to load Go plugins

Example Structure
-----------------

The only directories that are fundamental to the creation of a "site" is the `site` directory which contains the initial format of the site and the functions (`stages`) directory that contains the staged pipeline pieces of code. It is also highly suggested to create a `util` directory that contains executables or scripts used during pipelining.

My personal project root looks like this (directories marked with `<` are required for the generator to work by default):

```
.
|-- README.md
|-- rollout.go
|-- rollout.sh
|-- build/
|-- stages/	<
|-- site/	<
|-- tmpl/
`-- util/	<
```

```
.
|-- build/
|   |-- 1772409060/
|   |-- 1772409114/
|   `-- latest@ -> 1772409114
|-- stages/
|   |-- 00-depends.sh*
|   |-- 01-posts.sh*
|   |-- 01-projects.sh*
|   |-- 02-http.sh*
|   |-- 03-removemd.sh*
|   |-- 04-minify.sh*
|   |-- 05-rss.sh*
|   `-- scripts/
|       `-- clean.sh*
|-- site/
|   |-- 0.md
|   |-- 403.md
|   |-- 404.md
|   |-- 50x.md
|   |-- about.md
|   |-- index.md
|   |-- security.md
|   |-- style.css
|   |-- ~/
|   |-- i/
|   |   |-- dasho.png
|   |   `-- favicon.png
|   `-- p/
|       |-- 0x00-hello-world.md
|       |-- 0x01-count-of-monte-cristo.md
|       |-- 0x02-git-servers.md
|       `-- index.md
|-- tmpl/
|   |-- footer.html
|   |-- header.html
|   |-- meta.html
|   `-- style.css
`-- util/
    |-- file.go
    |-- mdtohtml*
    `-- minify*

``` 

Exposed Variables
-----------------

The following variables are exposed to all running stage executables/scripts and to any generator scripts:

* `_ORIGIN` - The origin directory that is `pwd`
* `_SITEDIR` - Contains all the site files. In my case I use a bunch of .md files and assets that get built
* `_BUILDROOT` - The `build` directory that contains all the build runs and a symlink (`$_BUILDROOT/latest`) to the last build
* `_BUILDID` - The current running build ID, by default uses UNIX timestamps
* `_BUILDDIR` - The current running build and build ID in absolute path form
* `_STAGEDIR` - Directory containing the stage scripts or executables
* `_SCRIPTDIR` - Directory containing scripts that are used for "out-of-build" site management (for example, `clean.sh` cleans my build dirs)
* `_UTILDIR` - Utilities that are required for building are expected to be built into this directory
* `_PRODDIR` - The current "production" build. The idea is that this can contain the code that is committed to CI and all tests and deployments can be run without pulling in all the `rollout` repo

Demo
----

The demo that is in the default repository requires two projects to either be in `$PATH` or to be in the `util` directory:

* https://github.com/gomarkdown/mdtohtml
* https://github.com/tdewolff/minify

Once those binaries are setup simply:

```
go run rollout.go
```

and check `build/latest`
