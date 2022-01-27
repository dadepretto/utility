select
	[SC].[schema_id]						as [schema_id],
	[SC].[name]								as [schema_name],
	[TB].[object_id]						as [table_id],
	[TB].[name]								as [table_name],
	[IX].[index_id]							as [index_id],
	[IX].[name]								as [index_name],
	[IX].[type_desc]						as [index_type],
	[PT].[rows]								as [rowcount],
	[IS].[user_seeks]						as [seeks_count],
	[IS].[user_scans]						as [scans_count],
	[IS].[user_lookups]						as [lookups_count],
	[IS].[user_updates]						as [updates_count],
	[IS].[last_user_seek]					as [last_seek],
	[IS].[last_user_scan]					as [last_scan],
	[IS].[last_user_lookup]					as [last_lookup],
	[IS].[last_user_update]					as [last_update],
	[PS].[used_page_count] * 8 / 1024		as [used_space_MB],
	[PS].[reserved_page_count] * 8 / 2014	as [reserved_space_MB]
from [sys].[schemas] as [SC] with (nolock)
	inner join [sys].[tables] as [TB] with (nolock)
		on [SC].[schema_id] = [TB].[schema_id]
	inner join [sys].[indexes] as [IX] with (nolock)
		on [TB].[object_id] = [IX].[object_id]
	inner join [sys].[partitions] as [PT] with (nolock)
		on [TB].[object_id] = [PT].[object_id]
			and [IX].[index_id] = [PT].[index_id]
	left join [sys].[dm_db_index_usage_stats] as [IS] with (nolock)
		on [TB].[object_id] = [IS].[object_id]
			and [IX].[index_id] = [IS].[index_id]
	left join [sys].[dm_db_partition_stats] as [PS] with (nolock)
		on [PT].[partition_id] = [PS].[partition_id]
			and [IX].[index_id] = [PS].[index_id]
			and [TB].[object_id] = [PS].[object_id]
order by [index_id] asc;
