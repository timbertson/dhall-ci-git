let CI = ../../dependencies/CI.dhall

let Script = ../Script.dhall

let Workflow = CI.Workflow

let Step = Workflow.Step

let requireCleanWorkspace =
          Step.bash Script.requireCleanWorkspace
      //  { name = Some "Require clean workspace" }

let botCommitterEnv = Script.committerEnv Script.githubActionsBot

let CleanupAssociatedBranch = ./CleanupAssociatedBranch.dhall

let Checkout =
      { Type = { fetchDepth : Natural, token : Optional Text }
      , default = { fetchDepth = 1, token = None Text }
      }

let toParams =
      \(options : Checkout.Type) ->
        let tokenParam =
              merge
                { None = [] : List { mapKey : Text, mapValue : Text }
                , Some =
                    \(token : Text) ->
                      [ { mapKey = "token", mapValue = "\${{ ${token} }}" } ]
                }
                options.token

        in  toMap { fetch-depth = Natural/show options.fetchDepth } # tokenParam

let checkout =
      \(options : Checkout.Type) ->
          Step::{
          , uses = Some "actions/checkout@v2"
          , `with` = Some (toParams options)
          }
        : Step.Type

in  { checkout
    , Checkout
    , CleanupAssociatedBranch
    , VersionBump = ./VersionBump.dhall
    , DerivedCommit = ./DerivedCommit.dhall
    , botCommitterEnv
    , requireCleanWorkspace
    }
