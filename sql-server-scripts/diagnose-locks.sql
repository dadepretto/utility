with
    [BaseData] as (
        select
            [TL].[resource_type],
            [TL].[resource_subtype],
            [TL].[resource_database_id],
            [TL].[resource_description],
            [TL].[resource_associated_entity_id],
            [TL].[resource_lock_partition],
            [TL].[request_mode],
            [TL].[request_type],
            [TL].[request_status],
            [TL].[request_reference_count],
            [TL].[request_lifetime],
            [TL].[request_session_id],
            [TL].[request_exec_context_id],
            [TL].[request_request_id],
            [TL].[request_owner_type],
            [TL].[request_owner_id],
            [TL].[request_owner_guid],
            [TL].[request_owner_lockspace_id],
            [TL].[lock_owner_address],
            case [TL].[resource_type]
                when N'OBJECT'
                    then object_name([TL].[resource_associated_entity_id])
                    else object_name([P].[object_id])
            end as [resource_associated_entity_name]
        from [sys].[dm_tran_locks] as [TL]
            left join [sys].[partitions] as [P]
                on [TL].[resource_associated_entity_id] = [P].[hobt_id]
            left join [sys].[indexes] as [I]
                on [I].[object_id] = [P].[object_id]
                    and [I].[index_id] = [P].[index_id]
        )
select
    [resource_type]                   as [resource_type],
    [request_type]                    as [request_type],
    [request_mode]                    as [request_mode],
    [resource_associated_entity_name] as [resource_associated_entity_name],
    count(*)                          as [locks_count]
from [BaseData]
-- where [request_session_id] = session_id
group by
    [resource_type],
    [request_type],
    [request_mode],
    [resource_associated_entity_name];
