let Meta =
        env:DHALL_CI_META_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/master/Meta/package.dhall

let CI = ../dependencies/CI.dhall
let Workflow = CI.Workflow

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-git"
            , componentDesc = Some "git support"
            }
          }
    }
