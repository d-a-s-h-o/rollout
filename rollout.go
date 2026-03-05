package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"time"

	util "./util"
)

var builddir = "build"
var stagedir = "stages"
var scriptdir = stagedir + "/scripts"
var utildir = "util"
var proddir = "prod"
var sitedir = "site"
var origin string
var buildid string

type DirectoryEnv struct {
	Path     string
	Variable string
}

type RolloutBuild struct {
	BuildEnv []DirectoryEnv
	BuildRoot,
	BuildDir,
	StageDir,
	ScriptsDir,
	ProdDir,
	OriginDir,
	UtilDir,
	SiteDir,
	BuildId DirectoryEnv
}

func main() {
	origin, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
	}
	var build = RolloutBuild{
		OriginDir:  DirectoryEnv{Path: origin, Variable: "_ORIGIN"},
		BuildRoot:  DirectoryEnv{Path: origin + "/" + builddir, Variable: "_BUILDROOT"},
		BuildId:    DirectoryEnv{Path: strconv.FormatInt(int64(time.Now().Unix()), 10), Variable: "_BUILDID"},
		StageDir:   DirectoryEnv{Path: origin + "/" + stagedir, Variable: "_STAGEDIR"},
		ScriptsDir: DirectoryEnv{Path: origin + "/" + scriptdir, Variable: "_SCRIPTDIR"},
		UtilDir:    DirectoryEnv{Path: origin + "/" + utildir, Variable: "_UTILDIR"},
		ProdDir:    DirectoryEnv{Path: origin + "/" + proddir, Variable: "_PRODDIR"},
		SiteDir:    DirectoryEnv{Path: origin + "/" + sitedir, Variable: "_SITEDIR"},
	}
	build.BuildDir = DirectoryEnv{Path: build.BuildRoot.Path + "/" + build.BuildId.Path, Variable: "_BUILDDIR"}
	//TODO I should make function types for RolloutBuild and create a Add() and Remove() so that these can be tracked instead of this crap
	build.BuildEnv = append(build.BuildEnv, build.OriginDir, build.BuildRoot, build.BuildId, build.StageDir, build.ScriptsDir, build.UtilDir, build.ProdDir, build.SiteDir, build.BuildDir)

	if os.MkdirAll(build.BuildRoot.Path, 0755) != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	if os.MkdirAll(build.ProdDir.Path, 0755) != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println(build.BuildDir.Path)
	//TODO check for required directories
	if util.CopyDir(build.SiteDir.Path, build.BuildDir.Path) != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fi, err := os.Lstat(build.BuildRoot.Path + "/latest")
	if err != nil && !os.IsNotExist(err) {
		fmt.Println(err)
		os.Exit(3)
	}
	if os.IsNotExist(err) {
		os.Symlink(build.BuildId.Path, build.BuildRoot.Path+"/latest")

	} else {
		switch mode := fi.Mode(); {
		case mode&os.ModeSymlink != 0:
			err = os.Remove(build.BuildRoot.Path + "/latest")
			if err != nil {
				os.Exit(2)
			}
		}
		os.Symlink(build.BuildId.Path, build.BuildRoot.Path+"/latest")
	}
	bds, err := os.Open(build.StageDir.Path)
	if err != nil {
		//TODO error
		os.Exit(3)
	}
	defer bds.Close()
	dirs, err := bds.Readdirnames(0)
	if err != nil {
		os.Exit(3)
	}
	//Quick hack, this needs a cleaned up and remove the useless var
	var a []string
	for _, m := range dirs {
		//Ignore filepath error since it is static here
		matched, _ := filepath.Match("[0-9]*-*", m)
		if matched {
			a = append(a, m)
		}
	}
	dirs = a
	sort.Strings(dirs)
	for _, stage := range dirs {
		cmd := exec.Command(build.StageDir.Path + "/" + stage)
		cmd.Env = append(os.Environ())
		for _, e := range build.BuildEnv {
			//TODO should I be quoting these variables? Almost certainly
			cmd.Env = append(cmd.Env, e.Variable+"="+e.Path)
		}
		fmt.Println(cmd.Path)
		if err := cmd.Run(); err != nil {
			fmt.Println(err)
			os.Exit(4)
		}
	}
}
