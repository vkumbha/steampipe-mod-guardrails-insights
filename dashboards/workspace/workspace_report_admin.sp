dashboard "workspace_report_admin" {

  title         = "Turbot Guardrails Workspace Report for Admins"
  documentation = file("./dashboards/workspace/docs/workspace_report.md")

  tags = merge(local.workspace_common_tags, {
    type     = "Report"
    category = "Summary"
  })

  # Analysis
  container {
    card {
      sql   = query.workspaces_count.sql
      width = 2
    }

    card {
      sql   = query.unique_te_installations.sql
      width = 2
    }

    card {
      sql   = query.accounts_total.sql
      width = 2
    }

    card {
      sql   = query.resources_count.sql
      width = 2
    }

    card {
      sql   = query.policy_settings_total.sql
      width = 2
    }

    # card {
    #   sql   = query.alerts_total.sql
    #   width = 2
    # }

    card {
      sql   = query.active_controls_count.sql
      width = 2
    }
  }

  container {
    card {
      sql   = query.policies_tbd_count.sql
      width = 2
    }

    card {
      sql   = query.policies_invalid_count.sql
      width = 2
    }

    card {
      sql   = query.policies_error_count.sql
      width = 2
    }

    card {
      sql   = query.controls_tbd_count.sql
      width = 2
    }

    card {
      sql   = query.controls_invalid_count.sql
      width = 2
    }

    card {
      sql   = query.controls_error_count.sql
      width = 2
    }

  }
  # Analysis - Workspace stats - Accounts, Resources, Controls, Alerts
  container {
    title = "Workspaces Summary"
    table {
      width = 12

      column "teVersionTurbotId" {
        display = "none"
      }

      column "TE Version" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/policies/settings/{{. 'teVersionTurbotId' | @uri}}
        EOT
      }

      column "Accounts" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/accounts?filter=sort%3AtrunkTitle
        EOT
      }

      column "Resources" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/resources-by-resource-type
        EOT
      }

      column "Policy Settings" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/policies/all/settings
        EOT
      }

      column "Active Controls" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-resource-type?filter=state%3Aactive+%21resourceTypeId%3A%27tmod%3A%40turbot%2Fturbot%23%2Fresource%2Ftypes%2Fturbot%27
        EOT
      }

      column "Alerts" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/alerts-by-control-type
        EOT
      }

      sql = query.workspace_stats.sql
    }
  }

  container {
    title = "Policies Summary"
    table {
      width = 12

      column "ok" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/policy-values-by-state?filter=state%3Aok
        EOT
      }

      column "tbd" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/policy-values-by-state?filter=state%3Atbd+timestamp%3A>%3DT-1h
        EOT
      }

      column "invalid" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/policy-values-by-state?filter=state%3Ainvalid
        EOT
      }

      column "error" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/policy-values-by-state?filter=state%3Aerror
        EOT
      }

      column "total" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/policy-values-by-state
        EOT
      }

      sql = query.policies_summary.sql
    }
  }

  container {
    title = "Controls Summary"
    table {
      width = 12

      column "ok" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Aok
        EOT
      }

      column "skipped" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Askipped
        EOT
      }

      column "tbd" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Atbd
        EOT
      }

      column "alarm" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Aalarm
        EOT
      }

      column "invalid" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Ainvalid
        EOT
      }

      column "error" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state?filter=state%3Aerror
        EOT
      }

      column "total" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/reports/controls-by-state
        EOT
      }

      sql = query.controls_summary.sql
    }
  }

  container {
    title = "Mods Health"
    text {
      value = "This looks for 'Turbot > Mod > Health' control. The list is empty for healthy workspace(s)."
    }
    table {
      column "id" {
        display = "none"
      }

      column "Resource Trunk Title" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/controls/{{. 'id' | @uri}}
        EOT
      }
      width = 12
      sql   = query.mod_health_summary.sql
    }
  }

  container {
    title = "DB queries/indexes Health"
    text {
      value = "This looks for 'Turbot > Workspace > Health Control' control. The list is empty for healthy workspace(s)."
    }
    table {
      column "id" {
        display = "none"
      }

      column "State" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/controls/{{. 'id' | @uri}}
        EOT
      }
      width = 12
      sql   = query.db_queries_health_summary.sql
    }
  }

  container {
    title = "Cache parameter Health"
    text {
      value = "This looks for 'Turbot > Cache > Health Check' control. The list is empty for healthy workspace(s)."
    }
    table {
      column "id" {
        display = "none"
      }

      column "State" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/controls/{{. 'id' | @uri}}
        EOT
      }
      width = 12
      sql   = query.cache_parameter_health_summary.sql
    }
  }

  container {
    title = "Top 20 Control Alerts by URI"
    text {
      value = "List of top 20 control alerts(tbd, invalid, error) by Control Type URIs across workspaces."
    }
    table {
      width = 12
      sql   = query.control_alerts_by_uri.sql
    }
  }


  container {
    title = "Missing required minimum permissions for the AWS Role"
    text {
      value = "The AWS Account CMDB is in eror state, this is most likely because the AWS IAM Role used to import the account does not have bare minimum permissions. The list is empty for healthy workspace(s)."
    }
    table {
      column "id" {
        display = "none"
      }

      column "Account Id" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/controls/{{. 'id' | @uri}}
        EOT
      }
      width = 12
      sql   = query.missing_permissions_aws_account.sql
    }
  }

}

query "unique_te_installations" {
  sql = <<-EOQ
    select
      COUNT(DISTINCT value) as "Unique TE versions"
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/workspaceVersion'
  EOQ
}

query "policies_tbd_count" {
  sql = <<-EOQ
  select
    sum((output ->  'tbd' -> 'metadata' -> 'stats' -> 'total')::int) as value,
    'Policies - TBD' as label,
    case when sum((output ->  'tbd' -> 'metadata' -> 'stats' -> 'total')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query
  where
    query = '{
    tbd: policyValues(filter: "state:tbd timestamp:<=T-1h") {
      metadata {
        stats {
          total
        }
      }
    }
  }'
  EOQ
}

query "policies_invalid_count" {
  sql = <<-EOQ
  select
    sum((output ->  'invalid' -> 'metadata' -> 'stats' -> 'total')::int) as value,
    'Policies - Invalid' as label,
    case when sum((output ->  'invalid' -> 'metadata' -> 'stats' -> 'total')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query
  where
    query = '{
    invalid: policyValues(filter: "state:invalid") {
      metadata {
        stats {
          total
        }
      }
    }
  }'
  EOQ
}

query "policies_error_count" {
  sql = <<-EOQ
  select
    sum((output ->  'error' -> 'metadata' -> 'stats' -> 'total')::int) as value,
    'Policies - Error' as label,
    case when sum((output ->  'error' -> 'metadata' -> 'stats' -> 'total')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query
  where
    query = '{
    error: policyValues(filter: "state:error") {
      metadata {
        stats {
          total
        }
      }
    }
  }'
  EOQ
}

query "controls_tbd_count" {
  sql = <<-EOQ
  select
    sum((controls -> 'summary' -> 'control' ->> 'tbd')::int) as value,
    'Controls - TBD' as label,
    case when sum((controls -> 'summary' -> 'control' ->> 'tbd')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query,
    jsonb_array_elements(output -> 'controlSummariesByResource' -> 'items') as controls
  where
    query = '{
    controlSummariesByResource {
      items {
        summary {
          control {
            total
            ok
            skipped
            alarm
            tbd
            invalid
            error
          }
        }
      }
    }
    }'
  EOQ
}

query "controls_invalid_count" {
  sql = <<-EOQ
  select
    sum((controls -> 'summary' -> 'control' ->> 'invalid')::int) as value,
    'Controls - Invalid' as label,
    case when sum((controls -> 'summary' -> 'control' ->> 'invalid')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query,
    jsonb_array_elements(output -> 'controlSummariesByResource' -> 'items') as controls
  where
    query = '{
    controlSummariesByResource {
      items {
        summary {
          control {
            total
            ok
            skipped
            alarm
            tbd
            invalid
            error
          }
        }
      }
    }
    }'
  EOQ
}

query "controls_error_count" {
  sql = <<-EOQ
  select
    sum((controls -> 'summary' -> 'control' ->> 'error')::int) as value,
    'Controls - Error' as label,
    case when sum((controls -> 'summary' -> 'control' ->> 'error')::int) = 0 then 'ok' else 'alert' end as "type"
  from
    guardrails_query,
    jsonb_array_elements(output -> 'controlSummariesByResource' -> 'items') as controls
  where
    query = '{
    controlSummariesByResource {
      items {
        summary {
          control {
            total
            ok
            skipped
            alarm
            tbd
            invalid
            error
          }
        }
      }
    }
    }'
  EOQ
}

query "policies_summary" {
  sql = <<-EOQ
  select
    workspace as "Workspace",
    output ->  'ok' -> 'metadata' -> 'stats' -> 'total' as ok,
    output ->  'tbd' -> 'metadata' -> 'stats' -> 'total' as tbd,
    output ->  'invalid' -> 'metadata' -> 'stats' -> 'total' as invalid,
    output ->  'error' -> 'metadata' -> 'stats' -> 'total' as error,
    output ->  'total' -> 'metadata' -> 'stats' -> 'total' as total
  from
    guardrails_query
  where
    query = '{
    ok: policyValues(filter: "state:ok") {
      metadata {
        stats {
          total
        }
      }
    }
    tbd: policyValues(filter: "state:tbd timestamp:<=T-1h") {
      metadata {
        stats {
          total
        }
      }
    }
    invalid: policyValues(filter: "state:invalid") {
      metadata {
        stats {
          total
        }
      }
    }
    error: policyValues(filter: "state:error") {
      metadata {
        stats {
          total
        }
      }
    }
    total: policyValues {
      metadata {
        stats {
          total
        }
      }
    }
  }'
  order by
    total desc
  EOQ
}

query "controls_summary" {
  sql = <<-EOQ
  select
    workspace as "Workspace",
    (controls -> 'summary' -> 'control' ->> 'ok')::int as ok,
    (controls -> 'summary' -> 'control' ->> 'skipped')::int as skipped,
    (controls -> 'summary' -> 'control' ->> 'tbd')::int as tbd,
    (controls -> 'summary' -> 'control' ->> 'alarm')::int as alarm,
    (controls -> 'summary' -> 'control' ->> 'invalid')::int as invalid,
    (controls -> 'summary' -> 'control' ->> 'error')::int as error,
    (controls -> 'summary' -> 'control' ->> 'total')::int as total
  from
    guardrails_query,
    jsonb_array_elements(output -> 'controlSummariesByResource' -> 'items') as controls
  where
    query = '{
    controlSummariesByResource {
      items {
        summary {
          control {
            total
            ok
            skipped
            alarm
            tbd
            invalid
            error
          }
        }
      }
    }
    }'
  order by
    total desc
  EOQ
}

query "mod_health_summary" {
  sql = <<-EOQ
  select
    id,
    workspace as "Workspace",
    resource_trunk_title as "Resource Trunk Title",
    state as "State",
    reason as "Reason",
    update_timestamp as "Update Timestamp"
  from
    guardrails_control
  where
    control_type_uri = 'tmod:@turbot/turbot#/control/types/modHealth'
    and state != 'ok'
  order by
    workspace,state
  EOQ
}

query "db_queries_health_summary" {
  sql = <<-EOQ
  select
    id,
    workspace as "Workspace",
    state as "State",
    reason as "Reason",
    jsonb_pretty(details) as "Details",
    update_timestamp as "Update Timestamp"
  from
    guardrails_control
  where
    control_type_uri = 'tmod:@turbot/turbot#/control/types/workspaceHealthControl'
    and state != 'ok'
  order by
    workspace, state
  EOQ
}

query "cache_parameter_health_summary" {
  sql = <<-EOQ
  select
    id,
    workspace as "Workspace",
    state as "State",
    reason as "Reason",
    jsonb_pretty(details) as "Details",
    update_timestamp as "Update Timestamp"
  from
    guardrails_control
  where
    control_type_uri = 'tmod:@turbot/turbot#/control/types/cacheHealthCheck'
    and state != 'ok'
  order by
    workspace, state
  EOQ
}

query "control_alerts_by_uri" {
  sql = <<-EOQ
  select
    count(reason) as "Count",
    control_type_uri as "Control Type URI",
    reason as "Reason"
  from
    guardrails_control
  where
    state in ('error','invalid','tbd')
  group by
    reason,
    control_type_uri
  order by
    "Count" desc
  limit 20
  EOQ
}

query "missing_permissions_aws_account" {
  sql = <<-EOQ
  select
    workspace as "Workspace",
    accounts -> 'turbot' ->> 'id' as id,
    accounts -> 'resource' ->> 'account_id' as "Account Id",
    accounts -> 'resource' ->> 'account_alias' as "Account Alias",
    accounts ->> 'state'  as "State",
    accounts ->> 'reason'  as "Reason"
  from
    guardrails_query,
    jsonb_array_elements(output ->  'controls' -> 'items') as accounts
  where
    query = '{
    controls(
      filter: "controlTypeId:tmod:@turbot/aws#/control/types/accountCmdb state:error"
    ) {
      items {
        turbot {
          id
        }
        state,
        reason
        resource {
          account_id: get(path: "Id")
          account_alias: get(path: "AccountAlias")
          turbot {
            id
          }
        }
      }
      metadata {
        stats {
          total
        }
      }
    }
  }
  '
  order by
    workspace
  EOQ
}


