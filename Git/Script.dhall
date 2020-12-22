let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let hasUncommittedChanges =
      "! git --no-pager diff --patch --exit-code HEAD -- >&2"

let ifUncommitedChanges =
      \(cmd : Bash.Type) -> Bash.`if` hasUncommittedChanges cmd : Bash.Type

let requireCleanWorkspace =
        ifUncommitedChanges
          [ "echo 'Uncommitted changes found!' >&2", "exit 1" ]
      : Bash.Type

let requireCleanWorkspaceAfterRunning =
      \(script : Bash.Type) ->
            script
          # ifUncommitedChanges
              [ "set +x"
              , "echo >&2"
              , "echo '--------------------------------' >&2"
              , "echo 'Uncommitted changes found, please run the following locally and commit the changes:' >&2"
              , "cat >&2 <<EOF_diff"
              , Bash.render (Bash.indent script)
              , ''
                EOF_diff''
              , "exit 1"
              ]
        : Bash.Type

let commitEnvVars =
      [ "GIT_AUTHOR_NAME"
      , "GIT_AUTHOR_EMAIL"
      , "GIT_COMMITTER_NAME"
      , "GIT_COMMITTER_EMAIL"
      ]

let Committer = { name : Text, email : Text }

let committerEnv =
      \(user : Committer) ->
        toMap
          { GIT_AUTHOR_NAME = user.name
          , GIT_AUTHOR_EMAIL = user.email
          , GIT_COMMITTER_NAME = user.name
          , GIT_COMMITTER_EMAIL = user.email
          }

let StringMapEntry = { mapKey : Text, mapValue : Text }

let exportCommiterEnv =
      \(user : Committer) ->
          Prelude.List.map
            StringMapEntry
            Text
            (\(kv : StringMapEntry) -> "export ${kv.mapKey}=\"${kv.mapValue}\"")
            (committerEnv user)
        : Bash.Type

let githubActionsBot =
        { name = "github-actions"
        , email = "41898282+github-actions[bot]@users.noreply.github.com"
        }
      : Committer

let withoutImplicitGithubAuth =
    -- used as e.g. "git ${Git.withoutImplicitGithubAuth} push [...]"
    -- see https://github.com/timbertson/dhall-render/issues/6
      "-c 'http.https://github.com/.extraheader='"

in  { Committer
    , commitEnvVars
    , committerEnv
    , exportCommiterEnv
    , githubActionsBot
    , hasUncommittedChanges
    , ifUncommitedChanges
    , requireCleanWorkspace
    , requireCleanWorkspaceAfterRunning
    , withoutImplicitGithubAuth
    }
