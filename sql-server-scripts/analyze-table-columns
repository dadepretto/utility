create or alter procedure [#AnalyzeTable]
(
	@SchemaName sysname = N'dbo',
	@TableName sysname
)
as
declare
	@stmt nvarchar(max);
begin
	set @stmt = (
		select string_agg(convert(nvarchar(max), concat(N'
			select
				N''', [QC].[Name], '''					as [Column],
				N''', [Y].[name], N'''					as [Type],
				min(len([T].', [QC].[Name], '))			as [MinLength],
				max(len([T].', [QC].[Name], '))			as [MaxLength],
				iif(sum([N].[IsNull]) = 0, 0, 1)		as [IsNullable]
			from ', [QS].[Name], N'.', [QT].[Name], ' as [T]
				cross apply (select iif(nullif(trim(cast([T].', [QC].[Name], ' as nvarchar(max))), '''') is null, 1, 0) as [IsNull]) as [N]
		')), ' union all ') within group (order by [C].[column_id])
		from [sys].[schemas] as [S]
			inner join [sys].[tables] as [T]
				on [S].[schema_id] = [T].[schema_id]
			inner join [sys].[columns] as [C]
				on [T].[object_id] = [C].[object_id]
			inner join [sys].[types] as [Y]
				on [C].[user_type_id] = [Y].[user_type_id]
			cross apply (select quotename([S].[name]) as [Name]) as [QS]
			cross apply (select quotename([T].[name]) as [Name]) as [QT]
			cross apply (select quotename([C].[name]) as [Name]) as [QC]
		where [S].[Name] = @SchemaName
			and [T].[Name] = @TableName
	);

	execute [sys].[sp_executesql] @stmt = @stmt;
end;
go
