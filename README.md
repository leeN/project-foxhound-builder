# Foxhound build script

Automatic setup of Foxhound with Playwright integration, useful for e.g., crawling studies.

## Usage

Assume you have a folder structure like this:

`BASE_DIR/foxhound_builder <- this repo`

1. Adjust the variables to configure e.g., the version of foxhound you want to build. This is done 
by editing `build.sh`. The following variables are available:
    * `FOXHOUND_VERSION` determines the tag/branch you want to build. Possible values are e.g., 
      `main` for the current development version or `v118.0.1` for a tagged release.
    * `PLAYWRIGHT_VERSION` determines the matching Playwright release. The correct one can be found 
      in the release description of the version you want to build, e.g., [for 
      v121.0](https://github.com/SAP/project-foxhound/releases/tag/v121.0). Here, `release-1.42` is the correct value
    * `FOXHOUND_OBJ_DIR` is the directory in which foxhound places the freshly built object files. 
      It can be configured inside the mozconfig files, e.g., as follows:
      `mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-tf-release-with-symbols`
      Here, `FOXHOUND_OBJ_DIR` would be set to `obj-tf-release-with-symbols`.
      This script tries to determine the correct version from the mozconfig in case you did not set 
      the variable manually. This is hacky and will only print a suggestion.
2. `bash build.sh` and get a coffee
3. Start crawling!

When running `build.sh` it will clone and setup foxhound and playwright inside this `BASE_DIR`. 
Running this should not require user interaction, unless some system dependencies are amiss. If 
that is the case, invoke `./mach bootstrap --application-choice=browser` inside 
`BASE_DIR/project-foxhound` manually and follow the instructions.

## Cite us!

If you use project foxhound in your academic works, please cite us as follows:

```bibtex
@inproceedings{KleBarBen+22,
  author = {David Klein and Thomas Barber and Souphiane Bensalim and Ben Stock and Martin Johns},
  title = {Hand Sanitizers in the Wild: A Large-scale Study of Custom JavaScript Sanitizer Functions},
  booktitle = {Proc. of the IEEE European Symposium on Security and Privacy},
  year = {2022},
  month = jun,
}
```
