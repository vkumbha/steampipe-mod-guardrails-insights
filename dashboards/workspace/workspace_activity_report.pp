benchmark "workspace_user_activity" {
  title = "Turbot Guardrails Workspace Activity"
  tags = merge(local.workspace_common_tags, {
    type     = "Benchmark"
    category = "Health"
  })

  description = "Turbot Guardrails Workspace Activity"
  children = [
    control.guardrails_workspace_user_activity,
    control.guardrails_workspace_mod_auto_update,
    control.guardrails_workspace_retention,
    control.guardrails_workspace_activity_retention,
    control.guardrails_workspace_policy_conflicts,
  ]
}

control "guardrails_workspace_user_activity" {
  title       = "Turbot > User Login History"
  description = "Check User Login activity in customer workspaces"
  query       = query.guardrails_workspace_user_activity
}

control "guardrails_workspace_mod_auto_update" {
  title       = "Turbot > Workspace > Auto Update"
  description = "Check the policy values for guardrails mod auto updates"
  query       = query.guardrails_mod_auto_update
}

control "guardrails_workspace_retention" {
  title       = "Turbot > Workspace > Retention"
  description = "Check the policy values for guardrails workspace retention"
  query       = query.guardrails_retention
}

control "guardrails_workspace_activity_retention" {
  title       = "Turbot > Workspace > Retention > Activity Retention"
  description = "Check the policy values for guardrails workspace activity retention"
  query       = query.guardrails_activity_retention
}

control "guardrails_workspace_policy_conflicts" {
  title       = "Turbot > Workspace > Policy Conflicts"
  description = "Detect potential policy conflicts causing controls to loop repeatedly."
  query       = query.guardrails_workspace_policy_conflicts
}

# query "guardrails_workspace_user_activity" {
#   sql = <<-EOQ
#     SELECT
#         g.workspace,
#         g.workspace AS resource,
#         CASE
#             WHEN COUNT(n.notifications) = 0 THEN 'alarm'
#             ELSE 'ok'
#         END AS status,
#         CASE
#             WHEN COUNT(n.notifications) = 0 THEN 'Workspace is Inactive. No User Login for 30 Days.'
#             ELSE 'Workspace is Active.'
#         END AS reason
#     FROM
#         tmhcc.guardrails_query g
#     LEFT JOIN LATERAL
#         jsonb_array_elements(g.output -> 'notifications' -> 'items') AS n(notifications) ON TRUE
#     WHERE
#         g.query = '{
#           notifications: resources(
#             filter: "resourceTypeId:tmod:@turbot/turbot-iam#/resource/types/profile,tmod:@turbot/turbot-iam#/resource/types/groupProfile,tmod:@turbot/aws-iam#/resource/types/instanceProfile $.lastLoginTimestamp:>=T-30d"
#           ) {
#             items {
#               lastLoginTimestamp: get(path: "lastLoginTimestamp")
#               trunk {
#                 title
#               }
#               turbot {
#                 akas
#               }
#             }
#           }
#         }'
#     GROUP BY
#         g.workspace;
#   EOQ
# }

query "guardrails_workspace_user_activity" {
  sql = <<-EOQ
    SELECT
        g.workspace,
        g.workspace AS resource,
        CASE 
            WHEN COUNT(
                CASE 
                    WHEN (n.notifications ->> 'email') NOT LIKE '%@turbot.com' 
                    THEN 1 
                    ELSE NULL 
                END
            ) = 0 THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE 
            WHEN COUNT(
                CASE 
                    WHEN (n.notifications ->> 'email') NOT LIKE '%@turbot.com' 
                    THEN 1 
                    ELSE NULL 
                END
            ) = 0 THEN 'Workspace is Inactive. No User Login for 30 Days.'
            ELSE 'Workspace is Active.'
        END AS reason
    FROM
        guardrails_query g
    LEFT JOIN LATERAL
        jsonb_array_elements(g.output -> 'notifications' -> 'items') AS n(notifications) ON TRUE
    WHERE
        g.query = '{
          notifications: resources(
            filter: "resourceTypeId:tmod:@turbot/turbot-iam#/resource/types/profile,tmod:@turbot/turbot-iam#/resource/types/groupProfile,tmod:@turbot/aws-iam#/resource/types/instanceProfile $.lastLoginTimestamp:>=T-30d"
          ) {
            items {
              email: get(path:"email")
              lastLoginTimestamp: get(path: "lastLoginTimestamp")
              trunk {
                title
              }
              turbot {
                akas
              }
            }
          }
        }'
    GROUP BY
        g.workspace;
  EOQ
}


query "guardrails_mod_auto_update" {
  sql = <<-EOQ
    select
      resource_trunk_title,
      workspace,
      workspace as resource,
      CASE 
        WHEN value = 'Enforce within Mod Change Window' THEN 'ok'
        ELSE 'alarm'
      END AS status,
      CASE 
        WHEN value = 'Enforce within Mod Change Window' THEN 'Policy recommendation met'
        ELSE 'Policy recommendation not met'
      END AS reason
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/modAutoUpdate'
    order by 
      workspace;
  EOQ
}

query "guardrails_retention" {
  sql = <<-EOQ
    select
      workspace,
      id as resource,
      CASE 
        WHEN value = 'Enforce: Enable purging via Smart Retention' THEN 'ok'
        ELSE 'alarm'
      END AS status,
      CASE 
        WHEN value = 'Enforce: Enable purging via Smart Retention' THEN 'Policy recommendation met'
        ELSE 'Policy recommendation not met'
      END AS reason
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/retention'
    order by 
      workspace;
  EOQ
}

query "guardrails_activity_retention" {
  sql = <<-EOQ
    SELECT
      ws.workspace,
      ps.id AS resource,
      CASE 
        WHEN ps.value IS NULL OR ps.value = '' THEN 'alarm'
        WHEN ps.value = 'None' THEN 'alarm'
        ELSE 'ok'
      END AS status,
      CASE 
        WHEN ps.value IS NULL OR ps.value = '' THEN 'Policy recommendation not met'
        WHEN ps.value = 'None' THEN 'Policy recommendation not met'
        ELSE 'ok'
      END AS reason
    FROM
      (SELECT DISTINCT workspace FROM guardrails_policy_setting) ws
    LEFT JOIN
      guardrails_policy_setting ps
    ON
      ws.workspace = ps.workspace
      AND ps.policy_type_uri = 'tmod:@turbot/turbot#/policy/types/activityRetention'
    ORDER BY
      ws.workspace;
  EOQ
}

query "guardrails_workspace_policy_conflicts" {
  sql = <<-EOQ
SELECT
    g.workspace,
    g.workspace AS resource,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM (
                SELECT
                    notifications -> 'resource' -> 'type' ->> 'uri' AS resource_type,
                    notifications ->> 'notificationType' AS notification_type,
                    COUNT(*) AS notification_count
                FROM
                    jsonb_array_elements(g.output -> 'notifications' -> 'items') AS notifications
                WHERE
                    notifications ->> 'notificationType' IN ('resource_created', 'resource_deleted', 'resource_updated', 'control_notify')
                GROUP BY
                    resource_type, notification_type
                HAVING
                    COUNT(*) >= 10
            ) sub
        ) THEN 'alarm'
        ELSE 'ok'
    END AS status,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM (
                SELECT
                    notifications -> 'resource' -> 'type' ->> 'uri' AS resource_type,
                    notifications ->> 'notificationType' AS notification_type,
                    COUNT(*) AS notification_count
                FROM
                    jsonb_array_elements(g.output -> 'notifications' -> 'items') AS notifications
                WHERE
                    notifications ->> 'notificationType' IN ('resource_created', 'resource_deleted', 'resource_updated', 'control_notify')
                GROUP BY
                    resource_type, notification_type
                HAVING
                    COUNT(*) >= 10
            ) sub
        ) THEN 'Potential control conflicts detected in the last hour.'
        ELSE 'No control conflicts detected.'
    END AS reason
FROM
    guardrails_query g
WHERE
    g.query = '{
      notifications: notifications(
        filter: "timestamp:>=T-1h !controlTypeId:tmod:@turbot/turbot#/control/types/runnableMonitor,tmod:@turbot/turbot#/control/types/processMonitor,tmod:@turbot/turbot#/control/types/eventMonitor limit:5000"
      ) {
        items {
          turbot {
            id
            createTimestamp
          }
          resource {
            type {
              uri
            }
          }
          notificationType
          control {
            type {
              uri
            }
          }
        }
      }
    }';
  EOQ
}
