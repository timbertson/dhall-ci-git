let CI = ../../dependencies/CI.dhall

let Script = ../Script.dhall

let Workflow = CI.Workflow

let Step = Workflow.Step

let requireCleanWorkspace =
          Step.bash Script.requireCleanWorkspace
      //  { name = Some "Require clean workspace" }

let botCommitterEnv = Script.committerEnv Script.githubActionsBot

let CleanupAssociatedBranch = ./CleanupAssociatedBranch.dhall

let Checkout = { Type = { fetchDepth : Natural }, default.fetchDepth = 1 }

let toParams =
      \(options : Checkout.Type) ->
        toMap { fetch-depth = Natural/show options.fetchDepth }

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
    , botCommitterEnv
    , requireCleanWorkspace
    }
