dashboard "control_dashboard" {

  title         = "Turbot Guardrails Controls Dashboard"
  documentation = file("./dashboards/control/docs/control_dashboard.md")

  tags = merge(local.control_common_tags, {
    type     = "Dashboard"
    category = "Control"
  })

  container {

    card {
      sql   = query.guardrails_control_error_count.sql
      width = 2
      href  = dashboard.control_error_report_age.url_path
    }

    card {
      sql   = query.guardrails_control_invalid_count.sql
      width = 2
      href  = dashboard.control_invalid_report_age.url_path
    }

    card {
      sql   = query.guardrails_control_alarm_count.sql
      width = 2
      href  = dashboard.control_alarm_report_age.url_path
    }

    card {
      sql   = query.guardrails_control_ok_count.sql
      width = 2
      # href  = dashboard.control_alarm_report_age.url_path
    }

    card {
      sql   = query.guardrails_control_skipped_count.sql
      width = 2
      # href  = dashboard.control_alarm_report_age.url_path
    }

    card {
      sql   = query.guardrails_control_tbd_count.sql
      width = 2
      # href  = dashboard.control_alarm_report_age.url_path
    }



    container {
      title = "Control states by workspaces"

      chart {
        type  = "donut"
        title = "Errors by Workspace"
        width = 4
        sql   = query.errors_by_workspace.sql
      }

      chart {
        type  = "donut"
        title = "Invalids by Workspace"
        width = 4
        sql   = query.invalids_by_workspace.sql
      }

      chart {
        type  = "donut"
        title = "Alarms by Workspace"
        width = 4
        sql   = query.alarms_by_workspace.sql
      }
    }

    # table {
    #   title = "Top 20 Alerts by Control Type URI across workspaces"
    #   sql   = query.guardrails_control_top_20_alerts.sql
    # }


    chart {
      type  = "bar"
      title = "Alerts by Control Type"
      width = 6

      legend {
        display  = "auto"
        position = "top"
      }

      series "error" {
        title = "Error"
        color = "red"
      }
      series "invalid" {
        title = "Invalid"
        color = "MediumVioletRed"
      }
      series "alarm" {
        title = "Alarm"
        color = "darkred"
      }
      axes {
        x {
          title {
            value = "Control Alerts"
          }
          labels {
            display = "auto"
          }
          min = 0
        }
        y {
          title {
            value = "Control Type"
          }
          labels {
            display = "show"
          }
          min = 0
          max = 100
        }
      }
      sql = <<-EOQ
        select
          controls -> 'type' ->> 'title',
          (controls -> 'summary' -> 'control' ->> 'invalid')::int as invalid,
          (controls -> 'summary' -> 'control' ->> 'error')::int as error,
          (controls -> 'summary' -> 'control' ->> 'alarm')::int as alarm
        from
          guardrails_query,
          jsonb_array_elements(output ->  'controlSummariesByControlType' -> 'items') as controls
        where
          query = '
            {
              controlSummariesByControlType {
                items {
                  type {
                    uri
                    title
                  }
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
        group by controls -> 'type'  ->> 'uri', controls.value
        order by controls -> 'category'  ->> 'title' desc
      EOQ
    }


    chart {
      type  = "bar"
      title = "Controls by Resource CategoryType"
      width = 6

      legend {
        display  = "auto"
        position = "top"
      }

      series "error" {
        title = "Error"
        color = "red"
      }
      series "invalid" {
        title = "Invalid"
        color = "MediumVioletRed"
      }
      series "alarm" {
        title = "Alarm"
        color = "darkred"
      }
      series "ok" {
        title = "OK"
        color = "green"
      }
      series "skipped" {
        title = "Skipped"
        color = "silver"
      }
      series "tbd" {
        title = "TBD"
        color = "aliceblue"
      }
      axes {
        x {
          title {
            value = "Control Alerts"
          }
          labels {
            display = "auto"
          }
          # min = 0
        }
        y {
          title {
            value = "Control Category"
          }
          labels {
            display = "show"
          }
          # min = 0
          # max = 100
        }
      }
      sql = <<-EOQ
      select
        controls -> 'category' ->> 'title' as category,
        SUM((controls -> 'summary' -> 'control' ->> 'invalid')::int) as invalid,
        SUM((controls -> 'summary' -> 'control' ->> 'error')::int) as error,
        SUM((controls -> 'summary' -> 'control' ->> 'alarm')::int) as alarm,
        SUM((controls -> 'summary' -> 'control' ->> 'ok')::int) as ok,
        SUM((controls -> 'summary' -> 'control' ->> 'skipped')::int) as skipped,
        SUM((controls -> 'summary' -> 'control' ->> 'tbd')::int) as tbd
      from
        guardrails_query,
        jsonb_array_elements(output ->  'controlSummariesByControlCategory' -> 'items') as controls
      where
        query = '
          {
            controlSummariesByControlCategory(
              filter: "controlCategoryId:tmod:@turbot/turbot#/control/categories/resource"
            ) {
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
                category {
                  title
                }
              }
            }
          }'
      GROUP BY category
      ORDER BY SUM((controls -> 'summary' -> 'control' ->> 'total')::int) DESC;
      EOQ
    }



  }
}

query "guardrails_control_top_20_alerts" {
  sql = <<-EOQ
    select
      control_type_trunk_title as "Control Type Trunk Title", control_type_uri as "Control Type URI",
      count(control_type_uri) as "Count"
    from
      guardrails_control
    where
      state in
      (
        'alarm',
        'error',
        'invalid'
      )
    group by
      control_type_uri, control_type_trunk_title
    order by
      "Count" desc limit 20;
  EOQ
}

##################
query "guardrails_control_error_count" {
  sql = <<-EOQ
    select
      case when (controls -> 'summary' -> 'control' ->> 'error')::int > 0 then (controls -> 'summary' -> 'control' ->> 'error')::int else '0' end as value,
      'Error' as label,
      case when (controls -> 'summary' -> 'control' ->> 'error')::int = 0 then 'ok' else 'alert' end as "type"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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

query "guardrails_control_invalid_count" {
  sql = <<-EOQ
    select
      case when (controls -> 'summary' -> 'control' ->> 'invalid')::int > 0 then (controls -> 'summary' -> 'control' ->> 'invalid')::int else '0' end as value,
      'Invalid' as label,
      case when (controls -> 'summary' -> 'control' ->> 'invalid')::int = 0 then 'ok' else 'alert' end as "type"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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

query "guardrails_control_alarm_count" {
  sql = <<-EOQ
    select
      case when (controls -> 'summary' -> 'control' ->> 'alarm')::int > 0 then (controls -> 'summary' -> 'control' ->> 'alarm')::int else '0' end as value,
      'Alarm' as label,
      case when (controls -> 'summary' -> 'control' ->> 'alarm')::int = 0 then 'ok' else 'alert' end as "type"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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

query "guardrails_control_ok_count" {
  sql = <<-EOQ
    select
      case when (controls -> 'summary' -> 'control' ->> 'ok')::int > 0 then (controls -> 'summary' -> 'control' ->> 'ok')::int else '0' end as value,
      'OK' as label,
      case when (controls -> 'summary' -> 'control' ->> 'ok')::int > 0 then 'ok' else 'alert' end as "type"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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

query "guardrails_control_skipped_count" {
  sql = <<-EOQ
    select
      (controls -> 'summary' -> 'control' ->> 'skipped')::int as "Skipped"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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

query "guardrails_control_tbd_count" {
  sql = <<-EOQ
    select
      case when (controls -> 'summary' -> 'control' ->> 'tbd')::int > 0 then (controls -> 'summary' -> 'control' ->> 'tbd')::int else '0' end as value,
      'TBD' as label,
      case when (controls -> 'summary' -> 'control' ->> 'tbd')::int = 0 then 'ok' else 'info' end as "type"
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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


query "alarms_by_workspace" {
  sql = <<-EOQ
    select
      _ctx ->> 'connection_name' as "Connection Name",
      (controls -> 'summary' -> 'control' ->> 'alarm')::int
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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
    group by _ctx ->> 'connection_name',controls.value;
    EOQ
}

query "invalids_by_workspace" {
  sql = <<-EOQ
    select
      _ctx ->> 'connection_name' as "Connection Name",
      (controls -> 'summary' -> 'control' ->> 'invalid')::int
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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
    group by _ctx ->> 'connection_name',controls.value;
    EOQ
}

query "errors_by_workspace" {
  sql = <<-EOQ
    select
      _ctx ->> 'connection_name' as "Connection Name",
      (controls -> 'summary' -> 'control' ->> 'error')::int
    from
      guardrails_query,
      jsonb_array_elements(output ->  'controlsByResourceList' -> 'items') as controls
    where
      query = '{
      controlsByResourceList {
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
    group by _ctx ->> 'connection_name',controls.value;
    EOQ
}


