let CI = ../../dependencies/CI.dhall

let Prelude = ../../dependencies/Prelude.dhall

let Workflow = CI.Workflow

let Expr = Workflow.Expr

let Step = Workflow.Step

let Component = < Major | Minor | Patch >

let ReleaseTrigger = < Always | Commit >

let Action = < Generate | Tag | Push >

let VersionScheme = < Semver | MajorMinor >

let VersionTemplate = < BranchName | Literal : Text >

let Opts =
      { scheme : VersionScheme
      , releaseTrigger : ReleaseTrigger
      , action : Action
      , defaultBump : Component
      , minBump : Optional Component
      , versionTemplate : Optional VersionTemplate
      , exportEnv : Optional Text
      }

let default =
        { scheme = VersionScheme.Semver
        , releaseTrigger = ReleaseTrigger.Always
        , defaultBump = Component.Minor
        , minBump = None Component
        , action = Action.Tag
        , versionTemplate = Some VersionTemplate.BranchName
        , exportEnv = Some "VERSION"
        }
      : Opts

let pushGeneratedTag =
    -- An explicit `push` step, useful instead of Action.Push when you want to
    -- perform some action before pushing
      \(opts : Opts) ->
        let exportEnv =
              merge { Some = \(v : Text) -> v, None = "VERSION" } opts.exportEnv

        in      Step.bash
                  [ "git push origin \"HEAD:refs/tags/v\$${exportEnv}\"" ]
            //  { name = Some "Push version tag"
                , `if` = Some "(${Expr.isPush}) && (env.${exportEnv} != '')"
                }

let releaseTriggerToString =
      \(trigger : ReleaseTrigger) ->
        merge { Always = "always", Commit = "commit" } trigger

let componentToString =
      \(component : Component) ->
        merge { Major = "major", Minor = "minor", Patch = "patch" } component

let versionTemplateToString =
    -- BranchName uses base_ref (destination for PR), or plain ref for a push
      \(template : VersionTemplate) ->
        merge
          { BranchName = "\${{ github.base_ref || github.ref }}"
          , Literal = \(t : Text) -> t
          }
          template

let stepParams =
      \(opts : Opts) ->
        let entry =
              \(key : Text) ->
              \(value : Text) ->
                  [ { mapKey = key, mapValue = value } ]
                : Prelude.Map.Type Text Text

        let optionalEntry =
              \(T : Type) ->
              \(convert : T -> Text) ->
              \(key : Text) ->
              \(value : Optional T) ->
                merge
                  { Some = \(value : T) -> entry key (convert value)
                  , None = [] : Prelude.Map.Type Text Text
                  }
                  value

        let maybePush =
            -- if action is Push, still only push when it's a `push` event (not a `pull_request`)
              "\${{github.event_name == 'push'}}"

        in  Prelude.List.concat
              (Prelude.Map.Entry Text Text)
              [ entry
                  "numComponents"
                  (merge { Semver = "3", MajorMinor = "2" } opts.scheme)
              , entry
                  "releaseTrigger"
                  (releaseTriggerToString opts.releaseTrigger)
              , toMap
                  ( merge
                      { Generate = { doTag = "false", doPush = "false" }
                      , Tag = { doTag = "true", doPush = "false" }
                      , Push = { doTag = "true", doPush = maybePush }
                      }
                      opts.action
                  )
              , entry "defaultBump" (componentToString opts.defaultBump)
              , optionalEntry Component componentToString "minBump" opts.minBump
              , optionalEntry
                  VersionTemplate
                  versionTemplateToString
                  "versionTemplate"
                  opts.versionTemplate
              ]

let step =
      \(opts : Opts) ->
        Step::{
        , name = Some "Version bump"
        , uses = Some "timbertson/autorelease-tagger-action@v1"
        , `with` = Some (stepParams opts)
        }

in  { Type = Opts
    , default
    , Component
    , ReleaseTrigger
    , Action
    , VersionScheme
    , VersionTemplate
    , pushGeneratedTag
    , step
    }
